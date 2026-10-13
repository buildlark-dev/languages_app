# Development

How to set this project up, run it and publish it. For what the app is and why,
see the [README](../README.md).

**Initial languages:** English, French and Portuguese. The architecture is built so a
new language can be added without touching the learning engine.

## Status

Early development. Project governance lives in
[`.specify/memory/constitution.md`](../.specify/memory/constitution.md) and is required
reading before contributing.

## Stack

| Piece | Choice |
|---|---|
| Language | Dart |
| Framework | Flutter (SDK `^3.12.2`) |
| Editor | Visual Studio Code |
| Primary platforms | Android and Web |
| Hosting | Firebase Hosting → `languages.buildlark.com` |

## Architecture

Dependencies flow one way: `ui → engine → core ← content`.

```
lib/
  core/                   shared models and contracts
  engine/                 learning logic (scoring, SRS, unlocks)
  ui/                     screens and widgets
  content/<language>/     teaching data per language (en, fr, pt, ...)
  services/               persistence, speech, Firebase
  main.dart               entry point
```

The engine knows no specific language: all content lives in `lib/content/<language>/`
and implements the contracts in `lib/core/`. An architecture test inspects imports and
fails if anything outside the composition root reaches into `lib/content/`.

## Commands

Install dependencies:

```bash
flutter pub get
```

Run on the connected device or emulator:

```bash
flutter run
```

The quality gates, required before every commit:

```bash
flutter analyze && flutter test
```

## Building and deploying the web app

Use the script, not `flutter build web` on its own:

```bash
pwsh -File tool/build_web.ps1 -Deploy
```

It exists because a plain build published a broken bundle once. It wipes the
incremental build state, stamps a build id the running app uses to notice new
versions, refuses to publish if the generated web plugin registry is missing a plugin,
and prints the cache headers of the files Flutter does not content-hash — the one
failure that is invisible from a browser and only shows up in the headers.

## Workflow

Development follows [Spec Kit](https://github.com/github/spec-kit):
`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`, with
`/speckit-converge` between passes to find what the code still owes the spec.

`main` advances by merged pull request, enforced on the server by a branch ruleset:
direct pushes and force pushes are rejected, and the two CI checks must pass before a
merge is possible.
