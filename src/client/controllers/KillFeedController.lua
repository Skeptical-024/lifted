-- KillFeedController: kill-feed container, item pool, and Add/Clear API.

local KillFeedController = {}

local sharedHud = nil

-- Private state
local killFeed = nil
local feedItems = {}

function KillFeedController.Init(sh)
	sharedHud = sh

	local COLORS = sh.COLORS
	local gui = sh.gui

	killFeed = Instance.new("Frame")
	killFeed.Size = UDim2.fromOffset(280, 160)
	killFeed.Position = UDim2.new(1, -296, 0, 16)
	killFeed.BackgroundTransparency = 1
	killFeed.Parent = gui
end

function KillFeedController.Add(text)
	local COLORS = sharedHud.COLORS
	local makePanel = sharedHud.makePanel
	local makeLabel = sharedHud.makeLabel
	local tweenIn = sharedHud.tweenIn

	local pill = makePanel(UDim2.fromOffset(280, 28), UDim2.fromOffset(20, #feedItems * 34), killFeed, 0.3)
	local msg = string.lower(text or "")
	local eventColor = COLORS.white
	if string.find(msg, "caught") then
		eventColor = COLORS.red
	elseif string.find(msg, "seal") or string.find(msg, "vault") then
		eventColor = COLORS.teal
	elseif string.find(msg, "idol") then
		eventColor = COLORS.gold
	end
	local lbl = makeLabel(text, Enum.Font.GothamBold, eventColor, pill)
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	pill.Position = UDim2.fromOffset(40, #feedItems * 34)
	tweenIn(pill, "Position", UDim2.fromOffset(0, #feedItems * 34), 0.2)
	table.insert(feedItems, 1, pill)
	for i, item in ipairs(feedItems) do
		tweenIn(item, "Position", UDim2.fromOffset(0, (i - 1) * 34), 0.15)
	end
	while #feedItems > 4 do
		local old = table.remove(feedItems)
		old:Destroy()
	end
	task.delay(5, function()
		if pill.Parent then
			tweenIn(pill, "BackgroundTransparency", 1, 0.2)
			task.delay(0.22, function()
				for i, item in ipairs(feedItems) do
					if item == pill then
						table.remove(feedItems, i)
						break
					end
				end
				pill:Destroy()
			end)
		end
	end)
end

function KillFeedController.Clear()
	for _, item in ipairs(feedItems) do
		if item.Parent then item:Destroy() end
	end
	feedItems = {}
end

function KillFeedController.Reset()
	KillFeedController.Clear()
end

return KillFeedController
