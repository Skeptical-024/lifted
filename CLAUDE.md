# LIFTED — Claude Standing Rules

This is a Roblox 4v1 asymmetric heist game built with Rojo and Luau. All sessions must follow the rules below without exception. Read this file at the start of every session.

## Server authority
- The server validates and owns all state. Clients **request**; the server **decides**.
- Every `RemoteEvent` handler on the server must check: role, round state, distance, payload types, and rate limit (via `RemoteGuardService`) before acting.
- Never compute authoritative outcomes (progress, score, win conditions, positions used for validation) on the client.

## PlayerStateService is the source of truth
- `PlayerStateService` is the single authoritative record for role and per-round state.
- Player **attributes** (`Role`, `RoundState`, `HasIdol`, `IsCaged`, etc.) are display-only mirrors set by `setAttributes`. They are **never** authoritative. Do not branch server logic on attributes.

## Remote layout
- Remotes live **flat** under `ReplicatedStorage`. There must **never** be a `ReplicatedStorage.Remotes` folder.
- Use `getOrCreateRemote` from `GameManager` or the same pattern in services for all remote creation.

## Performance / CCU
- Prefer events over per-frame loops. Throttle any loop that scans all players or tagged parts.
- Cache part references that do not change within a round (spawn parts, cage, rescue point, idol, vault, extract points).
- Never do workspace-wide descendant scans in hot paths.
- Pool repeatedly created/destroyed instances where possible.
- Avoid high-frequency attribute writes that replicate to all clients.

## Win-condition guards
- Do **not** touch the `endingRound`, `forcedWinner`, `resultsFired` flags in `GameManager` without explicit instruction and matching tests. These guards are correct and fragile.

## API conventions
- Use `task.wait`, `task.spawn`, `task.delay`, `task.defer` — not deprecated globals (`wait`, `spawn`, `delay`).
- Set instance properties before parenting them.

## Test map
- `TestMapService` ships until the real map is integrated. Do **not** delete it and do **not** hardcode logic to test-map coordinates.
- All gameplay parts (spawn points, cage, vault, idol, extract points) are provided via `CollectionService` tags.

## Build gate
- After every change, run `~/.aftman/bin/rojo build default.project.json` from the project root and confirm it exits 0 before marking a task done.
- If the build fails, fix the syntax error before proceeding.

## PROGRESS.md
- Maintain `PROGRESS.md` at the repo root. Append a dated entry per hardening pass listing what changed and exactly how to test it.
