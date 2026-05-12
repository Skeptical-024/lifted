# AI_BACKLOG.md

## Purpose

This file is the task queue for LIFTED AI development.

Future AI sessions should read this file after AI_DEV_CONTEXT.md.

Do not skip ahead.
Do not add features outside the active milestone.
Do not mark a task done without validation.

---

## Current Milestone

## Round Lifecycle Stability v1 + Playtest Clarity Pass v1

Status: ACTIVE

Goal:
Make the current core loop reliable across repeated rounds and readable enough to playtest.

The game must survive:

Lobby
→ round start
→ roles assigned
→ objectives
→ vault
→ idol pickup
→ extraction/cage win
→ results
→ cleanup
→ next round

without stale state leaks.

---

## Active Task 1: Server Round Lifecycle Stability

Status: ACTIVE

### Goal

Make round start, round end, reset, and repeated rounds stable.

### Required checks

GameManager:
- round start cleanup exists
- round end cleanup exists
- RoundEnded fires once
- currentRoundId/roundActive/ending guard prevents duplicate end
- services reset in correct order
- services stop in correct order
- player tracking tables do not drift
- alive thief count comes from PlayerStateService

ObjectiveService:
- resets progress
- resets completed state
- resets vaultOpen
- clears active interactions
- disconnects or guards heartbeat
- VaultOpened fires once per round
- stale heartbeat cannot mutate next round

IdolService:
- clears idolCarrier
- clears HasIdol
- clears IdolCarrierSpeed
- cancels extraction
- disconnects or guards extraction heartbeat
- restores movement
- idol locked/unavailable until vault opens
- carrier leaving is safe
- extraction cannot complete after reset

CageService:
- clears caged players
- clears rescue records
- cancels rescues
- unfreezes caged players on round end/reset
- rescuer leaving is safe
- caged target leaving is safe
- rescue cannot complete after reset

GuardianAbilityService:
- clears slowed players
- clears reveal state
- restores movement
- delayed restore cannot corrupt later round

PlayerStateService:
- CountAliveThieves correct
- AreAllThievesOut correct
- CanInteractObjective blocks invalid states
- CanBeCaught blocks invalid targets
- UnregisterPlayer safe

### Done when

- rojo build passes
- repeated rounds do not leak server state
- no stale objective/vault/idol/extract/cage state appears in next round
- manual Studio test confirms thief win → next round clean
- manual Studio test confirms guardian win → next round clean

---

## Active Task 2: Player Leave Edge Cases

Status: ACTIVE

### Goal

No player leaving case should stall or corrupt the round.

### Cases to handle

Alive thief leaves:
- remove from active state
- update alive thief count
- guardian win if no alive thieves remain

Idol carrier leaves:
- cancel extraction
- drop/clear idol safely
- clear HasIdol
- clear IdolCarrierSpeed
- update UI remotes safely

Extracting player leaves:
- cancel extraction
- prevent ExtractCompleted after leave

Caged player leaves:
- clear cage record
- clear rescue records targeting them
- update win condition

Rescuer leaves:
- cancel rescue
- target remains caged unless another rescue succeeds or round ends

Guardian leaves:
- no nil errors
- no permanent stuck round
- acceptable for now: safely end/cancel round or continue safely if current code supports it
- do not build guardian reassignment yet

### Done when

- no PlayerRemoving script errors
- no stuck round from any listed case
- state cleanup is visible in logs or tested in Studio

---

## Active Task 3: Playtest Clarity Pass

Status: PENDING UNTIL SERVER LIFECYCLE IS PATCHED OR VERIFIED

### Goal

Make the current loop readable enough to playtest.

This is not polish.
This is clarity.

### Allowed work

RoundUIClient:
- clear stale result screen on RoundStarted
- clear stale objective state on RoundStarted
- clear stale vault/idol/extract/cage text on RoundStarted
- prevent Unknown carrier text
- show clear alerts for objective/vault/idol/extract/cage states

ThiefClient:
- clear local active flags on RoundStarted/RoundEnded
- ensure E release cancels correct active action
- keep E priority:
  1. extract
  2. rescue
  3. idol pickup
  4. objective

BrazierClient:
- visual/proximity only
- no gameplay remotes
- remove dead RequestObjectiveStart/Stop references

