# Mahjong Zen Garden — project anchor

**Status:** 🟡 In development (rebranded 2026-04-30 from "Neon Mahjong")
**App Store name:** Mahjong Zen Garden
**Bundle ID:** TBD
**ASC App ID:** TBD

## Read first
- `project_neon_mahjong.md` — product overview, stone garden theme
- `project_neon_mahjong_v11.md` — v1.1 hybrid F2P monetization plan
- `reference_neon_mahjong_github.md` — code + site repos under anulfito1991-wq

## What this app is
Classic Mahjong solitaire (tile matching) with a **warm earth-tone "stone garden" aesthetic** — explicitly NOT neon. Rebrand happened 2026-04-30 because the original "Neon Mahjong" framing fought the meditative core of the genre.

## Visual tone — non-negotiable
- Earth tones, stone textures, soft natural light. Zen garden visual metaphor.
- **No neon** (per `feedback_visual_neon.md`). The rebrand is the proof point that neon was wrong for this app.
- Apply `feedback_visual_polish_playbook.md` (painted textures, ambient drift, gentle Metal shaders if scoped).

## Monetization (per `project_neon_mahjong_v11.md`)
Hybrid F2P:
1. **Themes IAP** — alternate garden aesthetics
2. **Remove Ads** — one-time
3. **Rewarded video** — currently stubbed; wire up when ready

## Hard constraints
- **No streak shaming** (mahjong solitaire is a "play when calm" game, not a daily-streak game)
- **Banner/interstitial discipline** — never interrupt a tile-match resolution

## Cross-cutting playbooks that apply
- Onboarding: `feedback_onboarding_playbook.md` Track A (drop into fun)
- App feel & retention: `feedback_app_feel_retention.md`
- Visual polish: `feedback_visual_polish_playbook.md`
- Submission: `feedback_app_submission.md`, `feedback_asc_api_quirks.md`
- Xcode: `feedback_xcode_info_plist.md`, `feedback_xcode_entitlements.md`, `feedback_swift6_main_actor_default.md`
- IAP: `feedback_first_iap_must_bundle_with_version.md` (first IAP must bundle with version via web UI, not API)
