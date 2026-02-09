#!/usr/bin/env python3
"""
Add director data to the MovieChain SQLite database.

This script processes IMDb TSV files to add:
- directors table: director IDs and names
- movie_directors junction table: movie-director relationships
- directors_fts full-text search index

Usage:
    python3 add_directors.py
"""

import sqlite3
import csv
import gzip
import os
import sys
from pathlib import Path


class DirectorDatabaseBuilder:
    """Builds director tables in the MovieChain SQLite database."""
    
    def __init__(self, db_path: str, title_principals_path: str, name_basics_path: str):
        self.db_path = db_path
        self.title_principals_path = title_principals_path
        self.name_basics_path = name_basics_path
        self.conn = None
        
    def connect(self):
        """Connect to the database."""
        print(f"Opening database: {self.db_path}")
        self.conn = sqlite3.connect(self.db_path)
        self.conn.execute("PRAGMA journal_mode = WAL")
        self.conn.execute("PRAGMA synchronous = NORMAL")
        self.conn.execute("PRAGMA cache_size = -64000")  # 64MB cache
        
    def disconnect(self):
        """Close the database connection."""
        if self.conn:
            self.conn.close()
            
    def drop_existing_tables(self):
        """Drop existing director tables if they exist."""
        print("Dropping existing director tables if present...")
        cursor = self.conn.cursor()
        cursor.execute("DROP TABLE IF EXISTS directors_fts")
        cursor.execute("DROP TABLE IF EXISTS movie_directors")
        cursor.execute("DROP TABLE IF EXISTS directors")
        self.conn.commit()
        print("Existing tables dropped.")
        
    def create_tables(self):
        """Create the directors, movie_directors, and directors_fts tables."""
        print("Creating new director tables...")
        cursor = self.conn.cursor()
        
        # Create directors table
        cursor.execute("""
            CREATE TABLE directors (
                nconst TEXT PRIMARY KEY,
                name TEXT NOT NULL
            )
        """)
        
        # Create movie_directors junction table
        cursor.execute("""
            CREATE TABLE movie_directors (
                tconst TEXT NOT NULL,
                nconst TEXT NOT NULL,
                PRIMARY KEY (tconst, nconst)
            )
        """)
        
        self.conn.commit()
        print("Tables created.")
        
    def get_existing_movie_ids(self):
        """Get set of all movie IDs currently in the database."""
        print("Loading existing movie IDs from database...")
        cursor = self.conn.cursor()
        cursor.execute("SELECT tconst FROM movies")
        movie_ids = {row[0] for row in cursor.fetchall()}
        print(f"Found {len(movie_ids):,} movies in database.")
        return movie_ids
        
    def extract_director_relationships(self, existing_movies):
        """
        Extract director-movie relationships from title.principals.tsv.
        Returns dict mapping nconst -> set of tconst values.
        """
        print(f"Processing {self.title_principals_path}...")
        
        # Map director nconst -> set of movie tconsts
        director_movies = {}
        rows_processed = 0
        directors_found = 0
        
        with open(self.title_principals_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter='\t')
            
            for row in reader:
                rows_processed += 1
                
                # Progress indicator every million rows
                if rows_processed % 1_000_000 == 0:
                    print(f"  Processed {rows_processed:,} rows, found {directors_found:,} director links...")
                
                # Only process director rows
                if row.get('category') != 'director':
                    continue
                    
                tconst = row.get('tconst')
                nconst = row.get('nconst')
                
                # Skip if missing data or movie not in our database
                if not tconst or not nconst or tconst not in existing_movies:
                    continue
                
                # Add relationship
                if nconst not in director_movies:
                    director_movies[nconst] = set()
                director_movies[nconst].add(tconst)
                directors_found += 1
        
        print(f"Completed processing {rows_processed:,} rows.")
        print(f"Found {len(director_movies):,} unique directors for {directors_found:,} movie-director links.")
        return director_movies
        
    def extract_director_names(self, director_nconsts):
        """
        Extract director names from name.basics.tsv.
        Returns dict mapping nconst -> name.
        """
        print(f"Processing {self.name_basics_path}...")
        
        director_names = {}
        rows_processed = 0
        names_found = 0
        
        # Convert to set for fast lookup
        needed_nconsts = set(director_nconsts)
        
        with open(self.name_basics_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter='\t')
            
            for row in reader:
                rows_processed += 1
                
                # Progress indicator every million rows
                if rows_processed % 1_000_000 == 0:
                    print(f"  Processed {rows_processed:,} rows, found {names_found:,} director names...")
                
                nconst = row.get('nconst')
                
                # Check if this is a director we need
                if nconst not in needed_nconsts:
                    continue
                
                name = row.get('primaryName')
                if name and name != '\\N':
                    director_names[nconst] = name
                    names_found += 1
                    
                # Early exit if we've found all directors
                if names_found == len(needed_nconsts):
                    print(f"  Found all {names_found:,} director names, stopping scan.")
                    break
        
        print(f"Completed processing {rows_processed:,} rows.")
        print(f"Found {len(director_names):,} director names out of {len(needed_nconsts):,} needed.")
        return director_names
        
    def insert_directors(self, director_names):
        """Insert directors into the directors table."""
        print(f"Inserting {len(director_names):,} directors...")
        
        cursor = self.conn.cursor()
        batch_size = 50_000
        batch = []
        inserted = 0
        
        for nconst, name in director_names.items():
            batch.append((nconst, name))
            
            if len(batch) >= batch_size:
                cursor.executemany("INSERT INTO directors (nconst, name) VALUES (?, ?)", batch)
                self.conn.commit()
                inserted += len(batch)
                print(f"  Inserted {inserted:,} directors...")
                batch = []
        
        # Insert remaining
        if batch:
            cursor.executemany("INSERT INTO directors (nconst, name) VALUES (?, ?)", batch)
            self.conn.commit()
            inserted += len(batch)
        
        print(f"Inserted {inserted:,} directors total.")
        
    def insert_movie_directors(self, director_movies):
        """Insert movie-director relationships into movie_directors table."""
        print("Inserting movie-director relationships...")
        
        cursor = self.conn.cursor()
        batch_size = 50_000
        batch = []
        inserted = 0
        
        for nconst, tconsts in director_movies.items():
            for tconst in tconsts:
                batch.append((tconst, nconst))
                
                if len(batch) >= batch_size:
                    cursor.executemany("INSERT INTO movie_directors (tconst, nconst) VALUES (?, ?)", batch)
                    self.conn.commit()
                    inserted += len(batch)
                    print(f"  Inserted {inserted:,} relationships...")
                    batch = []
        
        # Insert remaining
        if batch:
            cursor.executemany("INSERT INTO movie_directors (tconst, nconst) VALUES (?, ?)", batch)
            self.conn.commit()
            inserted += len(batch)
        
        print(f"Inserted {inserted:,} movie-director relationships total.")
        
    def create_fts_index(self):
        """Create FTS5 full-text search index on director names."""
        print("Creating FTS5 index on director names...")
        
        cursor = self.conn.cursor()
        
        # Create FTS5 virtual table
        cursor.execute("""
            CREATE VIRTUAL TABLE directors_fts USING fts5(
                name,
                content='directors',
                content_rowid='rowid'
            )
        """)
        
        # Populate FTS index
        cursor.execute("""
            INSERT INTO directors_fts (rowid, name)
            SELECT rowid, name FROM directors
        """)
        
        self.conn.commit()
        print("FTS5 index created.")
        
    def create_indexes(self):
        """Create indexes on movie_directors for fast lookups."""
        print("Creating indexes on movie_directors...")
        
        cursor = self.conn.cursor()
        
        # Index for finding directors by movie
        cursor.execute("CREATE INDEX idx_movie_directors_tconst ON movie_directors(tconst)")
        
        # Index for finding movies by director
        cursor.execute("CREATE INDEX idx_movie_directors_nconst ON movie_directors(nconst)")
        
        self.conn.commit()
        print("Indexes created.")
        
    def vacuum_database(self):
        """Optimize the database."""
        print("Vacuuming database (this may take a while)...")
        self.conn.execute("VACUUM")
        print("Vacuum complete.")
        
    def print_stats(self):
        """Print summary statistics."""
        cursor = self.conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM directors")
        director_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM movie_directors")
        relationship_count = cursor.fetchone()[0]
        
        print("\n" + "="*60)
        print("SUMMARY STATISTICS")
        print("="*60)
        print(f"Directors added: {director_count:,}")
        print(f"Movie-director links: {relationship_count:,}")
        print(f"Database location: {self.db_path}")
        
        if os.path.exists(self.db_path):
            db_size_mb = os.path.getsize(self.db_path) / (1024 * 1024)
            print(f"Database size: {db_size_mb:.1f} MB")
        
        print("="*60 + "\n")
        
    def compress_database(self):
        """Compress the database to .gz format."""
        gz_path = self.db_path + '.gz'
        print(f"Compressing database to {gz_path}...")
        
        with open(self.db_path, 'rb') as f_in:
            with gzip.open(gz_path, 'wb', compresslevel=9) as f_out:
                # Copy in chunks
                chunk_size = 1024 * 1024  # 1MB chunks
                bytes_written = 0
                
                while True:
                    chunk = f_in.read(chunk_size)
                    if not chunk:
                        break
                    f_out.write(chunk)
                    bytes_written += len(chunk)
                    
                    # Progress every 50MB
                    if bytes_written % (50 * 1024 * 1024) == 0:
                        print(f"  Compressed {bytes_written / (1024*1024):.0f} MB...")
        
        if os.path.exists(gz_path):
            gz_size_mb = os.path.getsize(gz_path) / (1024 * 1024)
            db_size_mb = os.path.getsize(self.db_path) / (1024 * 1024)
            compression_ratio = (1 - gz_size_mb / db_size_mb) * 100
            print(f"Compression complete: {db_size_mb:.1f} MB -> {gz_size_mb:.1f} MB ({compression_ratio:.1f}% reduction)")
        
    def build(self):
        """Main build process."""
        try:
            self.connect()
            
            # Step 1: Drop existing tables
            self.drop_existing_tables()
            
            # Step 2: Create new tables
            self.create_tables()
            
            # Step 3: Get existing movies
            existing_movies = self.get_existing_movie_ids()
            
            # Step 4: Extract director-movie relationships
            director_movies = self.extract_director_relationships(existing_movies)
            
            # Step 5: Extract director names
            director_names = self.extract_director_names(director_movies.keys())
            
            # Step 6: Filter to only directors with names
            director_movies = {
                nconst: movies 
                for nconst, movies in director_movies.items() 
                if nconst in director_names
            }
            
            # Step 7: Insert directors
            self.insert_directors(director_names)
            
            # Step 8: Insert relationships
            self.insert_movie_directors(director_movies)
            
            # Step 9: Create FTS index
            self.create_fts_index()
            
            # Step 10: Create indexes
            self.create_indexes()
            
            # Step 11: Vacuum database
            self.vacuum_database()
            
            # Step 12: Print stats
            self.print_stats()
            
            # Step 13: Close connection before compression
            self.disconnect()
            
            # Step 14: Compress database
            self.compress_database()
            
            print("\n✅ Director data added successfully!")
            
        except Exception as e:
            print(f"\n❌ Error: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc()
            sys.exit(1)
        finally:
            if self.conn:
                self.disconnect()


def main():
    """Main entry point."""
    # Determine paths
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent.parent.parent  # Go up to project root
    
    # Path to decompressed database (in app documents, but we'll use a local copy for building)
    db_path = project_root / "moviechain_core.sqlite"
    
    # Paths to TSV files (assumed to be in project root)
    title_principals_path = project_root / "title.principals.tsv"
    name_basics_path = project_root / "name.basics.tsv"
    
    # Check if files exist
    if not db_path.exists():
        print(f"❌ Error: Database not found at {db_path}")
        print("Please decompress the moviechain_core.sqlite.gz file first:")
        print(f"  gunzip -k {project_root}/GamesWithFriends/Features/MovieChain/Resources/moviechain_core.sqlite.gz")
        print(f"  mv {project_root}/GamesWithFriends/Features/MovieChain/Resources/moviechain_core.sqlite {db_path}")
        sys.exit(1)
    
    if not title_principals_path.exists():
        print(f"❌ Error: {title_principals_path} not found")
        print("Please download the IMDb dataset file.")
        sys.exit(1)
    
    if not name_basics_path.exists():
        print(f"❌ Error: {name_basics_path} not found")
        print("Please download the IMDb dataset file.")
        sys.exit(1)
    
    print("MovieChain Director Database Builder")
    print("="*60)
    print(f"Database: {db_path}")
    print(f"Title Principals: {title_principals_path}")
    print(f"Name Basics: {name_basics_path}")
    print("="*60 + "\n")
    
    # Build the database
    builder = DirectorDatabaseBuilder(
        db_path=str(db_path),
        title_principals_path=str(title_principals_path),
        name_basics_path=str(name_basics_path)
    )
    
    builder.build()


if __name__ == "__main__":
    main()
