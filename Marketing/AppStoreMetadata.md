# Neon Mahjong — App Store Connect Metadata

Everything below is **paste-ready** for App Store Connect. Sections map 1:1 to the App Store Connect form fields.

---

## App Information

| Field | Value | Notes |
|---|---|---|
| **App Name** | `Neon Mahjong Solitaire` | 22 chars (max 30). Keeps "Mahjong" + "Solitaire" both in the name for ASO — these are the two highest-volume search terms in the category. |
| **Subtitle** | `Match Tiles · Daily Puzzles` | 28 chars (max 30). Subtitle is heavily weighted for search; packs two more keyword phrases. |
| **Bundle ID** | `com.AnulfoAcosta.neonmahjong` | (set in Xcode, matches NeonBlocks pattern) |
| **SKU** | `neonmahjong001` | Internal-only; any unique string works. |
| **Primary Language** | English (U.S.) | |

### Categories

- **Primary Category:** Games
  - **Subcategory:** Puzzle
- **Secondary Category:** Games
  - **Subcategory:** Board

---

## Pricing & Availability

| Field | Value |
|---|---|
| **Price** | Free |
| **Availability** | All territories |
| **Pre-Order** | No |

---

## Version Information (per release)

### Promotional Text (170 char max — editable anytime without resubmission)

```
✨ Now with 5 stunning layouts and Daily Challenges! Play Shanghai Turtle, Dragon, and more in modern neon style. Free to play, no time limits.
```
*(159 chars)*

### Description (4,000 char max)

```
Match. Glow. Repeat.

Neon Mahjong Solitaire reinvents the timeless tile-matching puzzle in stunning modern neon style. Match free pairs of identical tiles to clear the board — but with a futuristic glow that brings every game to life.


★ FIVE STUNNING LAYOUTS

• Neon Pyramid — the modern classic (144 tiles)
• Shanghai Turtle — the iconic shell shape (144 tiles)
• Dragon — long, sweeping horizontal stretch (144 tiles)
• Cathedral — tall and narrow (144 tiles)
• Sparkstone — quick play (72 tiles, perfect for a coffee break)


★ DAILY CHALLENGE

A new puzzle every day, the same one for every player worldwide. Build your win streak and see how long you can keep it going. Miss a day, lose your streak — it's that simple, that compelling.


★ MODERN POLISH

• Smooth animations and satisfying haptics
• Pulsing glow on every tile
• Particle bursts on every match
• Eye-friendly dark visuals
• Designed for iPhone and iPad


★ THOUGHTFUL GAMEPLAY

• Hint system to unstick you
• Undo any move
• Shuffle when you're stuck
• Always-solvable boards (no impossible games)
• Full 144-tile set: all suits, winds, dragons, flowers, and seasons


★ TRACK YOUR PROGRESS

• Best times per layout
• Win streak tracking
• Worldwide Game Center leaderboards
• Detailed stats screen


★ PERSONALIZE WITH THEMES

Unlock alternate neon palettes:
• Solar Flare — sunset reds and gold
• Cyberbloom — magenta in moonlight
• Ocean Drift — below the waves


★ NO PRESSURE

• No timers (unless you want to track your time)
• No energy or lives system
• No interruptions during gameplay
• Play offline, anytime, anywhere


★ GENEROUS FREE TIER

• All 5 layouts free
• Daily Challenge free
• 3 hints per game free
• Watch a short ad for unlimited hints, or upgrade to Remove Ads forever


Whether you're a Mahjong veteran or new to tile-matching puzzles, Neon Mahjong is the most beautiful way to play. Match tiles, beat your best time, and unwind in a glow-up of color and sound.

Privacy: We don't collect personal data. Game Center sign-in is optional.

— —
In-App Purchases:
• Theme Packs (Solar Flare, Cyberbloom, Ocean Drift) — $1.99 each
• Remove Ads Forever — $3.99
```

### Keywords (100 char max — comma-separated, NO spaces after commas)

```
mahjongg,tile,match,puzzle,brain,daily,zen,relax,offline,shanghai,pairs,classic,neon,arcade,casual
```
*(98 chars)*

