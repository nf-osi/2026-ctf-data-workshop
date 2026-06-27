#!/usr/bin/env python3
"""Search Bluesky for neurofibromatosis (NF) mentions and write them to JSONL.

Bluesky's app.bsky.feed.searchPosts endpoint requires authentication. We create
a session from an app password (NOT your main password) and page through results
with the `cursor` field.

Setup:
  1. Create an app password at https://bsky.app/settings/app-passwords
  2. Copy .env.example to .env and fill in BLUESKY_HANDLE + BLUESKY_APP_PASSWORD
  3. python bluesky_nf_search.py

Output: data/bluesky_nf_posts.jsonl  (one post per line, deduped by URI)
"""
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

import requests

PDS = "https://bsky.social"
# Authenticated searchPosts must go through the PDS/entryway. The public appview
# host (public.api.bsky.app) edge-blocks search with a 403 regardless of token.
APPVIEW = "https://bsky.social"
OUT_DIR = Path(__file__).parent / "data"
OUT_FILE = OUT_DIR / "bluesky_nf_posts.jsonl"

# Specific terms only. Bare "NF" is too noisy (NFL, NFT, "no fun", ...).
QUERIES = [
    "neurofibromatosis",
    "neurofibroma",
    "schwannomatosis",
    '"NF1"',
    '"NF2"',
    "von Recklinghausen",
    "plexiform neurofibroma",
    "#neurofibromatosis",
    "#NF1",
]

PAGE_LIMIT = 100          # max allowed by the API
MAX_PAGES_PER_QUERY = 50  # safety cap (50 * 100 = 5000 posts/query)
SLEEP_BETWEEN_CALLS = 0.5 # be polite / avoid rate limits


def load_dotenv(path: Path) -> None:
    """Minimal .env loader so we don't need python-dotenv."""
    if not path.exists():
        return
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        os.environ.setdefault(key.strip(), val.strip().strip('"').strip("'"))


def create_session(handle: str, app_password: str) -> str:
    """Exchange handle + app password for an access JWT."""
    resp = requests.post(
        f"{PDS}/xrpc/com.atproto.server.createSession",
        json={"identifier": handle, "password": app_password},
        timeout=30,
    )
    if resp.status_code != 200:
        sys.exit(f"Login failed ({resp.status_code}): {resp.text[:300]}")
    return resp.json()["accessJwt"]


def search_all(token: str, query: str) -> list[dict]:
    """Page through every result for one query term."""
    headers = {
        "Authorization": f"Bearer {token}",
        "User-Agent": "nf-osi-research/0.1",
    }
    posts: list[dict] = []
    cursor: str | None = None
    for page in range(MAX_PAGES_PER_QUERY):
        params = {"q": query, "limit": PAGE_LIMIT, "sort": "latest"}
        if cursor:
            params["cursor"] = cursor
        resp = requests.get(
            f"{APPVIEW}/xrpc/app.bsky.feed.searchPosts",
            headers=headers,
            params=params,
            timeout=30,
        )
        if resp.status_code == 429:  # rate limited
            wait = int(resp.headers.get("retry-after", "30"))
            print(f"    rate limited, sleeping {wait}s")
            time.sleep(wait)
            continue
        if resp.status_code != 200:
            print(f"    HTTP {resp.status_code}: {resp.text[:200]}")
            break
        data = resp.json()
        batch = data.get("posts", [])
        posts.extend(batch)
        cursor = data.get("cursor")
        print(f"    page {page + 1}: +{len(batch)} (total {len(posts)})")
        if not cursor or not batch:
            break
        time.sleep(SLEEP_BETWEEN_CALLS)
    return posts


def flatten(post: dict, matched_query: str) -> dict:
    """Pull the fields most useful for analysis; keep the raw record too."""
    record = post.get("record", {})
    author = post.get("author", {})
    return {
        "uri": post.get("uri"),
        "cid": post.get("cid"),
        "matched_query": matched_query,
        "created_at": record.get("createdAt"),
        "indexed_at": post.get("indexedAt"),
        "author_handle": author.get("handle"),
        "author_did": author.get("did"),
        "author_display_name": author.get("displayName"),
        "text": record.get("text", ""),
        "langs": record.get("langs"),
        "reply_count": post.get("replyCount"),
        "repost_count": post.get("repostCount"),
        "like_count": post.get("likeCount"),
        "tags": [
            feature["tag"]
            for facet in record.get("facets", [])
            for feature in facet.get("features", [])
            if feature.get("$type", "").endswith("#tag") and "tag" in feature
        ],
        "raw": post,
    }


def main() -> None:
    load_dotenv(Path(__file__).parent / ".env")
    handle = os.environ.get("BLUESKY_HANDLE")
    app_password = os.environ.get("BLUESKY_APP_PASSWORD")
    if not handle or not app_password:
        sys.exit(
            "Missing credentials. Copy .env.example to .env and set "
            "BLUESKY_HANDLE and BLUESKY_APP_PASSWORD "
            "(create one at https://bsky.app/settings/app-passwords)."
        )

    print(f"Authenticating as {handle} ...")
    token = create_session(handle, app_password)

    OUT_DIR.mkdir(exist_ok=True)
    seen: set[str] = set()
    written = 0
    with OUT_FILE.open("w", encoding="utf-8") as fh:
        for query in QUERIES:
            print(f"Searching: {query}")
            for post in search_all(token, query):
                uri = post.get("uri")
                if not uri or uri in seen:
                    continue
                seen.add(uri)
                fh.write(json.dumps(flatten(post, query), ensure_ascii=False) + "\n")
                written += 1

    print(f"\nDone. Wrote {written} unique posts to {OUT_FILE}")


if __name__ == "__main__":
    main()
