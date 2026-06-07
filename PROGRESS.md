# PROGRESS

## 2026-06-06 — RoundUIClient Split (11 Controllers)

Pure structural extraction. Behavior, visuals, and timing are identical to the monolith.
No gameplay, balance, remote-name, or payload changes.

### What changed

`src/client/RoundUIClient.client.lua` (2178 lines) split into 11 ModuleScripts under
`src/client/controllers/` plus a thin 170-line bootstrap.

| Controller | Owns |
|---|---|
| `SharedHud` | ScreenGui, helpers (makePanel/makeShadow/makeLabel/tweenIn), COLORS, shared state (getters/setters), proximity utils, readableFailure/showFailure |
| `KillFeedController` | Kill-feed Frame, item pool, Add/Clear/Reset |
| `ResultsController` | Round-results overlay, all result labels, Show/Hide/Reset, RoundResults remote |
| `GuardianHudController` | guardianStatusPanel, rushPanel, guardian state vars, all guardian ability remotes |
| `ThiefHudController` | thiefPanel (guardian sees it), crouchPanel, ThiefCountUpdate remote, IsCrouching attribute |
| `SkillCheckController` | skillCheckPanel, needle, SkillCheckStarted/Result/Expired remotes |
| `ObjectiveHudController` | sealPanel, objectiveInteractionPanel, all objective remotes |
| `IdolExtractController` | idolStatusPanel, extract progress bar, all idol/extract/vault remotes |
| `CageController` | PlayerCaged/Rescue/Cancel remotes → kill feed + directive updates |
| `CoreHudController` | timerPanel, roleBadge, phaseLabel, objectiveDirectiveLabel, interactionHintLabel, proximity dot, THE single persistent RunService.Heartbeat |
| `SnapshotController` | requestGameSnapshot, applyGameSnapshot, Role/RoundState attribute watchers, CharacterAdded, initial snapshot |

### Design notes

- ONE ScreenGui (`SharedHud.gui`); every controller parents frames into it.
- ONE persistent Heartbeat (in `CoreHudController`).
- Controllers communicate via plain function calls; no pub/sub.
- `connectOptional` lives in `SharedHud` and is shared by all controllers.
- Three dead remotes (`GuardianCatchPrompt`, `GuardianAlert`, `ObjectiveStarted`) moved as-is; `connectOptional` returns nil silently since they are not in ReplicatedStorage.
- `IdolExtractController` and `CageController` receive their `CoreHudController` reference via `SetCoreHud()` after CoreHud is initialized (bootstrap wires this explicitly).
- `ThiefHudController.thiefPanel` is shown for Guardian role (guardian sees thief-count icons). This matches the original `setRoleUI` logic exactly.
- `rushPanel` is guardian-owned (GuardianHudController). Original code: shown for Guardian, hidden for Thief.
- `SharedHud.injectKillFeed(fn)` called immediately after `KillFeedController.Init` so `showFailure` is live for all subsequent controllers.

### Build gate

All 12 files: `rojo build default.project.json --output /tmp/lifted_build.rbxl` exits 0.

### How to smoke-test

1. Studio 2-player local server.
2. Round starts — confirm timer, role badge, phase label, kill feed all appear identically to before.
3. Guardian role — confirm guardianStatusPanel + rushPanel visible, thief-icon panel visible.
4. Thief role — confirm sealPanel visible, crouch indicator appears on crouch.
5. Break seals → vault opens → idol spawns → pick up → extract → Thieves win → results overlay shows → auto-hides after ~8 s.
6. Guardian catches thief → cage UI directive ("You are caged") → rescue → "rescued!" feed event → directive updates.
7. Skill check shows on seal interaction and hides on result/expire.
8. Guardian Rush/Reveal/Roar cooldown line updates in real-time.
9. Proximity arrow appears when guardian is within 40 studs of a thief.
10. Snapshot recovery: join mid-round → GameSnapshot fires → role, vault, and idol state correctly reflected.
11. No red errors in output. `[RuntimeAudit] PASS` fires every 5 s.

## 2026-06-06 — Infrastructure & Cleanup Pass (Tasks 1–6)

Pure restructure. No gameplay, balance, visual, or remote-payload changes.

### Task 1 — Central RemoteEvent registry (`src/shared/Remotes.lua`)
Created `src/shared/Remotes.lua` under ReplicatedStorage (flat, no Remotes subfolder).
67 remote names as constants grouped by system. Three accessors:
- `Remotes.Server(name)` — idempotent create-or-get; replaces every per-file `getOrCreateRemote`.
- `Remotes.Client(name)` — `WaitForChild` up to 30 s; replaces all client `WaitForChild("X")` calls.
- `Remotes.Find(name)` — non-blocking `FindFirstChild`; replaces all client guard-checked `FindFirstChild("X")` calls.

