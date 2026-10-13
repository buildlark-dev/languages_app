<!--
  The constitution asks two things of every pull request: that it names the principles
  it exercises and says how it was verified. This template exists so that happens by
  default instead of depending on someone remembering — which is what failed on PR #2,
  whose description kept saying "No application code yet" for thirty-odd commits after
  it stopped being true.

  Delete the sections that do not apply. A template that forces you to fill empty boxes
  gets filled in falsely, and then it verifies nothing.
-->

## What this changes

<!-- Two or three lines: what the app does differently now, not which files were
     touched. The diff already lists the files. -->

## Why

<!-- The problem it solves. If it comes from an observed failure, give the evidence:
     the error message, the measurement, the steps to reproduce. A measured cause is
     worth more than an explained one. -->

## How it was verified

- [ ] `flutter analyze` — no errors, no warnings
- [ ] `flutter test` — green (N tests)
- [ ] Affected screens opened and looked at by hand
- [ ] Checked on the deployment, if this touches web or the deploy

<!-- Principle V: if a test fails or is skipped, say so explicitly. Reporting "done"
     over unverified work is forbidden, so write here what was NOT checked, and why. -->

## Constitution

<!-- Tick only the ones this change really exercises, and say how it is demonstrated.
     "It complies" without evidence is not an answer. -->

| | Principle | How this PR demonstrates it |
|---|---|---|
| ☐ | I — Content decoupled from the engine | |
| ☐ | II — One file, one responsibility | |
| ☐ | III — Verifiable pedagogical rigour | |
| ☐ | IV — Student progress is sacred | |
| ☐ | V — Nothing is finished without proof | |
| ☐ | VI — Didactic, socialised code | |
| ☐ | VII — Mobile first and accessible | |

## Known limitations

<!-- What is left out, what was deliberately degraded, and what could not be checked.
     Stating it here is part of the work: a written limit is a decision, a silent one
     is a surprise for whoever finds it. -->
