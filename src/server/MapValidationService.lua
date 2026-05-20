local CollectionService = game:GetService("CollectionService")

local MapValidationService = {}

local lastReport = nil

local REQUIRED_IDS = {
	FlameSeal = true,
	MoonLock = true,
	StoneSigil = true,
}

local function taggedParts(tag)
	local out = {}
	for _, inst in ipairs(CollectionService:GetTagged(tag)) do
		if inst:IsA("BasePart") and inst:IsDescendantOf(workspace) then
			table.insert(out, inst)
		end
	end
	return out
end

function MapValidationService.ValidateCurrentMap()
	local counts = {
		ObjectiveStation = #taggedParts("ObjectiveStation"),
		Vault = #taggedParts("Vault"),
		Idol = #taggedParts("Idol"),
		ExtractPoint = #taggedParts("ExtractPoint"),
		ThiefSpawn = #taggedParts("ThiefSpawn"),
		GuardianSpawn = #taggedParts("GuardianSpawn"),
		CageSpawn = #taggedParts("CageSpawn"),
		CageRescuePoint = #taggedParts("CageRescuePoint"),
	}
	local errors = {}
	local warnings = {}

	if counts.ObjectiveStation < 3 then table.insert(errors, "Missing ObjectiveStation tags (need >=3)") end
	if counts.Vault < 1 then table.insert(errors, "Missing Vault tag") end
	if counts.Idol < 1 then table.insert(errors, "Missing Idol tag") end
	if counts.ExtractPoint < 1 then table.insert(errors, "Missing ExtractPoint tag") end
	if counts.ExtractPoint < 2 then table.insert(warnings, "Only one ExtractPoint found; two preferred") end
	if counts.ThiefSpawn < 4 then table.insert(errors, "Missing ThiefSpawn tags (need >=4)") end
	if counts.GuardianSpawn < 1 then table.insert(errors, "Missing GuardianSpawn tag") end
	if counts.CageSpawn < 1 then table.insert(errors, "Missing CageSpawn tag") end
	if counts.CageRescuePoint < 1 then table.insert(errors, "Missing CageRescuePoint tag") end

	local foundIds = {}
	for _, part in ipairs(taggedParts("ObjectiveStation")) do
		local id = part:GetAttribute("ObjectiveId")
		local name = part:GetAttribute("ObjectiveName")
		if type(id) ~= "string" or id == "" then
			table.insert(errors, "ObjectiveStation missing ObjectiveId: " .. part:GetFullName())
		else
			foundIds[id] = true
		end
		if type(name) ~= "string" or name == "" then
			table.insert(warnings, "ObjectiveStation missing ObjectiveName: " .. part:GetFullName())
		end
	end
	for id in pairs(REQUIRED_IDS) do
		if not foundIds[id] then
			table.insert(errors, "Required ObjectiveId missing: " .. id)
		end
	end

	for _, part in ipairs(taggedParts("Idol")) do
		if part:GetAttribute("IdolId") == nil and part:GetAttribute("IdolName") == nil then
			table.insert(warnings, "Idol has no IdolId/IdolName attribute: " .. part:GetFullName())
		end
	end

	for _, part in ipairs(taggedParts("ExtractPoint")) do
		if part:GetAttribute("ExtractId") == nil then
			table.insert(warnings, "ExtractPoint missing ExtractId: " .. part:GetFullName())
		end
		if part:GetAttribute("ExtractName") == nil then
			table.insert(warnings, "ExtractPoint missing ExtractName: " .. part:GetFullName())
		end
	end

	lastReport = {
		ok = #errors == 0,
		errors = errors,
		warnings = warnings,
		counts = counts,
	}
	return lastReport
end

function MapValidationService.GetLastReport()
	return lastReport
end

function MapValidationService.PrintReport()
	local report = lastReport or MapValidationService.ValidateCurrentMap()
	if report.ok then
		print("[MapValidation] PASS")
	else
		warn("[MapValidation] FAIL")
	end
	print(string.format("[MapValidation] Counts: Objective=%d Vault=%d Idol=%d Extract=%d ThiefSpawn=%d GuardianSpawn=%d CageSpawn=%d CageRescue=%d",
		report.counts.ObjectiveStation,
		report.counts.Vault,
		report.counts.Idol,
		report.counts.ExtractPoint,
		report.counts.ThiefSpawn,
		report.counts.GuardianSpawn,
		report.counts.CageSpawn,
		report.counts.CageRescuePoint
	))
	for _, e in ipairs(report.errors) do
		warn("[MapValidation][ERROR] " .. e)
	end
	for _, w in ipairs(report.warnings) do
		warn("[MapValidation][WARN] " .. w)
	end
	return report
end

return MapValidationService
