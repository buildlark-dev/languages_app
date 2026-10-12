## Languages App
A language-learning app built with Flutter/Dart that takes a Spanish speaker from absolute zero to fluency, following a CEFR path (A1 to C2).

# Problem
Most language apps lock you into one language and mix content with logic, so adding a new language means rebuilding the app.

# Solution
A language-agnostic learning engine: all teaching content lives in lib/content/<language>/ and implements shared contracts, so new languages are added without touching the engine.

## Key features
- Initial languages: English, French, Portuguese
- CEFR-based progression (A1 to C2)
- Scoring, spaced repetition (SRS) and unlocks in a dedicated engine
- Clean, one-directional architecture
- Tech stack
- Flutter/Dart - Firebase Hosting - Android + Web

# Architecture
**ui -> engine -> core <- content.** Dependencies flow one way; the engine knows no specific language.

# Status
Early development.

# Demo
languages-buildlark.web.app

# Screenshots: Pending...

### For local setup and deployment, see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
