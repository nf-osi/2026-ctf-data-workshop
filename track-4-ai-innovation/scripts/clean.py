#!/usr/bin/env python3
"""Clean the raw Bluesky NF search dump into an analysis-ready dataset.

Input : data/bluesky_nf_posts.jsonl   (output of bluesky_nf_search.py)
Output: data/bluesky_nf_clean.jsonl   (kept, NF-relevant posts, with labels)
        data/bluesky_nf_dropped.jsonl  (dropped posts, each with a drop_reason)
        data/bluesky_nf_summary.json   (counts)

Decisions are made by explicit, auditable rules (below) and every post lands in
one of the two output files so nothing is silently discarded.

Added fields on each post:
  account_type   : 'bot' | 'org_or_highvolume' | 'individual'
  precision_tier : 'A' high-confidence | 'B' NF1/NF2 + medical context | 'C' ambiguous
  drop_reason    : None if kept, else why it was dropped
"""
from __future__ import annotations

import json
import re
import collections
from pathlib import Path

DATA = Path(__file__).parent / "data"
IN_FILE = DATA / "bluesky_nf_posts.jsonl"
KEEP_FILE = DATA / "bluesky_nf_clean.jsonl"
DROP_FILE = DATA / "bluesky_nf_dropped.jsonl"
SUMMARY_FILE = DATA / "bluesky_nf_summary.json"

# --- rule vocabularies -------------------------------------------------------

# Full disease words -> a post containing any of these is almost certainly NF.
HIGH_PRECISION = [
    "neurofibromatosis", "neurofibroma", "schwannomatosis",
    "von recklinghausen", "plexiform",
]

# Used to rescue bare "NF1"/"NF2" matches that have real medical context.
MEDICAL_CONTEXT = [
    "tumor", "tumour", "gene", "genetic", "mutation", "diagnos", "schwannoma",
    "glioma", "optic", "cafe au lait", "café au lait", "symptom", "patient",
    "mri", "oncolog", "cutaneous", "lesion", "nerve", "hereditary", "chromosome",
    "suppressor", "meningioma", "neuroma", "hearing loss", "clinical", "therapy",
    "treatment", "trial", "selumetinib", "mek inhibitor", "koselugo", "ras",
    "disorder", "condition", "rare disease", "biomarker", "surgery",
]

# Automated accounts: news/preprint/bridge/LLM feeds. Substring match on handle.
BOT_HANDLE_SUBSTR = [
    "bot", "preprint", "biorxiv", "medrxiv", "arxiv", "awakari",
    ".brid.gy", "rss", "-feed", "feedbot", "headlines",
]

# Org / institutional accounts. Substring match on handle OR display name.
ORG_SUBSTR = [
    "foundation", "charity", "biosolutions", "research", "institute", "universit",
    "college", "centre", "center", "clinic", "hospital", "health", "network",
    "society", "associat", "trust", "journal", "press", "official", ".gov",
    "nonprofit", "awareness", "alliance", "project", "ctf", "advocacy", "ngo",
]

HIGHVOL_THRESHOLD = 8  # accounts with >= this many posts treated as org/feed-like


def has_any(text: str, terms: list[str]) -> bool:
    return any(t in text for t in terms)


def classify_account(handle: str, display: str, post_count: int) -> str:
    h = (handle or "").lower()
    d = (display or "").lower()
    if has_any(h, BOT_HANDLE_SUBSTR):
        return "bot"
    if has_any(h, ORG_SUBSTR) or has_any(d, ORG_SUBSTR) or post_count >= HIGHVOL_THRESHOLD:
        return "org_or_highvolume"
    return "individual"


def precision_tier(text_lc: str, matched_query: str) -> str:
    if has_any(text_lc, HIGH_PRECISION):
        return "A"
    # only got here via a bare NF1/NF2 token match
    if has_any(text_lc, MEDICAL_CONTEXT):
        return "B"
    return "C"


def main() -> None:
    rows = [json.loads(l) for l in IN_FILE.open(encoding="utf-8")]
    post_counts = collections.Counter(r["author_handle"] for r in rows)

    kept, dropped = [], []
    seen_text = set()  # dedupe (author, normalized text) reposts

    for r in rows:
        handle = r.get("author_handle") or ""
        text = r.get("text") or ""
        text_lc = text.lower()
        acct = classify_account(handle, r.get("author_display_name") or "",
                                post_counts[handle])
        tier = precision_tier(text_lc, r.get("matched_query", ""))
        r["account_type"] = acct
        r["precision_tier"] = tier

        # dedupe identical reposts from the same author
        norm = re.sub(r"\s+", " ", text_lc).strip()
        key = (handle, norm)

        if acct == "bot":
            r["drop_reason"] = "automated account (bot/preprint/bridge feed)"
        elif tier == "C":
            r["drop_reason"] = "ambiguous NF1/NF2 match, no disease/medical context"
        elif norm and key in seen_text:
            r["drop_reason"] = "duplicate repost from same author"
        else:
            r["drop_reason"] = None

        if r["drop_reason"] is None:
            seen_text.add(key)
            kept.append(r)
        else:
            dropped.append(r)

    with KEEP_FILE.open("w", encoding="utf-8") as fh:
        for r in kept:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")
    with DROP_FILE.open("w", encoding="utf-8") as fh:
        for r in dropped:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")

    # --- summary -------------------------------------------------------------
    by_acct = collections.Counter(r["account_type"] for r in kept)
    by_tier = collections.Counter(r["precision_tier"] for r in kept)
    drop_reasons = collections.Counter(r["drop_reason"] for r in dropped)
    individuals = [r for r in kept if r["account_type"] == "individual"]

    summary = {
        "raw_posts": len(rows),
        "kept": len(kept),
        "dropped": len(dropped),
        "kept_by_account_type": dict(by_acct),
        "kept_by_precision_tier": dict(by_tier),
        "drop_reasons": dict(drop_reasons),
        "kept_individual_posts": len(individuals),
        "kept_unique_authors": len({r["author_handle"] for r in kept}),
    }
    SUMMARY_FILE.write_text(json.dumps(summary, indent=2))

    print(f"raw posts          : {len(rows)}")
    print(f"kept (relevant)    : {len(kept)}")
    print(f"dropped            : {len(dropped)}")
    print("\nkept by account type:")
    for k, v in by_acct.most_common():
        print(f"  {v:6d}  {k}")
    print("\nkept by precision tier (A=high, B=NF1/2+context):")
    for k, v in sorted(by_tier.items()):
        print(f"  {v:6d}  tier {k}")
    print("\ndrop reasons:")
    for k, v in drop_reasons.most_common():
        print(f"  {v:6d}  {k}")
    print(f"\n=> {len(individuals)} posts from likely-individual accounts")
    print(f"=> wrote {KEEP_FILE.name}, {DROP_FILE.name}, {SUMMARY_FILE.name}")


if __name__ == "__main__":
    main()
