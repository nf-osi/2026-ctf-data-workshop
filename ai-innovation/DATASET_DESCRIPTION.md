# Bluesky Neurofibromatosis (NF) Patient-Voice Dataset

A curated corpus of public Bluesky posts mentioning neurofibromatosis (NF1, NF2,
schwannomatosis), collected and filtered to surface genuine **patient and
family/caregiver lived-experience** voices, with emphasis on symptom and
medication mentions.

- **Collected:** 2026-06-27
- **Source:** Bluesky (AT Protocol public network) via the authenticated
  `app.bsky.feed.searchPosts` API
- **Purpose:** NF-OSI / Sage Bionetworks research into NF patient-reported
  experience, symptoms, and treatment.

---

## Provenance & method

1. **Collection** (`bluesky_nf_search.py`) — authenticated search over 9 specific
   query terms (`neurofibromatosis`, `neurofibroma`, `schwannomatosis`, `"NF1"`,
   `"NF2"`, `von Recklinghausen`, `plexiform neurofibroma`, `#neurofibromatosis`,
   `#NF1`). Bare "NF" was excluded as too noisy. Paginated via cursor, deduped by
   post URI. **Raw yield: 12,130 posts.**

2. **Cleaning** (`clean.py`) — rule-based, fully auditable (every dropped post
   carries a `drop_reason`). Removed automated accounts (news/preprint/bridge/LLM
   bots — notably `nfbot.bsky.social`, which alone was 76% of the raw pull),
   ambiguous `NF1`/`NF2` matches lacking any disease/medical context (e.g. a video
   game using "NF1" as a price label, chess notation "Nf2#"), and same-author
   duplicate reposts. **Cleaned: 1,170 NF-relevant posts.**

3. **Curation** (30-agent classification workflow + `merge_curation.py`) — each
   post labeled for speaker type, symptom/medication mentions, and
   lived-experience themes. **Curated patient/family set: 160 posts.**

---

## Files

| File | Rows | Description |
|---|---|---|
| `data/bluesky_nf_posts.jsonl` | 12,130 | Raw search results (deduped by URI) |
| `data/bluesky_nf_clean.jsonl` | 1,170 | Cleaned, NF-relevant posts |
| `data/bluesky_nf_dropped.jsonl` | 10,960 | Dropped posts, each with `drop_reason` (audit trail) |
| `data/bluesky_nf_labeled.jsonl` | 1,170 | Cleaned posts + agent curation labels |
| `data/bluesky_nf_patient_voices.jsonl` | 160 | **Curated patient + family lived-experience voices** |
| `data/bluesky_nf_summary.json` | — | Cleaning counts |
| `data/bluesky_nf_curation_summary.json` | — | Curation counts |

---

## Schema (`bluesky_nf_labeled.jsonl` / `bluesky_nf_patient_voices.jsonl`)

| Field | Type | Description |
|---|---|---|
| `uri`, `cid` | str | Bluesky post identifiers |
| `created_at`, `indexed_at` | str | Timestamps |
| `author_handle`, `author_did`, `author_display_name` | str | Author |
| `text` | str | Post text |
| `langs` | list | Declared languages |
| `reply_count`, `repost_count`, `like_count` | int | Engagement |
| `matched_query` | str | Search term that first matched the post |
| `account_type` | str | Cleaning label: `individual` / `org_or_highvolume` / `bot` |
| `precision_tier` | str | `A` (disease term) / `B` (NF1-2 + medical context) |
| `voice_type` | str | Curation label (see below) |
| `mentions_symptoms` | bool | Describes NF symptoms |
| `symptoms` | list | Extracted symptom mentions |
| `mentions_medication` | bool | Mentions a drug/treatment/surgery |
| `medications` | list | Extracted medication/treatment mentions |
| `lived_experience` | bool | Conveys personal/family lived experience |
| `themes` | list | e.g. `diagnosis_journey`, `pain_management`, `daily_living` |
| `curate_keep` | bool | True = genuine patient/family voice kept in curated set |
| `confidence` | float | Classifier confidence (0–1) in `voice_type` |
| `rationale` | str | One-line classifier justification |
| `raw` | obj | Full original Bluesky post record |

### `voice_type` values
`patient`, `family_caregiver`, `clinician_researcher`, `advocacy_org`,
`news_media`, `fundraiser_promo`, `unrelated_false_positive`, `unclear`.

---

## Composition

**Voice types across the 1,170 cleaned posts:**

| Voice type | Count |
|---|---|
| advocacy_org | 468 |
| clinician_researcher | 297 |
| patient | 113 |
| news_media | 99 |
| unrelated_false_positive | 83 |
| family_caregiver | 58 |
| unclear | 30 |
| fundraiser_promo | 22 |

**Curated set (160 patient + family voices):** 87 mention symptoms, 30 mention
medication. Top themes: `daily_living` (108), `diagnosis_journey` (84),
`mental_health` (53), `tumor_burden` (49), `treatment_experience` (25),
`surgery` (21), `genetics_inheritance` (23), `pain_management` (12).

**Representative medication/treatment mentions:** selumetinib→mirdametinib
switch, lidocaine patches for nerve pain, surgical tumor excision, HRT decisions
with NF1.

---

## Limitations & ethical notes

- **Small corpus.** Bluesky's NF patient signal is modest (~160 curated voices);
  smaller than r/neurofibromatosis would yield. Not population-representative.
- **Platform skew.** Bluesky users skew toward certain demographics; advocacy
  orgs and researchers are over-represented relative to patients.
- **Label noise.** `symptoms`/`medications`/`voice_type` are LLM-extracted and
  not clinically validated; `confidence` is the model's self-estimate.
- **Public but sensitive.** All posts were publicly accessible and collected via
  Bluesky's official API within ToS. Even so, these are health disclosures by
  individuals — handle with care, avoid re-identification, and follow applicable
  IRB/data-governance guidance before any downstream use or redistribution.

---

## Reproduce

```bash
cp .env.example .env          # add Bluesky handle + app password
python bluesky_nf_search.py   # -> data/bluesky_nf_posts.jsonl
python clean.py               # -> data/bluesky_nf_clean.jsonl (+ dropped, summary)
# 30-agent curation workflow -> classifications
python merge_curation.py data/classifications.json  # -> labeled + patient_voices
```