**Keyword strategy notes:**
- Skipped `mahjong` and `solitaire` — both in app name, Apple already indexes those automatically.
- `mahjongg` (alternate spelling) catches users who search incorrectly.
- `daily` and `offline` are App Store-favored differentiators.
- `zen` / `relax` / `casual` target the "unwinding" audience.
- `shanghai` is the historic name for the layout, often searched.

### What's New in this Version (4,000 char max)

**For v1.0 (first submission):**
```
Welcome to Neon Mahjong Solitaire — a brand new take on the timeless tile-matching puzzle, built from the ground up for iPhone and iPad.

• 5 unique board layouts including the iconic Shanghai Turtle
• Daily Challenge with worldwide streak tracking
• Game Center leaderboards for every layout
• 4 themes to personalize your glow
• Always-solvable boards (no impossible games)
• No timers, no pressure, no energy system
• Beautifully animated, satisfyingly tactile

Enjoy the glow.
```

**For v1.1 (post-launch update):**
```
The Glow gets brighter.

• Watch-ad-for-hint flow keeps free play generous
• "Remove Ads" upgrade unlocks unlimited hints forever
• Polishing across all 5 layouts
• Performance and stability improvements

Thanks for playing!
```

---

## URLs

| Field | Value | Notes |
|---|---|---|
| **Support URL** | `https://anulfito1991-wq.github.io/Neon-Mahjong-site/support.html` | Live · serves the FAQ + contact email. |
| **Marketing URL** | `https://anulfito1991-wq.github.io/Neon-Mahjong-site/` | Live · landing page. Optional but recommended. |
| **Privacy Policy URL** | `https://anulfito1991-wq.github.io/Neon-Mahjong-site/privacy.html` | Live · **required**. Update this page when AdMob lands in v1.2. |

---

## Copyright

```
© 2026 Anulfo Acosta
```

---

## Age Rating

Click **Edit** next to Age Rating. For all questions, answer:

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Gambling | **None** *(Mahjong Solitaire is single-player puzzle, not the four-player gambling game — this is the correct answer)* |
| Contests | None |
| Unrestricted Web Access | No |
| Medical/Treatment Information | None |

**Result: Age 4+**

---

## App Privacy

Click **Edit** next to App Privacy. Configure as follows:

### Data Collection

**v1.0 / v1.1 (no AdMob yet):**
- Select: **No, we do not collect data from this app**

**When you add AdMob (later):**
- Select: **Yes, we collect data from this app**
- Add data type: **Identifiers** → **Device ID** → Used for: **Third-Party Advertising** → Linked to user: **No** → Tracking: **Yes**
- Add data type: **Diagnostics** → **Crash Data, Performance Data** → Used for: **App Functionality** → Linked: **No** → Tracking: **No**

### Tracking
**v1.0 / v1.1:** Not applicable.
**With AdMob:** Yes — tracking enabled, requires `NSUserTrackingUsageDescription` in Info.plist.

---

## App Review Information

| Field | Value |
|---|---|
| **Sign-In Required** | No |
| **First Name** | Anulfo |
| **Last Name** | Acosta |
| **Phone** | *(your contact number)* |
| **Email** | *(your contact email)* |
| **Notes** | See below |

### Notes for Reviewer

```
Neon Mahjong Solitaire is a single-player tile-matching puzzle game. No login is required and all gameplay is accessible immediately on launch.

In-App Purchases:
- Three cosmetic theme unlocks ($1.99 each)
- One "Remove Ads" upgrade ($3.99) which removes the per-game hint cap
All IAPs are non-consumable and persist across reinstalls via App Store restore.

Optional Game Center integration provides per-layout leaderboards. Game Center sign-in is not required to play.

This is "Mahjong Solitaire" (single-player tile matching), not the multi-player gambling game of Mahjong. There is no real-money or virtual gambling.

Thank you for your review!
```

---

## In-App Purchases (configure under My Apps → In-App Purchases)

Add each as **Non-Consumable**, with the IDs and prices below. **Product IDs must match the StoreKit Configuration file exactly.**

