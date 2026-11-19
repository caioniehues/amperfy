## Working in this repo

- Swift work: use the `swift-without-mac` skill (local Swift 6 compile + tests, pbxproj registration). Unit-test target: `AmperfyKitTests`; the scheme's `AmperfyTests` and `AmperfyUITests` entries are stale.
- Branches: `feature/*` (off `upstream/master`) are upstream-PR material and stay free of CI and agent docs; `replaygain` is the build branch (CI + this file) that merges them.

## Agent skills

### Issue tracker

GitHub Issues on the fork caioniehues/amperfy (never upstream BLeeEZ/amperfy). See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
