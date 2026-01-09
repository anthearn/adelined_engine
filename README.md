# adelined_engine

Adelined CLI for ingesting podcast/brand data, enriching with external sources, normalizing into structured fields, embedding to vectors, and ranking brand/creator matches.

This repo is centered on the `adl` command and a SQLite database (`adelined_matching.db` by default). Most workflows are incremental and can be re-run safely.

## Quick start (typical pipeline)
1) Ingest feeds or discover creators
   - `python3 adl ingest podcastindex --source-db data/podcastindex_feeds.db --target-db adelined_matching.db`
   - `python3 adl discover apple --terms "comedy,news" --country GB`
2) Enrich creators with external sources
   - `python3 adl enrich --sources spotify,apple,youtube,social --limit 100 --offset 0`
3) Normalize to structured fields
   - `python3 adl normalize-entity --entity-type creator --all-creators --limit 100 --offset 0`
4) Embed normalized text blocks
   - `python3 adl embed-entity --entity-type creator --limit 100 --offset 0`
5) Compare or rank
   - `python3 adl rank --bybrand --adlid 123`

## Installation
- Python 3.x
- Install dependencies: `pip install -r requirements.txt`

## Environment variables
- `PODSCAN_API_KEY`: required for Podscan lookups and search pulls.
- `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`: required for Spotify enrichment.
- `YOUTUBE_API_KEY`: required for YouTube enrichment.
- `OPENAI_API_KEY`: required for OpenAI normalization/embeddings when selected.
- `LLM_PROVIDER_EMBED`: default embedding provider (`local` or `openai`).
- `LLM_PROVIDER_META_ENRICH`: provider for creator metadata extraction (`local` or `openai`).
- `OLLAMA_MODEL`, `OLLAMA_EMBED_MODEL`, `OLLAMA_HOST`: local LLM/embedding settings.

## Command reference

### fetch
Fetch creator data from a source (YouTube or Spotify).

Usage:
```
python3 adl fetch <source> [options]
```

Sources:
- `youtube`
- `spotify`

Options:
- `--output PATH` Optional JSON output file to write results.
- `--channels` Comma-separated YouTube channel handles/IDs/URLs to fetch.
- `--channels-file PATH` Newline-delimited list of YouTube channel handles/IDs/URLs.
- `--shows` Comma-separated Spotify show IDs or URLs to fetch.
- `--shows-file PATH` Newline-delimited list of Spotify show IDs or URLs.

### ingest
Ingest data into the Adelined DB.

Usage:
```
python3 adl ingest <source> [options]
```

Sources:
- `podcastindex`
- `apple`

Options:
- `--source-db PATH` Source SQLite DB (default: `data/podcastindex_feeds.db`).
- `--target-db PATH` Target Adelined SQLite DB (default: `adelined_matching.db`).
- `--refresh-feeds` Refresh `podcastindex_feeds` from source before filtering creators.
- `--batch-size N` Batch size for streaming copy (default: 5000).

### enrich
Enrich creators with external signals (Spotify/Apple/YouTube/socials).

Usage:
```
python3 adl enrich [options]
```

Options:
- `--adl-db PATH` Adelined DB path (default: `adelined_matching.db`).
- `--limit N` Max creators to process (default: 100).
- `--offset N` Offset into creators table (default: 0).
- `--only-id N` Specific podcastindex_id to process.
- `--pidrange START_PID END_PID` Inclusive podcastindex_id range.
- `--sources` Comma-separated sources (default: all). Options: `spotify,apple,youtube,social`.

### discover
Discover new creators from external sources.

Usage:
```
python3 adl discover <source> [options]
```

Sources:
- `apple`

Options:
- `--terms` Comma-separated search terms.
- `--terms-file PATH` File with search terms (one per line).
- `--limit-per-term N` Results per page (default: 200).
- `--max-pages N` Max pages per term (default: 5).
- `--country CODE` iTunes country code (default: `GB`).
- `--adl-db PATH` Adelined DB path (default: `adelined_matching.db`).

### enrichment
Manage or inspect enrichment data.

Usage:
```
python3 adl enrichment <subcommand> [options]
```

Subcommands:
- `clear` Clear `creator_enrichment` (requires confirmation).
  - `--adl-db PATH` Adelined DB path.
- `show` Show enrichment summaries or source data.
  - `--adl-db PATH` Adelined DB path.
  - `--source` One of `spotify,apple,youtube,social,twitter,instagram,website,patreon`.
  - `--limit N` Max rows to display (default: 5).
- `summary` Report overall enrichment coverage.
  - `--adl-db PATH` Adelined DB path.

### static
Load static reference data or assign Apple topics.

Usage:
```
python3 adl static <subcommand> [options]
```

Subcommands:
- `load`
  - `--apple-topics` Load Apple podcast categories.
  - `--adl-db PATH` Adelined DB path.
- `creator-topics` Assign Apple topics to creators (local LLM).
  - `--adl-db PATH` Adelined DB path.
  - `--limit N` Max creators (default: 200).
  - `--offset N` Offset into creators.
  - `--ollama-model NAME` Ollama model name.
  - `--nolimit` Process all creators (requires confirmation).
- `brand-topics` Assign Apple topics to brands (local LLM by default).
  - `--adl-db PATH` Adelined DB path.
  - `--limit N` Max brands (default: 200).
  - `--offset N` Offset into brands.
  - `--openai` Use OpenAI instead of local.
  - `--ollama-model NAME` Ollama model name.
  - `--nolimit` Process all brands (requires confirmation).

