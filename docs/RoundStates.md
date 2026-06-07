# Round State Machine — LIFTED

## State Flow

```
Lobby
  └─► Countdown          (min players reached)
        └─► Cleanup       (countdown elapsed or force-start)
              └─► AssigningRoles
                    └─► Starting
                          └─► Active          ←─── main gameplay
                                ├─► Ending    (idol extracted / all thieves caught or eliminated / time up)
                                └─► Ending
                                      └─► Results
                                            └─► Intermission
                                                  └─► Lobby
```

## State Descriptions

| State | Who sets it | Condition |
|---|---|---|
| `Lobby` | GameManager loop | Waiting for enough eligible players |
| `Countdown` | GameManager loop | Min players met; countdown to round start |
| `Cleanup` | GameManager loop | Post-countdown; previous-round cleanup (respawn, reset services) |
| `AssigningRoles` | GameManager loop | Role assignment in progress |
| `Starting` | GameManager loop | Map reset, teleports, role announce |
| `Active` | GameManager loop | Round is live |
| `Ending` | `requestEndRound()` | Win condition triggered (see below) |
| `Results` | GameManager loop | Results payload fired; results screen shown |
| `Intermission` | GameManager loop | Brief pause before next Lobby |

## Win Conditions (triggers `Ending`)

| Winner | Trigger |
|---|---|
| `"Thieves"` | IdolService: a thief holds the extraction point long enough |
| `"Guardian"` | GameManager: all eligible thieves are eliminated or caged and cannot be rescued |
| `"Time"` | GameManager: `roundEndsAt` passes while round is Active |

## Service Ownership

| Concern | Owner |
|---|---|
| Round state machine | `GameManager.server.lua` |
| Player role / state records | `PlayerStateService` (authoritative); attributes are display-only mirrors |
| Objective / seal progress | `ObjectiveService` |
| Idol pickup, extract, carrier ping | `IdolService` |
| Cage, rescue progression | `CageService` |
| Guardian abilities (Rush/Reveal/Roar) | `GuardianAbilityService` |
| Skill check prompts | `SkillCheckService` |
| Round score / results payload | `RoundScoreService` |
| Late-load state recovery | `SnapshotService` |
| AFK detection | `ActivityService` |
| Gameplay QA checks | `RuntimeAuditService` |

## Guards

`endingRound`, `forcedWinner`, `resultsFired` in `GameManager` are idempotency guards — do **not** modify them outside `requestEndRound()` / `GameManager`'s own results-firing sequence. See `CLAUDE.md`.
