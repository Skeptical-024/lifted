#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

pass() { printf "[PASS] %s\n" "$1"; }
fail() { printf "[FAIL] %s\n" "$1"; exit 1; }
section() { printf "\n== %s ==\n" "$1"; }

section "Repo"
printf "Root: %s\n" "$ROOT_DIR"

section "Check: Forbidden Remotes folder patterns"
if rg -n "ReplicatedStorage\.Remotes|WaitForChild\(\"Remotes\"\)|FindFirstChild\(\"Remotes\"\)" src >/tmp/lifted_validate_remotes.txt; then
  cat /tmp/lifted_validate_remotes.txt
  fail "Found forbidden Remotes-folder patterns"
else
  pass "No forbidden Remotes-folder patterns"
fi

section "Check: Objective request FireServer ownership"
OBJ_MATCHES="$(rg -n "requestObjectiveStartRemote:FireServer|requestObjectiveStopRemote:FireServer|RequestObjectiveStart:FireServer|RequestObjectiveStop:FireServer" src/client || true)"
if [[ -z "$OBJ_MATCHES" ]]; then
  fail "No objective FireServer calls found in client (unexpected for current architecture)"
fi
printf "%s\n" "$OBJ_MATCHES"
if printf "%s\n" "$OBJ_MATCHES" | grep -v "src/client/ThiefClient.client.lua" >/tmp/lifted_validate_obj_owner.txt; then
  cat /tmp/lifted_validate_obj_owner.txt
  fail "Objective FireServer ownership leaked outside ThiefClient"
else
  pass "Objective FireServer ownership is ThiefClient-only"
fi

section "Check: BrazierClient no objective request references"
BRAZIER_REFS="$(rg -n "RequestObjectiveStart|RequestObjectiveStop" src/client/BrazierClient.client.lua || true)"
if [[ -n "$BRAZIER_REFS" ]]; then
  printf "%s\n" "$BRAZIER_REFS"
  fail "BrazierClient still references objective request remotes"
else
  pass "BrazierClient has no objective request remote references"
fi

section "Check: Objective constant key"
if rg -n "OBJECTIVE_INTERACTION_DISTANCE" src/server/ObjectiveService.lua >/tmp/lifted_validate_obj_const_bad.txt; then
  cat /tmp/lifted_validate_obj_const_bad.txt
  fail "ObjectiveService still references OBJECTIVE_INTERACTION_DISTANCE"
else
  pass "ObjectiveService does not reference OBJECTIVE_INTERACTION_DISTANCE"
fi
if rg -n "OBJECTIVE_INTERACT_DISTANCE" src/server/ObjectiveService.lua >/tmp/lifted_validate_obj_const_good.txt; then
  cat /tmp/lifted_validate_obj_const_good.txt
  pass "ObjectiveService references OBJECTIVE_INTERACT_DISTANCE"
else
  fail "ObjectiveService missing OBJECTIVE_INTERACT_DISTANCE reference"
fi

section "Build: rojo"
if command -v rojo >/dev/null 2>&1; then
  rojo build --output LiftedDev.rbxl
  pass "rojo build succeeded"
else
  printf "[WARN] rojo not found in PATH; build skipped\n"
fi

section "Done"
pass "Validation script completed"
