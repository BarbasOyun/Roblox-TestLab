local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages._Index["sleitnick_signal@1.5.0"].signal)

local enemyParent = workspace.WeaponHit

local PlayerService = nil

-- Move to file
local enemyData = {
	["Dummy"] = {
		EnemyType = "Dummy",
		Hp = 100,
	},
}

-- TODO : Implement ECS
-- Instead of using Rodux store
-- TODO : Use smart ID instead of Humanoid as key

local EnemyService = Knit.CreateService({
	Name = "EnemyService",
	enemiesHp = {},
	enemiesOnDeath = {},
	-- Client = {},
})

-- Take an instance and assosiate it stats
function EnemyService:CreateEnemy(humanoid, enemyType)
	humanoid.Parent.Parent = enemyParent

	self.enemiesHp[humanoid] = enemyType.Hp
	self.enemiesOnDeath[humanoid] = Signal.new()
end

function EnemyService:DamageEnemy(userId, humanoid, damage)
	local hp = self.enemiesHp[humanoid]
	hp -= damage

	-- print(player.name .. " Dealt " .. damage .. " damage to " .. humanoid.Parent.Name)
	print(" Dealt " .. damage .. " damage to " .. humanoid.Parent.Name)

	if hp <= 0 then
		local overKillDamage = math.abs(hp)
		self:KillEnemy(userId, humanoid, overKillDamage)
	end
end

function EnemyService:KillEnemy(userId, humanoid, overKillDamage)
	-- TODO : Check if userId is nil -> attribute the kill to nearest Player
	self.enemiesOnDeath[humanoid]:Fire(userId)

	self.enemiesHp[humanoid] = nil
	self.enemiesOnDeath[humanoid] = nil
end

function EnemyService:setupDummy(dummy)
	local humanoid = dummy:FindFirstChildOfClass("Humanoid")

	self:CreateEnemy(humanoid, enemyData["Dummy"])

	local anchor = script:GetAttribute("Anchor")
	if anchor and dummy:FindFirstChild("HumanoidRootPart") then
		dummy.HumanoidRootPart.Anchored = true
	end

	-- Take Damage
	-- humanoid.HealthChanged:Connect(function(health)
	-- 	print(dummy.Name .. " health: " .. health)
	-- end)

	-- Death
	local clone = dummy:Clone()

	local function onDeath(userId)
		-- print(dummy.Name .. " Died")
		-- Gears.SpawnXP(dummy:GetPivot().Position)
		PlayerService:IncrementScore(userId, 1)
		task.wait(1)
		-- Respawn
		self:setupDummy(clone)
		dummy:Destroy()
	end

	self.enemiesOnDeath[humanoid]:Connect(onDeath)
end

function EnemyService:SetupAllDummies()
	-- Setup Existing Dummies
	for _, dummy in pairs(CollectionService:GetTagged("Dummy")) do
		self:setupDummy(dummy)
	end

	-- Setup New Dummies
	CollectionService:GetInstanceAddedSignal("Dummy"):Connect(function(dummy)
		self:setupDummy(dummy)
	end)
end

function EnemyService:KnitInit()
	PlayerService = Knit.GetService("PlayerService")

	self:SetupAllDummies()
end

return EnemyService
