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
