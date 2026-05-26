local CollectionService = game:GetService("CollectionService")
local dummyParent = workspace.WeaponHit

local function setupDummy(dummy)
	local humanoid = dummy:FindFirstChildOfClass("Humanoid")
	local clone = dummy:Clone()

	if not humanoid then
		warn("TargetDummy missing Humanoid:", dummy.Name)
		return
	end

	local anchor = script:GetAttribute("Anchor")

	if anchor and dummy:FindFirstChild("HumanoidRootPart") then
		dummy.HumanoidRootPart.Anchored = true
	end

	-- Dummy Take Damage
	-- humanoid.HealthChanged:Connect(function(health)
	-- 	print(dummy.Name .. " health: " .. health)
	-- end)

	-- Dummy Death
	humanoid.Died:Connect(function()
		-- print(dummy.Name .. " Died")
		-- Gears.SpawnXP(dummy:GetPivot().Position)
		task.wait(1)
		-- Respawn
		clone.Parent = dummyParent
		dummy:Destroy()
	end)
end

-- Setup Existing Dummies
for _, dummy in pairs(CollectionService:GetTagged("Dummy")) do
	setupDummy(dummy)
end

-- Setup New Dummies
CollectionService:GetInstanceAddedSignal("Dummy"):Connect(setupDummy)
