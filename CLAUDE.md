## Working in this repo

- Swift work: use the `swift-without-mac` skill (local Swift 6 compile + tests, pbxproj registration). Unit-test target: `AmperfyKitTests`; the scheme's `AmperfyTests` and `AmperfyUITests` entries are stale.
- Branches: `replaygain` is the fork's **default branch**: Caio's Amperfy with every feature merged in, plus CI and this file. `feature/*` (off `upstream/master`) are upstream-PR material and stay free of CI and agent docs. `master` mirrors upstream untouched.
- Syncing upstream: `gh repo sync caioniehues/amperfy --branch master` (the default-branch sync would target `replaygain`), then merge `master` into `replaygain`. Upstream PRs: `gh pr create -R BLeeEZ/amperfy --base master --head caioniehues:feature/<name>`.

## Agent skills

### Issue tracker

GitHub Issues on the fork caioniehues/amperfy (never upstream BLeeEZ/amperfy). See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
