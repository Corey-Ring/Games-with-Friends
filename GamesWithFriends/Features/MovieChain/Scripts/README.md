# MovieChain Director Database Script

## Overview

The `add_directors.py` script adds director data to the MovieChain SQLite database by processing IMDb non-commercial datasets.

## Prerequisites

1. **Python 3.10+** (no additional dependencies required - uses standard library only)
2. **IMDb Dataset Files** (download from https://datasets.imdbws.com/):
   - `title.principals.tsv` (~4.1 GB)
   - `name.basics.tsv` (~883 MB)
3. **Decompressed Database**: The existing `moviechain_core.sqlite` file

## Setup

1. Download the required IMDb TSV files and place them in the project root directory:
   ```bash
   cd /Users/coreyring/Games-with-Friends/GamesWithFriends
   curl -O https://datasets.imdbws.com/title.principals.tsv.gz
   curl -O https://datasets.imdbws.com/name.basics.tsv.gz
   gunzip title.principals.tsv.gz
   gunzip name.basics.tsv.gz
   ```

2. Decompress the existing database and copy it to the project root:
   ```bash
   gunzip -k GamesWithFriends/Features/MovieChain/Resources/moviechain_core.sqlite.gz
   mv GamesWithFriends/Features/MovieChain/Resources/moviechain_core.sqlite ./
   ```

## Running the Script

Execute from the Scripts directory:

```bash
cd GamesWithFriends/Features/MovieChain/Scripts
python3 add_directors.py
```

## What the Script Does

1. **Opens** the existing `moviechain_core.sqlite` database
2. **Drops** any existing director tables (directors, movie_directors, directors_fts)
3. **Creates** new director tables with proper schema
4. **Loads** existing movie IDs from the database
5. **Processes** `title.principals.tsv` to extract director-movie relationships
   - Only includes directors for movies already in the database
   - Filters for rows where `category = 'director'`
6. **Processes** `name.basics.tsv` to get director names
7. **Inserts** directors into the `directors` table
8. **Inserts** movie-director relationships into `movie_directors` table
9. **Creates** FTS5 full-text search index on director names
10. **Creates** indexes on `movie_directors` for fast lookups
11. **Vacuums** the database to optimize storage
12. **Compresses** the database to `moviechain_core.sqlite.gz`

## Output

The script will create:
- **`directors` table**: Director IDs and names
- **`movie_directors` table**: Junction table linking movies to directors
- **`directors_fts` table**: Full-text search index for director names
- **Indexes**: `idx_movie_directors_tconst` and `idx_movie_directors_nconst`
- **Compressed file**: `moviechain_core.sqlite.gz` (new version with directors)

## Performance

- Processing is done in a streaming fashion to handle large files
- Uses batched inserts (50,000 rows per transaction)
- Progress updates printed every 1 million rows
- Expected runtime: 10-20 minutes depending on system

## After Running

1. **Replace** the old compressed database:
   ```bash
   mv moviechain_core.sqlite.gz GamesWithFriends/Features/MovieChain/Resources/
   ```

2. **Delete** the app's cached database so it uses the new one:
   ```bash
   # Find the app's documents directory and remove the old database
   # The app will decompress the new version on next launch
   ```

3. **Verify** the new data works by testing the director query methods in the app

## Database Schema

### directors
| Column | Type | Description |
|--------|------|-------------|
| nconst | TEXT PRIMARY KEY | Director's IMDb ID (e.g., "nm0000233") |
| name | TEXT NOT NULL | Director's display name |

### movie_directors
| Column | Type | Description |
|--------|------|-------------|
| tconst | TEXT | Movie's IMDb ID |
| nconst | TEXT | Director's IMDb ID |
| PRIMARY KEY | | (tconst, nconst) |

### directors_fts
FTS5 virtual table for full-text search on director names.

## Verification Queries

After running the script, test with these SQL queries:

```sql
-- Find directors of The Matrix
SELECT d.name FROM directors d
JOIN movie_directors md ON d.nconst = md.nconst
WHERE md.tconst = 'tt0133093';

-- Find movies by Christopher Nolan (nm0634240)
SELECT m.title, m.year FROM movies m
JOIN movie_directors md ON m.tconst = md.tconst
WHERE md.nconst = 'nm0634240';

-- Search for directors by name
SELECT d.name FROM directors d
JOIN directors_fts fts ON d.rowid = fts.rowid
WHERE directors_fts MATCH 'nolan*';

-- Count statistics
SELECT COUNT(*) FROM directors;
SELECT COUNT(*) FROM movie_directors;
```

## Troubleshooting

**Error: Database not found**
- Make sure you decompressed the database and moved it to the project root

**Error: TSV file not found**
- Download the IMDb datasets and place them in the project root
- Ensure files are decompressed (not .gz)

**Memory issues**
- The script uses streaming to avoid loading large files into memory
- Ensure you have at least 8GB RAM available

**Slow performance**
- The script processes millions of rows, which takes time
- Monitor progress updates to ensure it's working
- Consider running on an SSD for better performance