| Reference Name | Product ID | Price | Localization |
|---|---|---|---|
| Solar Flare Theme | `com.anulfito.mahjong.theme.solarflare` | $1.99 (Tier 2) | "Solar Flare Theme" — "Sunset reds, deep oranges, and gold. Warm and dramatic." |
| Cyberbloom Theme | `com.anulfito.mahjong.theme.cyberbloom` | $1.99 (Tier 2) | "Cyberbloom Theme" — "Hot magenta, lavender, and electric purple. Florals at night." |
| Ocean Drift Theme | `com.anulfito.mahjong.theme.oceandrift` | $1.99 (Tier 2) | "Ocean Drift Theme" — "Cool teals, aquamarines, and deep blues. Below the waves." |
| Remove Ads | `com.anulfito.mahjong.removeads` | $3.99 (Tier 4) | "Remove Ads" — "Removes all ads forever and unlocks unlimited hints. One-time purchase." |

**Each IAP also needs:**
- Review Screenshot (640×920 minimum) — can be any screenshot of the IAP entry point in your app
- Review Notes — `Tap Settings → UPGRADES → Remove Ads to test purchase.` (or for themes: `Settings → Appearance → Themes → tap a locked theme.`)

---

## Game Center (configure under My Apps → Services → Game Center)

Enable Game Center, then add **5 leaderboards** (one per layout). Sort: **Low to High**. Score Format: **Elapsed time**, formatted to integer seconds.

| Leaderboard ID | Reference Name | Localization |
|---|---|---|
| `com.anulfito.mahjong.leaderboard.bestTime.neon_pyramid` | Neon Pyramid Best Time | "Neon Pyramid · Best Time" |
| `com.anulfito.mahjong.leaderboard.bestTime.shanghai_turtle` | Shanghai Turtle Best Time | "Shanghai Turtle · Best Time" |
| `com.anulfito.mahjong.leaderboard.bestTime.dragon` | Dragon Best Time | "Dragon · Best Time" |
| `com.anulfito.mahjong.leaderboard.bestTime.sparkstone` | Sparkstone Best Time | "Sparkstone · Best Time" |
| `com.anulfito.mahjong.leaderboard.bestTime.cathedral` | Cathedral Best Time | "Cathedral · Best Time" |

---

## Marketing Screenshots

You already have these, generated by `bin/take-screenshots.sh`:

- `Screenshots/iPhone-6.9/` → upload to **6.9" iPhone Display** slot
- `Screenshots/iPad-13/` → upload to **13" iPad Display** slot

Apple auto-scales these to the smaller required sizes. Order them: `menu`, `game`, `layouts`, `stats`, `win`.

**Optional polish:** add overlay text in Figma/Sketch ("MATCH TILES IN NEON STYLE", "5 ICONIC LAYOUTS", "DAILY CHALLENGE", etc.) to give each screenshot a marketing headline. Not required, but it materially boosts conversion.

---

## Submission Checklist

Before clicking **Submit for Review**:

- [ ] Bundle version + marketing version bumped (1.0.0)
- [ ] StoreKit Configuration scheme setting **disabled** for Release (only on for local testing)
- [ ] All 4 IAPs created in App Store Connect, "Ready to Submit" status
- [ ] All 5 Game Center leaderboards created
- [ ] Privacy policy live at the URL above
- [ ] App icon set in `Assets.xcassets/AppIcon.appiconset/` (use the in-app exporter)
- [ ] Tested IAPs with sandbox account
- [ ] Tested Game Center auth + leaderboard submission
- [ ] All screenshots uploaded
- [ ] Age rating confirmed at 4+
- [ ] App Review notes filled in

---

## ASO Tips for Discovery

1. **Re-localize for top markets.** Add Spanish, German, Japanese, Simplified Chinese localizations of name + keywords + description (these are 4 of the top 6 puzzle-game markets). Even machine translation is better than English-only.
2. **Update Promotional Text monthly.** It doesn't require resubmission and Apple weighs freshness.
3. **Reply to every review** in the first 90 days. Builds the algorithm signal Apple uses for "responsive developer."
4. **Run a launch promo.** Drop one theme to free for week 1 to seed reviews. (Then re-list at $1.99.)
5. **Submit for App Store editorial.** Use App Store Connect → Editorial Submissions → highlight Neon Mahjong's design angle. Long shot but free.

---

*Last updated: 2026-04-28*