### brand
Ingest a brand by URL (scrape + LLM extraction).

Usage:
```
python3 adl brand --url <url> [options]
```

Options:
- `--url URL` Brand website URL (required).
- `--brand-name` Optional brand name override.
- `--adl-db PATH` Adelined DB path.
- `--write-test` Write test brand embedding text to `tests/test-enrich-brand-adlid-<id>_cleaned.txt`.

### normalize-entity
Normalize a brand or creator into structured fields.

Usage:
```
python3 adl normalize-entity --entity-type brand|creator [options]
```

Options:
- `--entity-type` `brand` or `creator` (required).
- `--id N` Specific id (adlid for brand, podcastindex_id for creator).
- `--podcastindex_ids N N ...` Space-delimited creator IDs (creator-only).
- `--id-range START_ID END_ID` Inclusive range.
- `--all-brands` Normalize all brands (paged by limit/offset).
- `--all-creators` Normalize all creators (paged by limit/offset).
- `--limit N` Max rows to process (default: 100).
- `--offset N` Offset for bulk mode.
- `--llm-provider` `local` or `openai` (default: local via Ollama).
- `--ollama-model NAME` Local model name for normalization.
- `--force` Overwrite existing normalized rows.
- `--podscan` Use Podscan `podcast_description` as the sole source (creator-only).
- `--adl-db PATH` Adelined DB path.

### embed-entity
Embed normalized brands or creators into per-dimension vectors.

Usage:
```
python3 adl embed-entity --entity-type brand|creator [options]
```

Options:
- `--entity-type` `brand` or `creator` (required).
- `--id N` Specific id (adlid for brand, podcastindex_id for creator).
- `--id-range START_ID END_ID` Range used for delete operations.
- `--limit N` Max rows to embed (default: 100).
- `--offset N` Offset for bulk mode.
- `--refreshall` Delete existing embeddings for this entity type before embedding (requires YES).
- `--delete` Delete embeddings for `--id` or `--id-range` instead of embedding.
- `--deleteall` Delete all embeddings for this entity type (requires YES).
- `--adl-db PATH` Adelined DB path.
- `--embedding-provider` `openai` or `local` (default from `LLM_PROVIDER_EMBED`).
- `--openai` Shortcut to set `--embedding-provider openai`.
- `--embedding-model NAME` Embedding model name.

### export
Export a stored embedding text block to a file.

Usage:
```
python3 adl export --target creator|brand --id <id> [options]
```

Options:
- `--target` `creator` or `brand` (required).
- `--id N` `podcastindex_id` for creator or `adlid` for brand.
- `--out PATH` Output file path (default: `tests/export-<target>-<id>.txt`).
- `--adl-db PATH` Adelined DB path.
- `--usenorm` Export normalized text when available.

### rank
Rank creators vs brands via embeddings.

Usage:
```
python3 adl rank --bybrand|--bycreator --adlid <id> [options]
```

Options:
- `--bybrand` Rank creators for a brand.
- `--bycreator` Rank brands for a creator.
- `--adlid N` Brand or creator id (required).
- `--adl-db PATH` Adelined DB path.
- `--limit N` Top results to show (default: 20).
- `--debug` Show per-dimension similarity columns and warnings.
- `--raw` Dump normalized fields and sims for each candidate.
- `--csv` Write results to CSV (yyyyMMdd-brand{n}.csv or creator{n}.csv).

### test-compare
Compare two text inputs via embeddings.

Usage:
```
python3 adl test-compare [options]
```

Options:
- `--text1 TEXT` First text input.
- `--text2 TEXT` Second text input.
- `--file1 PATH` Path to first text file.
- `--file2 PATH` Path to second text file.
- `--brand-id N` Compare using brand embeddings.
- `--creator-id N` Compare using creator embeddings.
- `--adl-db PATH` Adelined DB path.

### test-enrich
Dump enrichment for a creator.

Usage:
```
python3 adl test-enrich --pid <podcastindex_id> [options]
```

Options:
- `--pid N` podcastindex_id to inspect (required).
- `--adl-db PATH` Adelined DB path.

### find-creator-country
Lookup and store creator country via Podscan (itunesId).

Usage:
```
python3 adl find-creator-country [options]
```

Options:
- `--limit N` Max rows to process (default: 50; `0` for no limit).
- `--print-only` Print resolved countries without writing to the DB.
- `--pid N` Specific podcastindex_id to lookup (forces print-only).
- `--adl-db PATH` Adelined DB path.

### update_from_podscan
Pull podcasts from Podscan search and store in the `podscan` table.

Usage:
```
python3 adl update_from_podscan [options]
```

Options:
- `--limit N` Max results to store (default: 50; `0` for no limit).
- `--per_page N` Results per page (default: 5; max: 50).
- `--order_by FIELD` One of `best_match,name,created_at,episode_count,rating,audience_size,last_posted_at`.
- `--force` Overwrite existing rows (default: skip duplicates).
- `--month_only M_YY` Restrict last_posted_at to a month like `1_25` (Jan 2025).
- `--adl-db PATH` Adelined DB path.

## Notes
- `midrollv0/` is legacy and should not be modified.
- `tests/` is used for debug artifacts and export files.
