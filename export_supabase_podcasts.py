#!/usr/bin/env python3
"""
Export creators (Podscan-backed) into a CSV shaped for Supabase public.podcasts.
"""

import argparse
import csv
import sqlite3
import json
from datetime import datetime
from pathlib import Path
from typing import Optional
from uuid import uuid4


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Export podcasts to Supabase CSV")
    parser.add_argument(
        "--adl-db",
        type=Path,
        default=Path("adelined_matching.db"),
        help="Path to Adelined SQLite database (default: adelined_matching.db)",
    )
    parser.add_argument(
        "--out",
        type=Path,
        help="Output CSV path (default: tests/supabase_podcasts_YYYYMMDD.csv)",
    )
    parser.add_argument(
        "--owner-id",
        default="11e86110-bdf7-4665-a2de-4a6846144b61",
        help="Supabase auth.users.id to set as owner_id for all exported podcasts",
    )
    parser.add_argument(
        "--region",
        help="Optional region filter (matches podscan.region)",
    )
    parser.add_argument(
        "--itunesid",
        type=int,
        help="Only export a specific iTunes ID",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=1000,
        help="Max rows to export (default: 1000)",
    )
    parser.add_argument(
        "--offset",
        type=int,
        default=0,
        help="Offset into the export set (default: 0)",
    )
    return parser


def resolve_sample_url(row: sqlite3.Row) -> str:
    return (
        (row["podscan_website"] or "").strip()
        or (row["feed_link"] or "").strip()
        or (row["feed_url"] or "").strip()
    )


def resolve_name(row: sqlite3.Row) -> str:
    return (row["creator_title"] or row["feed_title"] or "").strip()


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    db_path = Path(args.adl_db)
    if not db_path.exists():
        raise SystemExit(f"DB not found: {db_path}")

    out_path = args.out
    if not out_path:
        stamp = datetime.utcnow().strftime("%Y%m%d")
        out_path = Path("tests") / f"supabase_podcasts_{stamp}.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    itunesid = args.itunesid

    conn = sqlite3.connect(str(db_path), timeout=10)
    conn.row_factory = sqlite3.Row
    query = """
        WITH podscan_dedup AS (
            SELECT ps.*,
                   ROW_NUMBER() OVER (
                       PARTITION BY ps.podcastindex_id
                       ORDER BY ps.id
                   ) AS rn
            FROM podscan ps
        )
        SELECT c.adlid,
               c.podcastindex_id,
               c.itunesid AS creator_itunesid,
               c.title AS creator_title,
               c.normalized_tone,
               c.normalized_audience,
               ps.itunesid AS podscan_itunesid,
               ps.region AS podscan_region,
               ps.email AS podscan_email,
               ps.website AS podscan_website,
               pf.title AS feed_title,
               pf.url AS feed_url,
               pf.link AS feed_link
        FROM creators c
        JOIN podscan_dedup ps ON ps.podcastindex_id = c.podcastindex_id AND ps.rn = 1
        LEFT JOIN podcastindex_feeds pf ON pf.id = c.podcastindex_id
        WHERE COALESCE(NULLIF(ps.itunesid, 0), NULLIF(c.itunesid, 0), NULLIF(pf.itunesId, 0)) IS NOT NULL
          AND (? IS NULL OR COALESCE(NULLIF(ps.itunesid, 0), NULLIF(c.itunesid, 0), NULLIF(pf.itunesId, 0)) = ?)
        ORDER BY pf.lastUpdate DESC
    """
    params = [itunesid, itunesid]
    if args.limit and args.limit > 0:
        query += " LIMIT ? OFFSET ?"
        params.extend([args.limit, args.offset])
    rows = conn.execute(query, params).fetchall()
    conn.close()

    header = [
        "owner_id",
        "name",
        "itunesid",
        "vibe",
        "region",
        "audience_band",
        "price_gbp",
        "sample_url",
        "available",
        "can_negotiate",
        "banner_image_path",
        "tile_image_path",
        "external_ref",
        "external_json",
        "is_verified",
        "is_on_waitlist",
        "has_surveyed",
        "created_at",
        "updated_at",
    ]

    now_iso = datetime.utcnow().isoformat() + "Z"
    with out_path.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for row in rows:
            name = resolve_name(row)
            if not name:
                continue
            region_val = (row["podscan_region"] or "UK").upper()
            sample_url = resolve_sample_url(row)
            external_json = {
                "adlid": row["adlid"],
                "podcastindex_id": row["podcastindex_id"],
                "itunesid": row["podscan_itunesid"]
                or row["creator_itunesid"]
                or None,
                "email": row["podscan_email"],
                "website": row["podscan_website"],
                "feed_url": row["feed_url"],
                "feed_link": row["feed_link"],
            }
            itunes_val = (
                row["podscan_itunesid"]
                or row["creator_itunesid"]
                or None
            )
            writer.writerow(
                [
                    args.owner_id,
                    name,
                    itunes_val,
                    (row["normalized_tone"] or "").strip() or None,
                    region_val,
                    None,
                    50,
                    sample_url or None,
                    True,
                    False,
                    None,
                    None,
                    str(row["adlid"]),
                    json.dumps(external_json),
                    False,
                    False,
                    False,
                    now_iso,
                    now_iso,
                ]
            )

    print(f"✅ Wrote {out_path} ({len(rows)} rows, filtered)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
