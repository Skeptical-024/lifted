-- Legacy module kept for compatibility with older requires.
-- ObjectiveService is the only active objective/vault authority.

local BrazierManager = {}

function BrazierManager.InitRound(_rolesByPlayer)
end

function BrazierManager.TryLightBrazier(_player, _name, _rolesByPlayer, _roundActive)
	return false
end

function BrazierManager.TryExtinguishBrazier(_player, _name, _rolesByPlayer, _roundActive)
	return false
end

function BrazierManager.IsUnlocked()
	return false
end

function BrazierManager.GetLitCount()
	return 0
end

function BrazierManager.Reset()
end

return BrazierManager
