# Findings Report

## Purpose of the Engine
The Adelined engine is a CLI-driven data pipeline for ingesting, enriching, normalizing, embedding, and ranking podcast creators and brands. It aims to build a structured, queryable representation of creators that supports relevance scoring, discovery, and downstream workflows (e.g., segmentation and outreach).

## What We Are Trying To Achieve
- Build a reliable creator dataset from PodcastIndex and Podscan.
- Enrich creators with external signals and structured metadata.
- Normalize creators into consistent fields for downstream use.
- Embed creator and brand representations for similarity and ranking.
- Group creators into meaningful clusters for targeting and reporting.

## Findings So Far
1) Normalized template blocks can produce inflated similarity scores.
   - The structured text block is highly templated, with many repeated headers and generic phrases.
   - When embeddings are derived directly from these blocks, unrelated creators can score ~0.98.

2) Identity-focused embedding reduces template bias.
   - Using a smaller identity input (name + summary + keywords/topics) is more discriminative.
   - This removes most of the boilerplate effects from similarity scoring.

3) Embedding comparisons depend on input source.
   - Ad-hoc text comparison of exported blocks bypasses stored embeddings.
   - Stored embeddings should be the source of truth for similarity and ranking.

4) Clustering is viable but method-sensitive.
   - HDBSCAN can yield no clusters if density is low or parameters are too strict.
   - K-means provides stable groupings for segmentation at current scale.

5) Podscan-backed workflows are effective.
   - Filtering by Podscan JSON ensures only verified sources are processed.
   - Normalization and embeddings can be scoped to Podscan-backed creators.

## Current Status
- Podscan enrichment and normalization are operational.
- Identity-focused embeddings are in place.
- Clustering results are available via k-means and can be exported.

## Recommended Next Steps
- Expand normalization coverage for Podscan creators to increase embed pool size.
- Re-embed all creators using identity mode to reduce similarity inflation.
- Use k-means for production clustering; optionally use HDBSCAN for suggested K.
- Add label normalization to merge near-duplicate label names.
