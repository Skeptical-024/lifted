local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local DebugCommandService = {}

local enabled = false
local handlers = {}

local function canUse()
	return enabled
end

function DebugCommandService.Init(deps)
	enabled = (RunService:IsStudio() or deps.Constants.DEBUG_COMMANDS_ENABLED == true)
	if not enabled then
		return
	end

	handlers.completeSeals = function(player)
		deps.ObjectiveService.DebugCompleteAll()
	end

	handlers.openVault = function()
		deps.ObjectiveService.DebugOpenVault()
		deps.IdolService.OnVaultOpened()
	end

	handlers.giveIdol = function(player)
		deps.ObjectiveService.DebugOpenVault()
		deps.IdolService.OnVaultOpened()
		deps.IdolService.DebugForceGive(player)
	end

	handlers.cageMe = function(player)
		local caught, state = deps.PlayerStateService.MarkCaught(player)
		if caught then
			deps.CageService.CagePlayer(player)
		end
	end

	handlers.rescueAll = function()
		local snap = deps.CageService.GetCagedPlayersSnapshot()
		for uid, _ in pairs(snap) do
			for _, p in ipairs(Players:GetPlayers()) do
				if p.UserId == uid then
					deps.CageService.ReleasePlayer(p, "debug")
				end
			end
		end
	end

	handlers.endThieves = function()
		deps.SetForcedRoundResult("Thieves", "Debug command")
	end

	handlers.endGuardian = function()
		deps.SetForcedRoundResult("Guardian", "Debug command")
	end

	handlers.validateMap = function()
		deps.MapValidationService.PrintReport()
	end

	handlers.state = function(player)
		local round = deps.GetRoundSnapshot and deps.GetRoundSnapshot() or {}
		print(string.format(
			"[DebugState] player=%s roundState=%s roundId=%s timeRemaining=%s aliveThieves=%s",
			player.Name,
			tostring(round.roundState),
			tostring(round.roundId),
			tostring(round.timeRemaining),
			tostring(deps.PlayerStateService.CountAliveThieves())
		))
	end

	-- /debug snapshot
	handlers.snapshot = function(player)
		if deps.SnapshotService then
			deps.SnapshotService.PrintSnapshot(player)
			deps.SnapshotService.SendSnapshot(player)
		end
	end

	-- /debug audit
	handlers.audit = function()
		if deps.RuntimeAuditService then
			deps.RuntimeAuditService.RunOnce()
		end
	end

	handlers.checklist = function()
		print("[DebugChecklist] 1 lobby countdown")
		print("[DebugChecklist] 2 role assignment")
		print("[DebugChecklist] 3 thief objective")
		print("[DebugChecklist] 4 vault open")
		print("[DebugChecklist] 5 idol pickup")
		print("[DebugChecklist] 6 guardian reveal/rush/roar")
		print("[DebugChecklist] 7 catch/cage")
		print("[DebugChecklist] 8 rescue")
		print("[DebugChecklist] 9 extract win")
		print("[DebugChecklist] 10 guardian win")
		print("[DebugChecklist] 11 results")
		print("[DebugChecklist] 12 second round cleanup")
	end

	local normalized = {}
	for name, fn in pairs(handlers) do
		normalized[string.lower(name)] = fn
	end
	handlers = normalized

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if not canUse() then return end
			local cmd = string.match(string.lower(message), "^/debug%s+(%S+)")
			if not cmd then return end
			local fn = handlers[cmd]
			if fn then
				fn(player)
			end
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			if not canUse() then return end
			local cmd = string.match(string.lower(message), "^/debug%s+(%S+)")
			if not cmd then return end
			local fn = handlers[cmd]
			if fn then
				fn(player)
			end
		end)
	end
end

return DebugCommandService
