#!/usr/bin/env python3
"""Merge agent classifications back onto the cleaned posts and emit curated sets.

Usage: python merge_curation.py classifications.json
  where classifications.json is the workflow's returned {"classifications":[...]}
  (or a bare [...] array). Each item has at least: id, voice_type,
  mentions_symptoms, symptoms, mentions_medication, medications,
  lived_experience, themes, curate_keep, confidence, rationale.

Outputs:
  data/bluesky_nf_labeled.jsonl         all clean posts + labels
  data/bluesky_nf_patient_voices.jsonl  curated patient/family lived-experience set
  data/bluesky_nf_curation_summary.json counts
"""
import json, sys, collections
from pathlib import Path

DATA = Path(__file__).parent / "data"
CLEAN = DATA / "bluesky_nf_clean.jsonl"


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("pass the classifications JSON file path")
    raw = json.loads(Path(sys.argv[1]).read_text())
    cls = raw["classifications"] if isinstance(raw, dict) else raw
    by_id = {c["id"]: c for c in cls}

    posts = [json.loads(l) for l in CLEAN.open(encoding="utf-8")]
    labeled, voices = [], []
    for i, p in enumerate(posts):
        c = by_id.get(i)
        if not c:
            p["_label_missing"] = True
            labeled.append(p)
            continue
        for k in ("voice_type", "mentions_symptoms", "symptoms", "mentions_medication",
                  "medications", "lived_experience", "themes", "curate_keep",
                  "confidence", "rationale"):
            p[k] = c.get(k)
        labeled.append(p)
        if c.get("curate_keep") and c.get("voice_type") in ("patient", "family_caregiver"):
            voices.append(p)

    (DATA / "bluesky_nf_labeled.jsonl").write_text(
        "\n".join(json.dumps(p, ensure_ascii=False) for p in labeled) + "\n", encoding="utf-8")
    (DATA / "bluesky_nf_patient_voices.jsonl").write_text(
        "\n".join(json.dumps(p, ensure_ascii=False) for p in voices) + "\n", encoding="utf-8")

    vt = collections.Counter(p.get("voice_type") for p in labeled)
    sym = sum(1 for p in voices if p.get("mentions_symptoms"))
    med = sum(1 for p in voices if p.get("mentions_medication"))
    themes = collections.Counter(t for p in voices for t in (p.get("themes") or []))
    summary = {
        "labeled_total": len(labeled),
        "missing_labels": sum(1 for p in labeled if p.get("_label_missing")),
        "by_voice_type": dict(vt.most_common()),
        "patient_voices_kept": len(voices),
        "patient_voices_with_symptoms": sym,
        "patient_voices_with_medication": med,
        "top_themes": dict(themes.most_common(15)),
    }
    (DATA / "bluesky_nf_curation_summary.json").write_text(json.dumps(summary, indent=2))

    print(json.dumps(summary, indent=2))
    print(f"\nwrote bluesky_nf_labeled.jsonl, bluesky_nf_patient_voices.jsonl, "
          f"bluesky_nf_curation_summary.json")


if __name__ == "__main__":
    main()
