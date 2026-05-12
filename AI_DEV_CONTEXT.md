# AI_DEV_CONTEXT.md

## Purpose

This file is the standing operating manual for AI coding sessions on LIFTED.

Every AI session must read this before editing code.

This file is meant to reduce prompt size, prevent context drift, and stop AI from reviving old bad ideas.

The repo is the source of truth. If this file and the repo conflict, inspect the repo and report the conflict before editing.

Do not rely on old chat memory, old screenshots, old Claude/Codex summaries, or assumptions unless the current repo proves them.

---

## Project Identity

Project name: LIFTED

Platform: Roblox

Engine: Roblox Studio

Language: Luau

Project type: asymmetric heist/horror-lite prototype

Current stage: pre-alpha / core loop hardening

Main goal right now: make repeated rounds playable, readable, and stable.

The game is not launch-ready.

The current priority is not polish. The current priority is a reliable core loop.

---

## Game Concept

LIFTED is an asymmetric Roblox heist game.

Core fantasy:
- Thieves enter a cursed temple.
- They break three cursed seals.
- Breaking all three seals opens the vault.
- A thief steals the idol.
- The idol carrier must reach extraction.
- One guardian hunts the thieves and tries to stop the escape.

Primary inspiration:
- Flee the Facility
- Dead by Daylight structure, but Roblox-friendly and simpler
- Temple heist fantasy

Season/theme direction:
- Season 1: cursed temple
- ancient stone
- gold vault/idol accents
- red/purple cursed danger accents
- blue-white moonlight contrast
- warm torchlight

---

## Current Core Loop Target

The target full loop is:

1. Lobby / intermission
2. Round starts
3. Roles assigned
4. Thieves break 3 seals
5. Vault opens
6. Idol becomes available
7. Thief picks up idol
8. Idol carrier is slowed/revealed/pressured
9. Carrier reaches extraction
10. Thieves win only when idol carrier extracts
11. Guardian catches/cages thieves
12. Guardian wins if no alive thieves remain or timer expires
13. Results show
14. Full cleanup
15. Next round starts clean

Important:
- Thieves should not win on vault open.
- Thieves should not win on idol pickup.
- Thieves win only on successful extraction.
- Guardian win should not stall if all thieves are caught/caged/out.
- Caught/caged/eliminated/out-of-round thieves must not interact.

---

## Current Development Priority

Current milestone:

Round Lifecycle Stability v1 + Playtest Clarity Pass v1

Goal:
Make repeated rounds reliable and readable enough to playtest.

The game must survive:

Lobby
→ round start
→ objectives
→ vault
→ idol
→ extraction/cage win
→ results
→ full cleanup
→ next round

without stale state leaks.

Highest-risk areas:
- GameManager cleanup order
- PlayerRemoving handling
- idol carrier cleanup
- extraction cancellation
- cage/rescue cancellation
- movement speed restoration
- old Heartbeat/task.delay/task.spawn logic mutating later rounds
- UI state carrying into next round

---

## Architecture Rules

Hard rules:

- Server owns gameplay truth.
- Client owns UI and input only.
- Client can request actions.
- Client cannot decide action success.
- Server validates every gameplay action.
- Server validates role, state, round, distance, and target eligibility.
- RemoteEvents are flat under ReplicatedStorage.
- Do not create ReplicatedStorage.Remotes.
- Do not move remotes into a Remotes folder.
- Do not add DataStores until core loop is stable.
- Do not add progression until core loop is stable.
- Do not add monetization until the game is fun.
- Prefer small patches.
- Preserve working systems.
- Inspect files before editing.
- Never guess file paths.
- Never invent services that the repo does not contain.

---

## Server Authority Rules

The server must own:

- round state
- player role
- player active/caught/caged/eliminated/escaped state
- objective progress
- objective completion
- vault-open state
- idol availability
- idol carrier
- extraction progress/completion
- cage/caught/rescue state
- guardian catch success
- win/loss state

The client must not be able to:

- set objective progress
- mark an objective complete
- open the vault
- declare idol pickup success
- declare extraction success
- set cage state
- change role
- change win state
- bypass caught/caged restrictions

---

## Client Responsibilities

Clients may handle:

- local input
- prompts
- HUD rendering
- local visual feedback
- local alert text
- camera/UI polish
- sending server requests

Clients must not own:

- objective completion
- vault opening
- idol ownership
- extraction completion
- cage release success
- guardian catch success
- round win/loss

---

## RemoteEvent Rule

RemoteEvents are expected to be flat under ReplicatedStorage.

