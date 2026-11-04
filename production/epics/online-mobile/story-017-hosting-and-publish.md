# Story 017: Hospedagem e publicação: proposta, deploy e teste em celular real

> **Epic**: online-mobile
> **Status**: Ready
> **Layer**: Release
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md` and the user's request of 2026-11-03: play over the internet and install on the phone
**Requirement**: friends open one URL on their phones, install the game and play a match
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). The hosting choice is still open: the user asked for a proposal.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] A short comparison (2 or 3 options: free/cheap static hosting for the client plus a small VM or container service for the match server; or both on one small VPS) with monthly cost, setup effort, WebSocket and TLS support, region latency from Brazil and the limits that matter; the user picks one before any deploy. Recorded in `docs/hosting.md`.
- [ ] The match server runs at the chosen host from the story 016 recipe, with a `wss://` URL and TLS from a managed or automatic certificate.
- [ ] The Web build (stories 013 to 015) is published at an HTTPS URL, pointing at that server by default.
- [ ] One publish script (or CI job) builds and uploads the client and restarts or updates the server; running it twice in a row is safe.
- [ ] A smoke check after every publish (open the page, create a room, a second client joins) runs from a script and reports pass or fail.
- [ ] A real-device test: two phones (one Android, one iPhone if available), at least one on mobile data, install the app, create and join a room and play to the result; notes with device models and problems found are kept as a playtest report.
- [ ] A `README` section "Como jogar e instalar" in Portuguese: the URL, installing on Android and on iPhone, creating and joining a room.
- [ ] Costs and secrets: no secret or token is committed; the hosting bill's monthly estimate is stated in `docs/hosting.md`.

---

## Implementation Notes

Do not deploy before the user approves the option. Anything that creates accounts, spends money or publishes is the user's decision: prepare the commands and ask. Keep the server address in one deploy variable so the client build and the server agree.

---

## Out of Scope

- A custom domain, analytics, monitoring dashboards (a first-cut uptime check is enough). Native apps.

---

## Files

- `docs/hosting.md`, `README.md`, `tools/publish.*`, `tools/smoke-check.*`
- `production/qa/playtests/` (the device test report)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: a playtest report in `production/qa/playtests/` naming this story, with the two-phone match; tests waived at `qa.level: minimal`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/online-mobile/story-013-web-client.md`, `production/epics/online-mobile/story-014-phone-usability.md`, `production/epics/online-mobile/story-015-installable-pwa.md`, `production/epics/online-mobile/story-016-internet-ready-server.md`
- Unlocks: None
