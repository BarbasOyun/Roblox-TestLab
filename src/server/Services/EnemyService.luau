local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages._Index["sleitnick_signal@1.5.0"].signal)

local enemyParent = workspace.WeaponHit

local PlayerService = nil
local CombatService = nil

-- ENEMY AUTHORING DATA
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

local enemiesHp = {}
local enemiesOnDeath = {}

local EnemyService = Knit.CreateService({
	Name = "EnemyService",
	-- Client = {},
})

-- Take an instance and associate it stats
function EnemyService:CreateEnemy(humanoid, enemyType)
	humanoid.Parent.Parent = enemyParent

	enemiesHp[humanoid] = enemyType.Hp
	enemiesOnDeath[humanoid] = Signal.new()
end

function EnemyService:DamageEnemy(userId, humanoid, damage)
	if not enemiesHp[humanoid] then
		return
	end

	enemiesHp[humanoid] -= damage

	local hp = enemiesHp[humanoid]

	-- print(" Dealt " .. damage .. " damage to " .. humanoid.Parent.Name .. " New HP : " .. hp)

	if hp <= 0 then
		local overKillDamage = math.abs(hp)
		self:KillEnemy(userId, humanoid, overKillDamage)
	end
end

function EnemyService:KillEnemy(userId, humanoid, overKillDamage)
	-- TODO : Check if userId is nil -> attribute the kill to nearest Player
	enemiesOnDeath[humanoid]:Fire(userId)

	enemiesHp[humanoid] = nil
	enemiesOnDeath[humanoid] = nil
end

-- TODO : Move
local function dismember(character)
	print("Dismember : " .. character.Name)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			print("Delete Motor6D")
			descendant:Destroy()
		end
	end
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
		CombatService:SpawnAutomaticItem(CombatService.automaticItems.smallXpOrb, dummy:GetPivot().Position)
		-- CombatService.SpawnAutomaticItem(CombatService.automaticItems.smallXpOrb, dummy.PrimaryPart.Position)
		-- dismember(dummy)
		dummy.Torso.Snap:Destroy()
		PlayerService:IncrementScore(userId, 1)
		task.wait(1)
		-- Respawn
		self:setupDummy(clone)
		dummy:Destroy()
	end

	enemiesOnDeath[humanoid]:Connect(onDeath)
end

local function SetupAllDummies()
	-- Setup Existing Dummies
	for _, dummy in pairs(CollectionService:GetTagged("Dummy")) do
		EnemyService:setupDummy(dummy)
	end

	-- Setup New Dummies
	CollectionService:GetInstanceAddedSignal("Dummy"):Connect(function(dummy)
		EnemyService:setupDummy(dummy)
	end)
end

function EnemyService:KnitInit()
	PlayerService = Knit.GetService("PlayerService")
	CombatService = Knit.GetService("CombatService")
end

function EnemyService:KnitStart()
	SetupAllDummies()
end

return EnemyService
