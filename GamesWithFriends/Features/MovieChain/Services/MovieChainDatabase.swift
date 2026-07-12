import Foundation
import SQLite3
import Compression
import Combine

/// Database service for Movie Chain game
/// Handles all SQLite queries for movie/actor search and validation
final class MovieChainDatabase: ObservableObject {
    static let shared = MovieChainDatabase()

    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.moviechain.database", qos: .userInitiated)

    /// Whether the database is loaded and ready
    @Published private(set) var isLoaded = false

    /// Whether the database is currently being decompressed
    @Published private(set) var isDecompressing = false

    /// Progress of decompression (0.0 to 1.0)
    @Published private(set) var decompressionProgress: Double = 0.0

    /// Error information if loading failed
    private(set) var loadError: String?

    /// Filename of the decompressed database.
    private static let dbFileName = "moviechain_core.sqlite"

    /// Path to the decompressed database in the app's Application Support
    /// directory. This location is not synced to iCloud by default and, once
    /// created, we also flag it as excluded from backups so the ~557MB file
    /// never bloats the user's iCloud backup.
    private var decompressedDBPath: URL? {
        guard let supportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        // Application Support is not guaranteed to exist; create it if needed.
        if !FileManager.default.fileExists(atPath: supportPath.path) {
            do {
                try FileManager.default.createDirectory(at: supportPath, withIntermediateDirectories: true)
            } catch {
                print("MovieChainDatabase: Failed to create Application Support directory: \(error.localizedDescription)")
                return nil
            }
        }

        return supportPath.appendingPathComponent(Self.dbFileName)
    }

