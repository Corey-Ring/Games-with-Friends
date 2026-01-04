# MovieChain Data Files

This document describes the large data files required for the MovieChain game feature. These files are **not included in the Git repository** due to their size but are necessary for the game to function properly.

## Required Data Files

### 1. IMDb Dataset Files (.tsv)

The following TSV (Tab-Separated Values) files are sourced from the [IMDb Non-Commercial Datasets](https://developer.imdb.com/non-commercial-datasets/):

#### `name.basics.tsv` (~883 MB)
- **Source**: https://datasets.imdbws.com/name.basics.tsv.gz
- **Description**: Contains basic information about actors and other entertainment industry professionals
- **Fields**: nconst (person ID), primaryName, birthYear, deathYear, primaryProfession, knownForTitles
- **Role**: Provides actor names and metadata for the game's actor search functionality

#### `title.basics.tsv` (~1.0 GB)
- **Source**: https://datasets.imdbws.com/title.basics.tsv.gz
- **Description**: Contains basic information about movies and TV shows
- **Fields**: tconst (title ID), titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes, genres
- **Role**: Provides movie titles, years, and genre information for the game's movie search functionality

#### `title.principals.tsv` (~4.1 GB)
- **Source**: https://datasets.imdbws.com/title.principals.tsv.gz
- **Description**: Contains the principal cast and crew for each title
- **Fields**: tconst, ordering, nconst, category, job, characters
- **Role**: Links actors to movies they appeared in, enabling the game to validate actor-movie connections

### 2. SQLite Database Files

#### `moviechain_core.sqlite` (~557 MB)
- **Location**: `Features/MovieChain/Resources/moviechain_core.sqlite`
- **Description**: Pre-processed SQLite database containing optimized movie and actor data
- **Role**: Runtime database used by `MovieChainDatabase.swift` for fast movie/actor searches and validation
- **Tables**:
  - `movies` - Filtered and indexed movie data
  - `actors` - Filtered and indexed actor data
  - `movie_actors` - Junction table linking movies and actors
  - `movies_fts` - Full-text search index for movie titles
  - `actors_fts` - Full-text search index for actor names

#### `moviechain_core.sqlite.gz` (~198 MB)
- **Location**: `Features/MovieChain/Resources/moviechain_core.sqlite.gz`
- **Description**: Gzip-compressed version of the SQLite database
- **Role**: Shipped with the app bundle to reduce app size; automatically decompressed on first launch
- **Process**: The `MovieChainDatabase.swift` service automatically decompresses this file to the app's documents directory on first use

## How the Data is Used

1. **Database Loading** (`MovieChainDatabase.swift:44-79`):
   - On first launch, the app looks for `moviechain_core.sqlite.gz` in the app bundle
   - The compressed database is decompressed to the user's documents directory
   - Subsequent launches use the cached decompressed version

2. **Movie/Actor Search** (`MovieChainDatabase.swift:222-354`):
   - Full-text search (FTS5) enables fast prefix matching for movie titles and actor names
   - Results are ranked by popularity (vote count) for better user experience

3. **Chain Validation** (`MovieChainDatabase.swift:377-448`):
   - The `movie_actors` table validates whether an actor appeared in a specific movie
   - The game uses these queries to verify player answers during gameplay

## Data Processing Pipeline

The raw IMDb TSV files are processed into the optimized SQLite database through the following steps:

1. Filter movies to include only feature films with sufficient ratings/votes
2. Filter actors to include only those with known roles in popular films
3. Extract the top 10 billed cast members for each movie (as noted in `MovieChainGameView.swift:233`)
4. Create FTS5 full-text search indexes for fast prefix matching
5. Compress the final database with gzip to reduce app bundle size

## Data Licensing

The IMDb datasets are available for **non-commercial use only** under the IMDb Datasets License:
- IMDb Datasets: https://developer.imdb.com/non-commercial-datasets/
- License: https://developer.imdb.com/non-commercial-datasets/#licensingandaccess

## How to Obtain the Data Files

If you need to rebuild or update the data files:

1. **Download IMDb datasets**:
   ```bash
   curl -O https://datasets.imdbws.com/name.basics.tsv.gz
   curl -O https://datasets.imdbws.com/title.basics.tsv.gz
   curl -O https://datasets.imdbws.com/title.principals.tsv.gz
   ```

2. **Decompress the files**:
   ```bash
   gunzip name.basics.tsv.gz
   gunzip title.basics.tsv.gz
   gunzip title.principals.tsv.gz
   ```

3. **Process into SQLite database**:
   - (Note: A separate data processing script would be needed to convert the TSV files into the optimized SQLite database with FTS indexes. This script is not currently in the repository.)

4. **Compress the database**:
   ```bash
   gzip -c moviechain_core.sqlite > moviechain_core.sqlite.gz
   ```

5. **Place in project**:
   ```bash
   cp moviechain_core.sqlite.gz Features/MovieChain/Resources/
   ```

## File Locations

These files should be placed in the following locations but are **excluded from version control** via `.gitignore`:

```
Features/MovieChain/Resources/
├── moviechain_core.sqlite.gz    (Included in app bundle - compressed)
└── moviechain_core.sqlite       (Generated at runtime - decompressed)

Project Root/
├── name.basics.tsv              (Development/processing only)
├── title.basics.tsv             (Development/processing only)
└── title.principals.tsv         (Development/processing only)
```

## Size Constraints

These files exceed GitHub's file size limits:
- GitHub's file size limit: 100 MB
- GitHub LFS individual file limit: 2 GB

**Therefore, these files must be:**
- Downloaded separately from IMDb
- Processed locally
- Excluded from Git version control
- Distributed through alternative means (if distributing the app)

## Notes

- The database is read-only at runtime (opened with `SQLITE_OPEN_READONLY` flag)
- IMDb data is updated regularly; you may want to refresh these files periodically
- The current implementation includes only the top 10 billed cast members per movie
- Future enhancements could expand the database or use a cloud-based solution