Correct pattern:
- ReplicatedStorage.RequestObjectiveStart
- ReplicatedStorage.RequestObjectiveStop
- ReplicatedStorage.VaultOpened

Forbidden unless the repo has explicitly migrated:
- ReplicatedStorage.Remotes.RequestObjectiveStart
- ReplicatedStorage.Remotes.VaultOpened

Do not create ReplicatedStorage.Remotes.

Validation should search for:

ReplicatedStorage.Remotes

Expected result:
zero matches.

---

## Known/Relevant Systems

Verify exact files in repo before editing.

Server files currently present in repo:
- src/server/GameManager.server.lua
- src/server/PlayerStateService.lua
- src/server/ObjectiveService.lua
- src/server/IdolService.lua
- src/server/CageService.lua
- src/server/GuardianController.lua
- src/server/GuardianAbilityService.lua
- src/server/BrazierManager.lua
- src/server/TestMapService.lua
- src/server/BuildTemple.server.lua
- src/server/RoleManager.lua
- src/server/ThiefController.lua

Client files currently present in repo:
- src/client/ThiefClient.client.lua
- src/client/GuardianClient.client.lua
- src/client/BrazierClient.client.lua
- src/client/RoundUIClient.client.lua
- src/client/LobbyClient.client.lua
- src/client/MainMenuClient.client.lua
- src/client/CaughtFeedbackClient.client.lua
- src/client/RoleAnnouncementClient.client.lua
- src/client/controllers/UIStateController.lua

Shared files currently present in repo:
- src/shared/Constants.lua
- src/shared/Types.lua

---

## Service Ownership

### GameManager

Owns:
- round orchestration
- intermission
- role assignment flow
- round start/end
- service reset calls
- PlayerRemoving cleanup coordination
- win/loss handling

Do not rewrite GameManager from scratch.

Patch only the specific lifecycle bug.

---

### PlayerStateService

Should be the server source of truth for player role/state.

Expected responsibilities:
- register players for round
- track role
- track state
- answer CanInteractObjective
- answer CanBeCaught
- count alive thieves
- detect all-thieves-out condition
- unregister players cleanly

Important states in repo:
- Lobby
- Alive
- Caught
- Caged
- Escaped
- Eliminated
- OutOfRound

Important roles in repo:
- Thief
- Guardian
- None

Current intended logic:
- CanInteractObjective should be true only for alive thieves.
- CountAliveThieves should count only role Thief + state Alive.
- AreAllThievesOut should return false if any thief is Alive.
- AreAllThievesOut should return true if at least one thief exists and zero thieves are Alive.

---

### ObjectiveService

Owns:
- 3-seal objective progress
- objective completion
- vault-open state
- objective interaction eligibility
- objective progress remotes
- VaultOpened firing

Important:
- Server owns progress.
- Client only requests start/stop.
- ObjectiveService should validate PlayerStateService.CanInteractObjective(player).
- ObjectiveService should validate distance.
- ObjectiveService should clear active interactions on reset/end.
- VaultOpened should fire once per round.
- Vault opening should not end the round.

Known recent fix:
- ObjectiveService uses Constants.OBJECTIVE_INTERACT_DISTANCE.

---

### IdolService

Owns:
- idol locked/available state
- idol pickup
- idol carrier
- carrier slow
- extraction start/cancel/progress/complete
- thief win on successful extraction

Important:
- Idol cannot be picked up before vault opens.
- Idol cannot be picked up by guardian.
- Idol cannot be picked up by caught/caged/eliminated/out-of-round thief.
- Extraction requires the player to be the idol carrier.
- Extraction must cancel if carrier leaves, gets caught, moves away, or round ends.
- Extraction completion should fire once.
- Cleanup must restore carrier movement and clear HasIdol / IdolCarrierSpeed.

---

### CageService

Owns:
- caught/caged state
- cage placement/freeze
- rescue start/cancel/progress/complete
- caged player release

Important:
- Rescue can only be performed by an alive thief.
- Guardian cannot rescue.
- Target must still be caged.
- Rescue must cancel if rescuer leaves, target leaves, rescuer moves away, rescuer gets caught/caged, or round ends.
- StopRound/reset must unfreeze players and clear records.

---

### GuardianController

Owns:
- guardian catch request/validation
- catch distance/line-of-sight if implemented
- integration with PlayerStateService and CageService

Important:
- Guardian catch must validate guardian role.
- Target must be catchable.
- Client cannot catch arbitrary players across the map.

---

### GuardianAbilityService

Owns:
- guardian ability effects such as rush, roar, reveal, and slow

