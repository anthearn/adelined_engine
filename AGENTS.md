# AGENTS.md

Guidance for coding agents working in this repo.

## Project overview
- This repo centers on the `adl` CLI for ingesting, enriching, normalizing, embedding, and ranking podcast/brand data.
- Most work happens in `adl` (single large Python CLI script) and the SQLite DB `adelined_matching.db`.
- Data workflows are designed to be incremental and resumable.

## Do not touch legacy
- `midrollv0/` is read-only legacy reference. Do not modify files there, do not import from it, and do not wire new code to depend on it.
- If a task appears to require changing `midrollv0`, pause and ask for direction.

## Key files and directories
- `adl`: main CLI entrypoint (Python). Most new workflows/flags live here.
- `adelined_matching.db`: default working SQLite database.
- `data/`: source inputs such as PodcastIndex snapshots.
- `tests/`: logs and debug artifacts (e.g., normalize failures, Podscan PID dumps).

## Environment variables
- `PODSCAN_API_KEY`: required for Podscan lookups and search pulls.
- `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`: required for Spotify enrichment.
- `YOUTUBE_API_KEY`: required for YouTube enrichment.
- `OPENAI_API_KEY`: required for OpenAI normalization/embeddings when selected.
- `LLM_PROVIDER_EMBED`: default provider for embeddings (`local` or `openai`).
- `LLM_PROVIDER_META_ENRICH`: provider for creator metadata extraction (`local` or `openai`).
- `OLLAMA_MODEL`, `OLLAMA_EMBED_MODEL`, `OLLAMA_HOST`: local LLM/embedding settings.

## Core workflows (typical path)
1) Ingest and/or discover creators
   - `python3 adl ingest podcastindex --source-db data/podcastindex_feeds.db --target-db adelined_matching.db`
   - `python3 adl discover apple --terms "comedy,news" --country GB`

2) Enrich creators (external signals)
   - `python3 adl enrich --sources spotify,apple,youtube,social --limit 100 --offset 0`

3) Normalize to structured fields
   - `python3 adl normalize-entity --entity-type creator --all-creators --limit 100 --offset 0`
   - Optional: `--llm-provider openai` to force OpenAI for normalization.
   - Optional: `--podscan` to use Podscan `podcast_description` as the only source (creator-only).

4) Embed normalized text blocks
   - `python3 adl embed-entity --entity-type creator --limit 100 --offset 0`
   - Uses `LLM_PROVIDER_EMBED` by default or `--embedding-provider`.

5) Compare or rank
   - `python3 adl rank --brand-id <adlid>`
   - `python3 adl test-compare --text1 ... --text2 ...`

## Podscan workflows
- Pull Podscan search results into `podscan` table:
  - `python3 adl update_from_podscan --limit 100 --per_page 25 --order_by created_at`
  - `--force` overwrites duplicates; default skips.
  - `--month_only 1_25` restricts to a month (Jan 2025). This sets min/max last_posted_at.
- Find creator country via Podscan by itunesId:
  - `python3 adl find-creator-country --limit 50`

## Data conventions
- `podscan` table stores raw JSON in `full_json` plus extracted fields (`id`, `guid`, `itunesid`, `email`, `website`, `region`).
- `entity_normalized` stores normalized JSON fields plus a canonical normalized text block.
- `entity_embeddings.embedding_vector` stores JSON-encoded float vectors.

## Working style
- Prefer small, incremental changes to `adl` with clear CLI flags.
- Keep changes in this repo; avoid modifying database files unless explicitly asked.
- If new data artifacts are needed for debugging, place them in `tests/`.