    /// Legacy path where earlier (pre-release) builds decompressed the database.
    /// Used to migrate existing installs off of the iCloud-backed Documents
    /// directory rather than re-decompressing.
    private var legacyDocumentsDBPath: URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent(Self.dbFileName)
    }

    private init() {
        loadDatabase()
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    // MARK: - Database Loading

    private func loadDatabase() {
        guard let dbPath = decompressedDBPath else {
            loadError = "Could not locate documents directory"
            print("MovieChainDatabase: \(loadError ?? "unknown error")")
            return
        }

        // Reuse a previously decompressed database only if it passes the
        // integrity probe; a corrupt file here would otherwise be trusted
        // forever and the bundled archive fallback would never run again.
        if FileManager.default.fileExists(atPath: dbPath.path) {
            if validateDatabaseFile(at: dbPath.path) {
                excludeFromBackup(at: dbPath)
                openDatabase(at: dbPath.path)
                return
            }
            print("MovieChainDatabase: Existing database failed validation — re-extracting")
            try? FileManager.default.removeItem(at: dbPath)
        }

        // Migrate a database left in the legacy Documents directory by an
        // earlier build instead of re-decompressing the ~557MB file.
        if let legacyPath = legacyDocumentsDBPath,
           FileManager.default.fileExists(atPath: legacyPath.path) {
            do {
                try FileManager.default.moveItem(at: legacyPath, to: dbPath)
                if validateDatabaseFile(at: dbPath.path) {
                    print("MovieChainDatabase: Migrated database from Documents to Application Support")
                    excludeFromBackup(at: dbPath)
                    openDatabase(at: dbPath.path)
                    return
                }
                print("MovieChainDatabase: Migrated legacy database failed validation — re-extracting")
                try? FileManager.default.removeItem(at: dbPath)
            } catch {
                // If the move fails, fall through to a fresh decompression so
                // the game still works; the stale legacy copy is left in place.
                print("MovieChainDatabase: Failed to migrate legacy database: \(error.localizedDescription)")
            }
        }

        // Look for compressed database in bundle
        guard let compressedPath = Bundle.main.path(forResource: Self.dbFileName, ofType: "gz") else {
            loadError = "Compressed database file not found in bundle"
            print("MovieChainDatabase: \(loadError ?? "unknown error")")
            return
        }

        // Decompress in background
        isDecompressing = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                try self.decompressDatabase(from: compressedPath, to: dbPath.path)

                DispatchQueue.main.async {
                    self.isDecompressing = false
                    self.decompressionProgress = 1.0
                    self.excludeFromBackup(at: dbPath)
                    self.openDatabase(at: dbPath.path)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isDecompressing = false
                    self.loadError = "Failed to decompress database: \(error.localizedDescription)"
                    print("MovieChainDatabase: \(self.loadError ?? "unknown error")")
                }
            }
        }
    }

    /// Flag the database file as excluded from iCloud/iTunes backups. The file
    /// is large and fully regenerable from the bundled archive, so it should
    /// never be backed up. Failure here is non-fatal.
    private func excludeFromBackup(at url: URL) {
        var fileURL = url
        do {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try fileURL.setResourceValues(values)
        } catch {
            print("MovieChainDatabase: Failed to exclude database from backup: \(error.localizedDescription)")
        }
    }

    private func decompressDatabase(from sourcePath: String, to destinationPath: String) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = URL(fileURLWithPath: destinationPath)

        // Read compressed data
        let compressedData = try Data(contentsOf: sourceURL)
        let compressedSize = compressedData.count

        print("MovieChainDatabase: Decompressing \(compressedSize / 1_000_000) MB...")

        // Decompress using gzip
        guard let decompressedData = decompressGzip(data: compressedData) else {
            throw NSError(domain: "MovieChainDatabase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Gzip decompression failed"])
        }

        print("MovieChainDatabase: Decompressed to \(decompressedData.count / 1_000_000) MB")

        // Write to a temporary sibling and rename into place, so a kill or
        // crash mid-write can never leave a half-written file at the final
        // path (which would open "successfully" and break the game forever).
        let tempURL = destinationURL.appendingPathExtension("tmp")
        try? FileManager.default.removeItem(at: tempURL)
        try decompressedData.write(to: tempURL)
        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)

        print("MovieChainDatabase: Database ready at \(destinationPath)")
    }

    /// Cheap integrity probe run before trusting any database file that is
    /// already on disk. `sqlite3_open_v2` succeeds lazily even on truncated or
    /// garbage files, so opening alone proves nothing. Checks:
    /// 1. the file opens and its schema is readable (catches garbage),
    /// 2. the on-disk size is at least what the header claims
    ///    (`page_count × page_size` — catches truncation from an interrupted
    ///    write; reads only the first pages, so it's O(1) on the 557MB file).
    private func validateDatabaseFile(at path: String) -> Bool {
        var probe: OpaquePointer?
        guard sqlite3_open_v2(path, &probe, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(probe)
            return false
        }
        defer { sqlite3_close(probe) }

        func scalar(_ sql: String) -> Int64? {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(probe, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
            defer { sqlite3_finalize(statement) }
            guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
            return sqlite3_column_int64(statement, 0)
        }

        guard let schemaCount = scalar("SELECT count(*) FROM sqlite_master"), schemaCount > 0,
              let pageCount = scalar("PRAGMA page_count"),
              let pageSize = scalar("PRAGMA page_size") else {
            return false
        }

        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        let actualSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        return actualSize >= pageCount * pageSize
    }

    private func decompressGzip(data: Data) -> Data? {
        // Gzip header check
        guard data.count > 2,
              data[0] == 0x1f,
              data[1] == 0x8b else {
            print("MovieChainDatabase: Invalid gzip header")
            return nil
        }

        // Use a streaming approach for large files
        let destinationBufferSize = 65536  // 64KB chunks
        var decompressedData = Data()

        // Skip gzip header (minimum 10 bytes) and find the start of deflate data
        var headerSize = 10
        let flags = data[3]

        // Check for extra field
        if flags & 0x04 != 0 {
            guard data.count > headerSize + 2 else { return nil }
            let extraLen = Int(data[headerSize]) + Int(data[headerSize + 1]) << 8
            headerSize += 2 + extraLen
        }

        // Check for original file name
        if flags & 0x08 != 0 {
            while headerSize < data.count && data[headerSize] != 0 {
                headerSize += 1
            }
            headerSize += 1  // Skip null terminator
        }

        // Check for comment
        if flags & 0x10 != 0 {
            while headerSize < data.count && data[headerSize] != 0 {
                headerSize += 1
            }
            headerSize += 1  // Skip null terminator
        }

        // Check for header CRC
        if flags & 0x02 != 0 {
            headerSize += 2
        }

        guard headerSize < data.count - 8 else { return nil }  // 8 bytes for trailer

        // Get the deflate data (excluding header and 8-byte trailer)
        let deflateData = data.subdata(in: headerSize..<(data.count - 8))

        // Decompress using Compression framework
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferSize)
        defer { destinationBuffer.deallocate() }

        deflateData.withUnsafeBytes { sourceBuffer in
            guard let sourcePtr = sourceBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }

            let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
            defer { streamPtr.deallocate() }

            var stream = streamPtr.pointee
            var status = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
            guard status == COMPRESSION_STATUS_OK else { return }
            defer { compression_stream_destroy(&stream) }

            stream.src_ptr = sourcePtr
            stream.src_size = deflateData.count
            stream.dst_ptr = destinationBuffer
            stream.dst_size = destinationBufferSize

            repeat {
                status = compression_stream_process(&stream, 0)

                if stream.dst_size == 0 || status == COMPRESSION_STATUS_END {
                    let outputSize = destinationBufferSize - stream.dst_size
                    decompressedData.append(destinationBuffer, count: outputSize)
                    stream.dst_ptr = destinationBuffer
                    stream.dst_size = destinationBufferSize

                    // Update progress
                    let progress = Double(deflateData.count - stream.src_size) / Double(deflateData.count)
                    DispatchQueue.main.async { [weak self] in
                        self?.decompressionProgress = progress
                    }
                }
            } while status == COMPRESSION_STATUS_OK

            if status != COMPRESSION_STATUS_END {
                print("MovieChainDatabase: Decompression ended with status \(status)")
            }
        }

        return decompressedData.isEmpty ? nil : decompressedData
    }

    private func openDatabase(at path: String) {
        var dbPointer: OpaquePointer?
        // Use SQLITE_OPEN_FULLMUTEX for thread-safe access from multiple threads
        let result = sqlite3_open_v2(
            path,
            &dbPointer,
            SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX,
            nil
        )

        if result == SQLITE_OK {
            db = dbPointer
            isLoaded = true
            print("MovieChainDatabase: Loaded successfully from \(path)")
        } else {
            loadError = "Failed to open database: \(String(cString: sqlite3_errmsg(dbPointer)))"
            print("MovieChainDatabase: \(loadError ?? "unknown error")")
            sqlite3_close(dbPointer)
        }
    }

    // MARK: - Movie Search

    /// Search for movies by title prefix
    /// - Parameters:
    ///   - query: Search query (prefix match)
    ///   - limit: Maximum results to return
    /// - Returns: Array of matching movies, sorted by popularity
    func searchMovies(query: String, limit: Int = 10) -> [Movie] {
        guard isLoaded, let db = db else { return [] }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        // Use FTS5 for prefix matching
        let ftsQuery = trimmedQuery
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { "\($0)*" }
            .joined(separator: " ")

        let sql = """
            SELECT m.tconst, m.title, m.year, m.genres, m.rating, m.votes
            FROM movies m
            JOIN movies_fts fts ON m.rowid = fts.rowid
            WHERE movies_fts MATCH ?
            ORDER BY m.votes DESC
            LIMIT ?
            """

        var statement: OpaquePointer?
        var results: [Movie] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, ftsQuery, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 2, Int32(limit))

            while sqlite3_step(statement) == SQLITE_ROW {
                let movie = movieFromStatement(statement!)
                results.append(movie)
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    /// Get a movie by its ID
    func getMovie(byId tconst: String) -> Movie? {
        guard isLoaded, let db = db else { return nil }

        let sql = "SELECT tconst, title, year, genres, rating, votes FROM movies WHERE tconst = ?"
        var statement: OpaquePointer?
        var result: Movie?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, tconst, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_ROW {
                result = movieFromStatement(statement!)
            }
        }

        sqlite3_finalize(statement)
        return result
    }

    /// Get a random popular movie to start the chain
    func getRandomStartingMovie() -> Movie? {
        guard isLoaded, let db = db else { return nil }

        // Get a random movie from the top 1000 by votes
        let sql = """
            SELECT tconst, title, year, genres, rating, votes
            FROM movies
            ORDER BY votes DESC
            LIMIT 1000
            """

        var statement: OpaquePointer?
        var movies: [Movie] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                movies.append(movieFromStatement(statement!))
            }
        }

        sqlite3_finalize(statement)
        return movies.randomElement()
    }

    // MARK: - Actor Search

    /// Search for actors by name prefix
    /// - Parameters:
    ///   - query: Search query (prefix match)
    ///   - limit: Maximum results to return
    /// - Returns: Array of matching actors
    func searchActors(query: String, limit: Int = 10) -> [Actor] {
        guard isLoaded, let db = db else { return [] }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        // Use FTS5 for prefix matching
        let ftsQuery = trimmedQuery
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { "\($0)*" }
            .joined(separator: " ")

        // Rank by the actor's most popular movie (MAX votes) so famous actors
        // surface first for common-name searches. The correlated subquery only
        // runs over the FTS-matched rows and uses the movie_actors/movies
        // indexes, keeping it fast without a full-table scan.
        let sql = """
            SELECT a.nconst, a.name, a.known_for
            FROM actors a
            JOIN actors_fts fts ON a.rowid = fts.rowid
            WHERE actors_fts MATCH ?
            ORDER BY (
                SELECT MAX(m.votes)
                FROM movie_actors ma
                JOIN movies m ON ma.tconst = m.tconst
                WHERE ma.nconst = a.nconst
            ) DESC
            LIMIT ?
            """

        var statement: OpaquePointer?
        var results: [Actor] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, ftsQuery, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 2, Int32(limit))

            while sqlite3_step(statement) == SQLITE_ROW {
                let actor = actorFromStatement(statement!)
                results.append(actor)
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    /// Get an actor by their ID
    func getActor(byId nconst: String) -> Actor? {
        guard isLoaded, let db = db else { return nil }

        let sql = "SELECT nconst, name, known_for FROM actors WHERE nconst = ?"
        var statement: OpaquePointer?
        var result: Actor?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, nconst, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_ROW {
                result = actorFromStatement(statement!)
            }
        }

        sqlite3_finalize(statement)
        return result
    }

    // MARK: - Validation

    /// Check if an actor appeared in a specific movie
    func isActorInMovie(actorId: String, movieId: String) -> Bool {
        guard isLoaded, let db = db else { return false }

        let sql = "SELECT 1 FROM movie_actors WHERE tconst = ? AND nconst = ? LIMIT 1"
        var statement: OpaquePointer?
        var found = false

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, movieId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, actorId, -1, SQLITE_TRANSIENT)

            found = sqlite3_step(statement) == SQLITE_ROW
        }

        sqlite3_finalize(statement)
        return found
    }

    /// Get all actors in a specific movie
    func getActorsInMovie(movieId: String) -> [Actor] {
        guard isLoaded, let db = db else { return [] }

        let sql = """
            SELECT a.nconst, a.name, a.known_for
            FROM actors a
            JOIN movie_actors ma ON a.nconst = ma.nconst
            WHERE ma.tconst = ?
            """

        var statement: OpaquePointer?
        var results: [Actor] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, movieId, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(actorFromStatement(statement!))
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    /// Get all movies an actor appeared in
    /// Release years of every movie the actor appears in — the minimal
    /// projection used by Casting Director's era filter, so era probes don't
    /// materialize (and sort) full Movie rows just to read one column.
    func getMovieYears(forActorId actorId: String) -> [Int] {
        guard isLoaded, let db = db else { return [] }

        let sql = """
            SELECT m.year
            FROM movies m
            JOIN movie_actors ma ON m.tconst = ma.tconst
            WHERE ma.nconst = ? AND m.year IS NOT NULL
            """

        var statement: OpaquePointer?
        var results: [Int] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, actorId, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(Int(sqlite3_column_int(statement, 0)))
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    func getMoviesWithActor(actorId: String) -> [Movie] {
        guard isLoaded, let db = db else { return [] }

        let sql = """
            SELECT m.tconst, m.title, m.year, m.genres, m.rating, m.votes
            FROM movies m
            JOIN movie_actors ma ON m.tconst = ma.tconst
            WHERE ma.nconst = ?
            ORDER BY m.votes DESC
            """

        var statement: OpaquePointer?
        var results: [Movie] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, actorId, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(movieFromStatement(statement!))
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    /// Search for actors in a specific movie
    func searchActorsInMovie(query: String, movieId: String, limit: Int = 10) -> [Actor] {
        guard isLoaded, let db = db else { return [] }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            // If no query, return all actors in the movie
            return Array(getActorsInMovie(movieId: movieId).prefix(limit))
        }

        let ftsQuery = trimmedQuery
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { "\($0)*" }
            .joined(separator: " ")

        // Rank the matches within this movie by each actor's most popular movie
        // (MAX votes across their whole filmography) so famous names surface
        // first. The correlated subquery uses a distinct alias (ma2) so it does
        // not clash with the movie-scoping join, and only runs over the small
        // set of actors matched inside this movie.
        let sql = """
            SELECT a.nconst, a.name, a.known_for
            FROM actors a
            JOIN actors_fts fts ON a.rowid = fts.rowid
            JOIN movie_actors ma ON a.nconst = ma.nconst
            WHERE actors_fts MATCH ? AND ma.tconst = ?
            ORDER BY (
                SELECT MAX(m.votes)
                FROM movie_actors ma2
                JOIN movies m ON ma2.tconst = m.tconst
                WHERE ma2.nconst = a.nconst
            ) DESC
            LIMIT ?
            """

        var statement: OpaquePointer?
        var results: [Actor] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, ftsQuery, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, movieId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 3, Int32(limit))

            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(actorFromStatement(statement!))
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    /// Search for movies with a specific actor
    func searchMoviesWithActor(query: String, actorId: String, limit: Int = 10) -> [Movie] {
        guard isLoaded, let db = db else { return [] }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            // If no query, return all movies with the actor
            return Array(getMoviesWithActor(actorId: actorId).prefix(limit))
        }

        let ftsQuery = trimmedQuery
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { "\($0)*" }
            .joined(separator: " ")

        let sql = """
            SELECT m.tconst, m.title, m.year, m.genres, m.rating, m.votes
            FROM movies m
            JOIN movies_fts fts ON m.rowid = fts.rowid
            JOIN movie_actors ma ON m.tconst = ma.tconst
            WHERE movies_fts MATCH ? AND ma.nconst = ?
            ORDER BY m.votes DESC
            LIMIT ?
            """

        var statement: OpaquePointer?
        var results: [Movie] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, ftsQuery, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, actorId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 3, Int32(limit))

            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(movieFromStatement(statement!))
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    // MARK: - Director Search

    /// Search for directors by name prefix
    /// - Parameters:
    ///   - query: Search query (prefix match)
    ///   - limit: Maximum results to return
    /// - Returns: Array of matching directors
    func searchDirectors(query: String, limit: Int = 10) -> [Director] {
        guard isLoaded, let db = db else { return [] }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        // Use FTS5 for prefix matching
        let ftsQuery = trimmedQuery
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { "\($0)*" }
            .joined(separator: " ")

        let sql = """
            SELECT d.nconst, d.name
            FROM directors d
            JOIN directors_fts fts ON d.rowid = fts.rowid
            WHERE directors_fts MATCH ?
            LIMIT ?
            """

        var statement: OpaquePointer?
        var results: [Director] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, ftsQuery, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 2, Int32(limit))

            while sqlite3_step(statement) == SQLITE_ROW {
                let director = directorFromStatement(statement!)
                results.append(director)
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    /// Get a director by their ID
    func getDirector(byId nconst: String) -> Director? {
        guard isLoaded, let db = db else { return nil }

        let sql = "SELECT nconst, name FROM directors WHERE nconst = ?"
        var statement: OpaquePointer?
        var result: Director?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, nconst, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_ROW {
                result = directorFromStatement(statement!)
            }
        }

        sqlite3_finalize(statement)
        return result
    }

    /// Get all directors of a specific movie
    func getDirectorsOfMovie(movieId: String) -> [Director] {
        guard isLoaded, let db = db else { return [] }

        let sql = """
            SELECT d.nconst, d.name
            FROM directors d
            JOIN movie_directors md ON d.nconst = md.nconst
            WHERE md.tconst = ?
            """

        var statement: OpaquePointer?
        var results: [Director] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, movieId, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(directorFromStatement(statement!))
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    /// Get all movies by a specific director
    func getMoviesByDirector(directorId: String) -> [Movie] {
        guard isLoaded, let db = db else { return [] }

        let sql = """
            SELECT m.tconst, m.title, m.year, m.genres, m.rating, m.votes
            FROM movies m
            JOIN movie_directors md ON m.tconst = md.tconst
            WHERE md.nconst = ?
            ORDER BY m.votes DESC
            """

        var statement: OpaquePointer?
        var results: [Movie] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, directorId, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(movieFromStatement(statement!))
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    // MARK: - Qualified Actor Query (Casting Director)

    /// Get actor nconst IDs that have 5+ movies total, with at least 3 having 50,000+ votes.
    /// This runs as a single efficient SQL query using aggregation.
    func getQualifiedActorIds(minMovies: Int = 5, minHighVoteMovies: Int = 3, minVotes: Int = 50000) -> [String] {
        guard isLoaded, let db = db else { return [] }

        let sql = """
            SELECT ma.nconst,
                   COUNT(*) AS total_movies,
                   SUM(CASE WHEN m.votes >= ? THEN 1 ELSE 0 END) AS high_vote_movies
            FROM movie_actors ma
            JOIN movies m ON ma.tconst = m.tconst
            GROUP BY ma.nconst
            HAVING total_movies >= ? AND high_vote_movies >= ?
            """

        var statement: OpaquePointer?
        var results: [String] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(minVotes))
            sqlite3_bind_int(statement, 2, Int32(minMovies))
            sqlite3_bind_int(statement, 3, Int32(minHighVoteMovies))

            while sqlite3_step(statement) == SQLITE_ROW {
                let nconst = String(cString: sqlite3_column_text(statement, 0))
                results.append(nconst)
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    // MARK: - Helper Methods

    private func movieFromStatement(_ statement: OpaquePointer) -> Movie {
        let tconst = String(cString: sqlite3_column_text(statement, 0))
        let title = String(cString: sqlite3_column_text(statement, 1))
        let year = sqlite3_column_type(statement, 2) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 2)) : nil
        let genres = sqlite3_column_type(statement, 3) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 3)) : nil
        let rating = sqlite3_column_type(statement, 4) != SQLITE_NULL ? sqlite3_column_double(statement, 4) : nil
        let votes = sqlite3_column_type(statement, 5) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 5)) : nil

        return Movie(
            tconst: tconst,
            title: title,
            year: year,
            genres: genres,
            rating: rating,
            votes: votes
        )
    }

    private func actorFromStatement(_ statement: OpaquePointer) -> Actor {
        let nconst = String(cString: sqlite3_column_text(statement, 0))
        let name = String(cString: sqlite3_column_text(statement, 1))
        let knownFor = sqlite3_column_type(statement, 2) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 2)) : nil

        return Actor(
            nconst: nconst,
            name: name,
            knownFor: knownFor
        )
    }

    private func directorFromStatement(_ statement: OpaquePointer) -> Director {
        let nconst = String(cString: sqlite3_column_text(statement, 0))
        let name = String(cString: sqlite3_column_text(statement, 1))

        return Director(
            nconst: nconst,
            name: name
        )
    }
}

// MARK: - SQLite Transient Constant
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