UIStateController:
- reset stale state on RoundStarted
- clear active interaction state on RoundEnded
- store objective progress consistently if used

### Suggested copy

Thief start:
"Break 3 seals to open the vault."

Guardian start:
"Stop the thieves before they extract the idol."

Objective progress:
"Breaking seal..."

Objective complete:
"Seal broken."

Vault open:
"Vault open. Steal the idol."

Idol picked up by self:
"You have the idol. Get to extraction."

Idol picked up by teammate:
"{Name} has the idol. Protect them."

Idol picked up for guardian:
"{Name} has the idol. Hunt them."

Idol dropped:
"Idol dropped. Recover it."

Extraction started:
"Extracting..."

Extraction canceled:
"Extraction canceled."

Extraction complete:
"Extraction complete."

Thief win:
"Thieves escaped with the idol."

Guardian win:
"Guardian stopped the heist."

Caged:
"You are caged. Wait for rescue."

Rescue prompt:
"Hold E to rescue."

Rescued:
"Rescued. Get back in the heist."

### Done when

- players understand what to do in the current loop
- no old UI leaks into next round
- no large UI redesign was done

---

## Next Task 4: Map Gameplay Pass

Status: PENDING

### Goal

Make the map support the loop.

Do not start until lifecycle is stable.

### Areas to inspect

- objective spacing
- extract placement
- cage placement
- cage entrances
- line-of-sight breaks
- chase routes
- dead zones
- guardian pressure routes
- thief escape routes
- vault-to-extract timing
- objective-to-objective timing

### Known design direction

- Keep central vault.
- Keep 3 objective rooms.
- Keep side cage/prison.
- Keep 2 extraction points.
- Move one extraction away from right side if still too campable.
- Cage needs at least 2 entrances.
- Objective rooms need at least 2 exits.
- Upper-left area should become a useful route/shortcut/balcony, not dead space.
- Map must not become a maze.

### Done when

- routes support chase and rescue
- guardian cannot camp all key objectives from one spot
- extracts are not both camped from one side
- thieves have meaningful but readable route choices

---

## Next Task 5: Balance Pass

Status: PENDING

### Goal

Tune the loop after it works.

### Tune only after repeated rounds are stable

Variables:
- objective solo time
- multi-player objective speed
- guardian walk speed
- thief walk speed
- idol carrier slow
- extraction time
- rescue time
- catch distance
- sprint cooldown/duration if present
- round timer

### Done when

- rounds usually last 4–6 minutes
- max round length around 8 minutes
- guardian feels threatening
- thieves have comeback options
- idol phase feels tense

---

## Next Task 6: UI Clarity Pass

Status: PENDING

### Goal

Improve HUD clarity after core loop is stable.

Allowed later:
- better role directive layout
- better seal progress display
- clearer vault status
- clearer idol carrier status
- clearer extraction progress
- clearer cage/rescue state
- cleaner result screen

Not yet:
- full redesign
- animations
- expensive polish

---

## Next Task 7: Polish Pass

Status: PENDING

### Goal

Make the working game feel better.

Only after:
- lifecycle stable
- map gameplay pass done
- balance pass done
- UI clarity pass done

Possible polish:
- sound cues
- particles
- lighting tweaks
- animations
- feedback effects
- icon/thumbnail prep

---

## Future Task 8: Progression / Retention

Status: DO NOT START

Do not build until the game is fun.

Possible later systems:
- XP
- levels
- missions
- cosmetics
- role preference
- daily rewards
- currency
- monetization

Not now.

---

## Rules for AI Sessions

Every AI session must:

1. Read AI_DEV_CONTEXT.md.
2. Read AI_BACKLOG.md.
3. Read AI_VALIDATION.md.
4. Work only on the active task unless user explicitly says otherwise.
5. Inspect files before editing.
6. Patch the smallest confirmed issue.
7. Run validation.
8. Report exactly what changed.
9. Be honest about untested runtime behavior.

Do not skip from lifecycle stability to polish.

---

## Task Status Update Rules

When a task is complete, update this file.

Use status values:
- ACTIVE
- PENDING
- BLOCKED
- DONE
- DO NOT START

Do not mark DONE unless:
- build passes
- required searches pass
- manual Studio test is either passed or clearly listed as still required
- remaining risks are documented