Important:
- Ability effects must clear on round end.
- Speed/reveal effects must not leak into next round.
- delayed restores must not overwrite newer round speed state.

---

### BrazierManager

Legacy/prototype objective logic.

Current direction:
- Do not make BrazierManager the real objective source again.
- It may remain as visual compatibility if needed.
- Player-facing language should be seals, not braziers.
- Do not rename everything now unless explicitly tasked.

---

### TestMapService

Development/test map support.

Current direction:
- Useful for gameplay testing.
- Do not art-pass it.
- Do not break it.
- Do not rely on BuildTemple if TestMapService is currently active.

---

## Stable Systems: Do Not Rewrite

Do not rewrite unless runtime proves a direct blocking bug:

- main menu
- lobby UI
- role assignment
- basic guardian catch path
- test map generation
- existing round loop structure
- ObjectiveService architecture
- IdolService architecture
- CageService architecture

---

## Do-Not-Touch Areas Unless Directly Relevant

Avoid editing:
- src/client/MainMenuClient.client.lua
- src/client/LobbyClient.client.lua
- src/server/RoleManager.lua
- src/server/BrazierManager.lua
- src/server/TestMapService.lua
- map art/build scripts

Exceptions:
Only edit these if inspection proves they directly block the current milestone.

---

## Current Known Recent Fixes

Verify in repo before relying on these:

- ObjectiveService constant mismatch fixed.
- BrazierClient no longer fires RequestObjectiveStart / RequestObjectiveStop.
- ThiefClient owns objective input.
- ThiefClient E priority should be:
  1. extract with idol
  2. rescue caged teammate
  3. idol pickup
  4. objective fallback
- RoundUIClient should not call setIdolCarrierUI(nil, nil).
- UIStateController should reset stale state on RoundStarted.
- GameManager should use PlayerStateService.CountAliveThieves().
- PlayerStateService.AreAllThievesOut should treat zero alive thieves as guardian win.
- Rojo build should pass.

---

## Current Likely Weaknesses

These need continued testing:

- repeated round reset
- PlayerRemoving edge cases
- idol carrier leaving
- extracting carrier leaving
- caged player leaving
- rescuer leaving mid-rescue
- guardian leaving mid-round
- extraction heartbeat stale completion
- rescue heartbeat stale completion
- objective heartbeat stale vault open
- movement speed restore after slow/cage/round end
- UI stale state after next round starts
- RoundEnded firing more than once
- results overlay lingering into next round

---

## Development Style

Use this approach:

1. Inspect relevant files.
2. Confirm current behavior.
3. Patch the smallest confirmed issue.
4. Preserve existing APIs where possible.
5. Validate with search/build.
6. Report exactly what changed.
7. Report remaining risks honestly.

Do not:
- make giant speculative rewrites
- add systems because they sound useful
- add features outside the active milestone
- hide uncertainty
- claim runtime success without Studio testing

---

## Required AI Report Format

Every AI coding pass should end with:

1. Files inspected
2. Files changed
3. What changed and why
4. Validation results
5. Build result
6. Manual Studio tests still required
7. Remaining risks

For large lifecycle passes, also include:

8. Player leave cases handled
9. Async/Heartbeat stale-state checks
10. Server authority/security checks

---

## Current Product Reality

The game is incomplete.

That is expected.

It currently needs:
- reliability
- readable objectives
- clear idol/extract phase
- stable cage/rescue flow
- repeated-round cleanup
- playtest clarity
- map gameplay pass
- balance pass
- polish later

Do not solve incompleteness by adding random features.

Solve it by making the existing loop reliable, readable, and tense.

---

## Feature Creep Warnings

Reject these until core loop is stable:

- cosmetics
- XP
- currency
- shop
- daily rewards
- new maps
- new roles
- new abilities
- advanced tutorial
- full UI redesign
- monetization
- lore expansion
- cutscenes
- complex animations
- DataStores

---

## Next Recommended Work

Use AI_BACKLOG.md as the task source.

The current priority should remain:

1. Round Lifecycle Stability v1
2. Player Leave Edge Cases
3. Playtest Clarity Pass
4. Map Gameplay Pass
5. Balance Pass
6. UI Clarity Pass
7. Polish Pass
8. Progression/Retention later

Do not skip ahead without explicit user approval.

---

## Repo Reality Notes (Current)

- `default.project.json` project name is `Lifted`.
- Current `Constants.ROUND_MIN_PLAYERS` is `2` for playtesting, even if design intent is larger teams later.
- Keep docs honest to current repo behavior and mark future design separately.
