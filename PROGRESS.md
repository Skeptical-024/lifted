# PROGRESS

## 2026-06-06 — Hardening Pass 1

### Changes

**Task 0 — CLAUDE.md / PROGRESS.md**
Created `CLAUDE.md` with standing rules (server-authority, PlayerStateService truth, remote layout, perf/CCU, win-condition guards, API conventions, test-map policy, build gate). Created this `PROGRESS.md`.

**Task 1 — Lobby/countdown UI dead after round 1**
`src/client/LobbyClient.client.lua`: Added `menuActive = true` inside `onPlayClicked` so every Play click re-arms the lobby panel. Previously `menuActive` was set false on `roundStartedRemote`/`roleAssignedRemote` and never reset, causing all `LobbyUpdate` events from round 2 onward to be silently dropped.

**Task 2 — Eliminated thieves frozen/unrescuable with no UI**
- `src/server/GuardianController.lua`: Removed `ThiefCaught:FireAllClients` from `TryCatch`. The fire is now in `GameManager` after `MarkCaught` so `newState` can be included as a third argument.
- `src/server/GameManager.server.lua`:
  - Captured the `ThiefCaught` remote into a local variable; added `PlayerEliminated` remote.
  - Added `applyEliminatedTreatment(player)`: makes all character `BasePart`s non-collidable and fires `PlayerEliminated` to all clients.
  - Catch handler now branches on `newState`: `Caught` → `CageService.CagePlayer` (unchanged); `Eliminated` → `applyEliminatedTreatment`. `ThiefCaught` fires after `MarkCaught` with `newState` as third arg.
  - `CharacterAdded` handler: `Eliminated` state now calls `handleCaughtThief` + `applyEliminatedTreatment` instead of just `handleCaughtThief`.
- `src/client/CaughtFeedbackClient.client.lua`: Reads third `ThiefCaught` arg (`caughtState`); shows "ELIMINATED — OUT FOR THIS ROUND" on elimination and "YOU WERE CAUGHT" on first catch.
- `src/client/RoundUIClient.client.lua`: `RoundState` attribute change handler now handles `"Eliminated"` state with distinct directive text.

**Task 3 — RuntimeAudit runs in production**
`src/shared/Constants.lua`: `RUNTIME_AUDIT_ENABLED` changed from `true` to `false`. Audit loop only starts in Studio now.

**Task 4 — Caged state not restored from snapshot**
`src/client/RoundUIClient.client.lua`: `applyGameSnapshot` now reads `snapshot.cage.cagedPlayers`. If the local player's UserId is in that table, restores the "You are caged. Wait for rescue." directive. If a rescue is in progress, shows "Rescue in progress…" as well.

**Task 5 — Debug commands in private servers + QA commands**
- `src/server/GameManager.server.lua`: Added `forceStartRequested`/`skipCountdownRequested` flags; added `requestForceStart`/`requestSkipCountdown` functions; exposed them in `DebugCommandService.Init` deps; waiting and countdown loops respect the flags.
- `src/server/DebugCommandService.lua`: `Init` now also enables in private servers (`PrivateServerId ~= "" and PrivateServerOwnerId ~= 0`); per-command `canUse(player)` check gates to Studio, `DEBUG_COMMANDS_ENABLED`, or private-server owner. Added `forcestart` and `skiplobby` commands.

**Task 6 — Role intro double-fires**
`src/client/RoundUIClient.client.lua`: `showRoleIntro` replaced with a no-op; removed dead `roleIntroFrame.Visible = false` / `roleIntroShadow.Visible = false` cleanup lines from the `roundEndedRemote` handler. `RoleAnnouncementClient` is now the sole role-reveal.

**Task 7 — SessionAnalytics rounds table grows unbounded**
`src/server/SessionAnalyticsService.lua`: `StartRound` now caps `rounds` to 50 entries (ring buffer: `table.remove(rounds, 1)` when `#rounds > 50`). `GetLastRound` still returns `rounds[#rounds]`.

**Task 8 — Menu reshow hardcoded 4.5 s**
- `src/client/MainMenuClient.client.lua`: Added `require(Constants)`, changed `task.delay(4.5, ...)` to `task.delay(Constants.RESULTS_DISPLAY_SECONDS or 8, ...)`.
- `src/client/RoundUIClient.client.lua`: `showRoundResults` now auto-hides after `Constants.RESULTS_DISPLAY_SECONDS` seconds so both timers share the same source.

**Task 9 — warnOnce tables never reset across rounds**
Added `warned = {}` at the top of each service's `ResetForRound` (or `StopRound` where there is no `ResetForRound`):
- `ObjectiveService`, `IdolService`, `CageService`, `GuardianAbilityService`, `RoundScoreService`, `SkillCheckService`.

**Task 10 — Dead no-op map functions in GameManager**
`src/server/GameManager.server.lua`: Removed `ensureBasicMap`, `ensureSpawnPoints`, `ensureVaultPart`, `createSpawnPart` (all no-ops / unsupported), and the stale comment block that referenced them.

---

### How to test (Studio, 2-player local server)

**Task 1:** Play 3 rounds back to back. Confirm player count and countdown appear on every round, not just round 1. Confirm intermission timer shows between rounds.

**Task 2:** Catch thief once → confirm rescuable cage UI; rescue them; catch again → confirm "ELIMINATED — OUT FOR THIS ROUND" overlay (not "YOU WERE CAUGHT"), no frozen mystery body, eliminated player is non-collidable (walk through them), guardian E-catch prompt does not appear on them, round ends correctly when all thieves are out. Reset eliminated player character mid-round → confirm they stay correctly in eliminated state.

**Task 3:** In a non-Studio server, confirm no "[RuntimeAudit]" spam in output. In Studio, confirm audit runs every 5 s.

**Task 4:** Cage a player → reset their character → confirm "You are caged. Wait for rescue." directive appears from snapshot, not blank.

**Task 5:** In Studio: `/debug forcestart` skips waiting/countdown and starts round; `/debug skiplobby` shortens countdown to ~2 s. In a private server as owner: same commands work. In a private server as non-owner: commands are inert.

**Task 6:** Start a round and confirm only one role-reveal overlay appears (from RoleAnnouncementClient), not two overlapping panels.

**Task 7:** Reason about it: after 50 rounds the table length is capped at 50; `/debug roundlog` still shows last round correctly.

**Task 8:** End a round → confirm results screen shows fully (8 s) → main menu returns cleanly afterward with no overlap and no premature reshow at 4.5 s.

**Task 9:** Watch console across 3 rounds; confirm warnOnce messages that fired in round 1 can fire again in round 2.

**Task 10:** `rojo build` succeeds; no reference to `ensureBasicMap`, `ensureSpawnPoints`, `ensureVaultPart`, or `createSpawnPart` in any file.
