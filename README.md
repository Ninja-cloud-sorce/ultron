# Compass

An AI-powered journaling app for iOS. Write, reflect, and stay aligned with who you want to become.

---

## Table of Contents

1. [Purpose](#purpose)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Features](#features)
5. [Demo](#demo)
6. [Release Notes](#release-notes)
7. [Contact](#contact)

---

## Purpose

Most journaling apps give you a blank page. Compass gives you a direction.

You set a single long-term goal — your **North Star** — and every entry you write is analyzed against it using Gemini AI. Are you moving toward it, holding steady, or drifting? Compass tells you, and coaches you back on track.

The capture flow lets you scan handwritten journal pages. Your words are extracted via on-device OCR, cleaned by AI, and then re-typed onto a notebook page — word by word — before you save them.

---

## Requirements

| | Minimum |
|---|---|
| iOS | 17.0 |
| Xcode | 15.4 |
| Swift | 5.9 |

---

## Installation

**1. Clone**

```bash
git clone https://github.com/Ninja-cloud-sorce/ultron.git
cd ultron
open ultron.xcodeproj
```

**2. Add `Config.plist`**

Create `ultron/Config.plist` and add the following keys. This file is gitignored — never commit it.

```
FIREBASE_GOOGLE_APP_ID
FIREBASE_GCM_SENDER_ID
FIREBASE_CLIENT_ID
FIREBASE_API_KEY
FIREBASE_PROJECT_ID
FIREBASE_STORAGE_BUCKET
GEMINI_API_KEY
```

**3. Run**

Select a simulator or device and press `⌘R`.

> If `Config.plist` is missing, the app runs in demo mode — Firebase auth is disabled and AI features return mock data.

---

## Features

**Write** — Typed entries with mood, title, tags, and writing prompts.

**Capture** — Scan handwritten pages with your camera. Apple Vision extracts the text on-device. Gemini fixes OCR errors while preserving your exact wording. The cleaned text then writes itself onto a notebook page, word by word.

**AI Reflection** — Gemini 2.0 Flash analyzes each entry against your North Star and returns a direction (Toward / Neutral / Away), an alignment score, coaching advice, and themes.

**Observatory** — Mood trend charts and AI-surfaced insights across any time window.

**Library** — Browse your entries by Timeline, On This Day, or Favorites. Full-text search.

**Compass Monument** — Tap the lighthouse to activate a beam animation. Gemini loads your latest guidance inline.

**Campfire** — Writing streak tracker and weekly mood chart.

**Reflection Garden** — Gratitude counter with a spring bloom animation.

**Museum** — Your curated Lessons, Quotes, and Memories.

**Themes** — Dark · Soft Cream · Midnight · OLED Black · System.

**Notifications** — Morning reminder, evening reflection, weekly check-in, and motivational quotes.

---

## Demo

<p align="center">
  <img src="assets/demo.gif" width="480" alt="Compass Demo" />
</p>

---

## Release Notes

**v1.0** — July 2026
- Initial release
- North Star onboarding
- Write and Capture entry flows
- Gemini analysis pipeline
- Observatory, Library, Museum, Campfire, Reflection Garden, Compass Monument
- 5 themes, 4 notification types, Achievements

---

## Contact

Built by [@Ninja-cloud-sorce](https://github.com/Ninja-cloud-sorce)
