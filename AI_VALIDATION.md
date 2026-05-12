# AI_VALIDATION.md

## Purpose

This file defines required validation for LIFTED AI coding sessions.

Every AI patch must run the relevant checks before reporting success.

Build success does not prove gameplay works.
Manual Studio testing is still required.

---

## Always Required Checks

Run these after every patch.

### 1. Forbidden Remotes Folder

Search for:

```text
ReplicatedStorage.Remotes
WaitForChild("Remotes")
FindFirstChild("Remotes")
```

Expected:
- zero matches

### 2. Objective Start Ownership

Search for:

```text
RequestObjectiveStart:FireServer
RequestObjectiveStop:FireServer
```

Expected:
- objective interaction requests are only sent from the intended owner client path
- currently expected owner is `src/client/ThiefClient.client.lua`

### 3. BrazierClient Objective Remote References

Search in:
- `src/client/BrazierClient.client.lua`

Check for:

```text
RequestObjectiveStart
RequestObjectiveStop
```

Expected:
- zero references if BrazierClient is visual/proximity-only for objective prompts

### 4. Server Authority Invariants

Confirm in server files:
- Objective progress cannot be set by client payloads.
- Objective completion cannot be client-forced.
- Vault open cannot be client-forced.
- Idol extraction win cannot be client-forced.
- Cage state transitions cannot be client-forced.

### 5. Build

Run:

```bash
rojo build --output LiftedDev.rbxl
```

Expected:
- build succeeds

---

## Lifecycle-Focused Checks

Run these for any round-loop or gameplay-state changes.

### 1. Round Start Cleanup

Confirm:
- objective state reset
- vault state reset
- idol state reset
- extraction state reset
- cage state reset
- movement reset before role behavior

### 2. Round End Cleanup

Confirm:
- no new gameplay actions succeed after end starts
- extraction canceled
- rescue canceled
- services stop/cleanup called
- RoundEnded emitted once

### 3. PlayerRemoving Cleanup

Confirm cleanup for:
- alive thief leave
- idol carrier leave
- extracting carrier leave
- caged player leave
- rescuer leave
- guardian leave

### 4. Async Safety

Search touched files for:

```text
task.spawn
task.delay
RunService.Heartbeat
while
```

Confirm stale safety:
- heartbeat disconnected on stop/reset OR token guarded
- delayed restores cannot mutate later rounds incorrectly

---

## Quick Command Set

Run from repo root:

```bash
rg -n "ReplicatedStorage\\.Remotes|WaitForChild\\(\"Remotes\"\\)|FindFirstChild\\(\"Remotes\"\\)" src
rg -n "RequestObjectiveStart:FireServer|RequestObjectiveStop:FireServer" src/client
rg -n "RequestObjectiveStart|RequestObjectiveStop" src/client/BrazierClient.client.lua
rojo build --output LiftedDev.rbxl
```

---

## Manual Studio Tests (Required Before Claiming Runtime Success)

Core loop:
1. Round starts clean.
2. Thief can progress objectives.
3. Releasing interaction stops progress.
4. Three seals open vault exactly once.
5. Round does not end on vault open.
6. Idol pickup only works after vault opens.
7. Carrier extraction can start/cancel/restart/complete.
8. Thief win ends round once.
9. Guardian win ends round once.
10. Next round starts clean.

Cage/rescue:
11. Caught thief becomes caged/frozen.
12. Caged thief cannot interact.
13. Alive thief can rescue.
14. Rescue cancellation works when rescuer leaves/range breaks.
15. Rescued thief returns to valid interaction state.

Leave cases:
16. Alive thief leaves safely.
17. Idol carrier leaves safely.
18. Extracting carrier leaves safely.
19. Caged thief leaves safely.
20. Rescuer leaves safely.
21. Guardian leaves without nil errors/stalls.

---

## Reporting Template

Every AI pass should report:
1. Files inspected
2. Files changed
3. Validation command outputs (pass/fail)
4. Build result
5. Manual Studio tests still required
6. Remaining risks
