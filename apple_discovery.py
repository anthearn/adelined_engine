#!/usr/bin/env python3
"""
Apple Podcasts discovery via the iTunes Search API (country=GB).

Usage:
    python3 apple_discovery.py --terms-file terms.txt --limit-per-term 200 --max-pages 5 --output data/apple_discovery.jsonl
"""

import argparse
import json
import time
from pathlib import Path
from typing import Iterable, List, Optional, Set

import requests


def load_terms(terms_file: Optional[Path], terms_arg: Optional[str]) -> List[str]:
    terms: List[str] = []
    if terms_file and terms_file.exists():
        terms.extend([line.strip() for line in terms_file.read_text().splitlines() if line.strip()])
    if terms_arg:
        terms.extend([t.strip() for t in terms_arg.split(",") if t.strip()])
    # Deduplicate, preserve order
    seen: Set[str] = set()
    uniq = []
    for t in terms:
        if t not in seen:
            uniq.append(t)
            seen.add(t)
    return uniq


def search_term(term: str, limit: int, max_pages: int, country: str = "GB", media: str = "podcast") -> Iterable[dict]:
    offset = 0
    pages = 0
    while pages < max_pages:
        params = {
            "term": term,
            "country": country,
            "media": media,
            "limit": limit,
            "offset": offset,
        }
        res = requests.get("https://itunes.apple.com/search", params=params, timeout=15)
        res.raise_for_status()
        payload = res.json()
        results = payload.get("results", [])
        if not results:
            break
        for r in results:
            yield r
        offset += limit
        pages += 1
        time.sleep(0.5)  # be polite


def main():
    parser = argparse.ArgumentParser(description="Apple Podcasts discovery via iTunes Search API")
    parser.add_argument("--terms-file", type=Path, help="Path to file with search terms (one per line)")
    parser.add_argument("--terms", help="Comma-separated search terms")
    parser.add_argument("--limit-per-term", type=int, default=200, help="Results per term per page (max 200)")
    parser.add_argument("--max-pages", type=int, default=5, help="Max pages per term")
    parser.add_argument("--country", default="GB", help="iTunes country code (default: GB)")
    parser.add_argument("--output", type=Path, required=True, help="Output JSONL file")
    args = parser.parse_args()

    terms = load_terms(args.terms_file, args.terms)
    if not terms:
        print("No terms provided.")
        return 1

    seen_ids: Set[int] = set()
    out_lines: List[str] = []
    for term in terms:
        for item in search_term(term, args.limit_per_term, args.max_pages, country=args.country):
            tid = item.get("trackId")
            if tid in seen_ids:
                continue
            seen_ids.add(tid)
            out_lines.append(json.dumps(item))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(out_lines))
    print(f"Wrote {len(out_lines)} unique shows to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