Migrated all server services: `GameManager`, `ObjectiveService`, `IdolService`, `CageService`,
`GuardianAbilityService`, `SkillCheckService`, `PingService`, `RoundScoreService`,
`SnapshotService`, `ActivityService`. Removed all per-file `local function getOrCreateRemote`.

Migrated all client scripts: `RoundUIClient`, `ThiefClient`, `SoundClient`, `GuardianClient`,
`LobbyClient`, `PingClient`, `ActivityClient`, `CaughtFeedbackClient`, `RoleAnnouncementClient`,
`MainMenuClient`, `MinimapClient`. Also updated `connectOptional` in `RoundUIClient` to use
`Remotes.Find` internally.

Note: `PlayClicked` is a `BindableEvent`, not a RemoteEvent — intentionally excluded.

### Task 2 — Single `getRoundSnapshot()` in GameManager
Defined one `local function getRoundSnapshot()` before the service-init block.
Replaced three identical inline closures in `SnapshotService.Configure`, `RuntimeAuditService.Init`,
and `DebugCommandService.Init` with `GetRoundSnapshot = getRoundSnapshot`.
Returned table shape is unchanged.

### Task 3 — Delete dead Brazier code
Both `src/server/BrazierManager.lua` and `src/client/BrazierClient.client.lua` were already
deleted in a prior hardening pass. `TestMapService.lua` had no Brazier tags. No action needed.

### Task 4 — Remove dead roleIntro UI from RoundUIClient
Deleted:
- Lines 140–158: `roleIntroFrame` / `roleIntroShadow` / `roleIntroTitle` / `roleIntroSubtitle`
  / `roleIntroControls` panel creation.
- `local function showRoleIntro(_role) end` no-op stub.
- Two call sites (`showRoleIntro(role)` in `RoleAssigned` handler, and the
  `if not isRoundActive then showRoleIntro(...) end` block in attribute-changed handler).
`RoleAnnouncementClient` remains the sole role-reveal.

### Task 5 — Centralize client magic numbers
Added to `src/shared/Constants.lua`:
```
THIEF_GUARDIAN_PROXIMITY_RADIUS = 40
HUD_PROMPT_SCAN_INTERVAL        = 0.15
```
Updated `src/client/RoundUIClient.client.lua` to read these constants at the two call sites.
Values are identical to prior inline literals.

### Task 6 — Light typing pass and state-machine doc
- `src/shared/Types.lua`: Added `--!strict`, expanded with `PlayerState` value table,
  and three exported types: `RoundSnapshotPayload`, `PlayerScoreRow`, `ResultsPayload`.
- `src/shared/Remotes.lua`: Already had `--!strict`.
- `PlayerStateService`: Skipped `--!strict` — dynamic `records` table and untyped callbacks
  would produce new warnings with no behavioral benefit.
- Created `docs/RoundStates.md`: accurate state flow diagram, win conditions, and
  service ownership table.

### Build gate
All six tasks: `rojo build default.project.json --output /tmp/lifted_build.rbxl` exits 0.

### How to smoke-test
1. Start a 2-player Studio local server.
2. Confirm lobby countdown shows, roles assign, round goes active.
3. Break all 3 seals → vault opens → idol appears → thief picks up → extracts → Thieves win.
4. Guardian catches a thief → cage UI shows → thief rescued → round continues.
5. Let timer expire → Guardian/Time win → results screen shows → new lobby starts.
6. No red errors in output. `[RuntimeAudit] PASS` appears every 5 s in Studio.
7. Snapshot recovery: join mid-round (second client connects after round starts) → confirm
   `GameSnapshot` fires and client UI reflects correct role, vault, and idol state.

## 2026-06-06 — Hardening Pass 1 (scope fix)

**Task 1 scope bug fixed** (`src/client/LobbyClient.client.lua`): `local menuActive` was declared *after* `onPlayClicked`, so the `menuActive = true` assignment inside the function wrote to an implicit global instead of the local. `processLobbyPayload` reads the local, which stayed `false` after round 1, silently dropping all subsequent `LobbyUpdate` events. Fix: moved `local menuActive = true` to before `onPlayClicked` so it is captured as an upvalue. Removed the duplicate declaration that previously appeared after the function. Now exactly one `local menuActive` exists in the file.

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
