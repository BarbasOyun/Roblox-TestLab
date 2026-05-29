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
		Life = 100,
	},
}

-- TODO : Implement ECS
-- Instead of using Rodux store
-- TODO : Use smart ID instead of Humanoid as key

-- Per enemy property
local life = {}
local lifeBar = {}
local deathEvent = {}

local EnemyService = Knit.CreateService({
	Name = "EnemyService",
	-- Client = {},
})

-- Take an instance and associate it stats
function EnemyService:CreateEnemy(humanoid, enemyType)
	local character = humanoid.Parent
	character.Parent = enemyParent

	life[humanoid] = enemyType.Life
	deathEvent[humanoid] = Signal.new()

	-- Try to find lifeBar
	local lBar = character:FindFirstChild("LifeBar")
	if lBar then
		lifeBar[humanoid] = lBar.LifeBar
	end
end

function EnemyService:DamageEnemy(userId, humanoid, damage)
	if not life[humanoid] then
		return
	end

	life[humanoid] -= damage

	local life = life[humanoid]

	-- print(" Dealt " .. damage .. " damage to " .. humanoid.Parent.Name .. " New life : " .. life)

	if lifeBar[humanoid] then
		local lifePercent = life / 100 -- TODO : Better Enemy type definition
		-- lifeBar[humanoid].Size = CFrame.new(lifePercent, 1)
		lifeBar[humanoid].Size = UDim2.new(lifePercent, 0, 1, 0)
	end

	if life <= 0 then
		local overKillDamage = math.abs(life)
		self:KillEnemy(userId, humanoid, overKillDamage)
	end
end

function EnemyService:KillEnemy(userId, humanoid, overKillDamage)
	-- TODO : Check if userId is nil -> attribute the kill to nearest Player
	deathEvent[humanoid]:Fire(userId)

	life[humanoid] = nil
	deathEvent[humanoid] = nil
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
	-- 	dummy.HumanoidRootPart.Anchored = true

	-- Death
	local clone = dummy:Clone()

	local function onDeath(userId)
		-- Feedback
		-- print(dummy.Name .. " Died")
		-- dismember(dummy)
		dummy.Torso.Snap:Destroy()

		-- Rewards
		-- PlayerService:IncrementScore(userId, 1)
		local orbsRng = math.random(1, 3)
		CombatService:SpawnManyItem(CombatService.autoItems.smallXpOrb, dummy:GetPivot().Position, orbsRng)

		-- Respawn
		task.wait(1)
		self:setupDummy(clone)
		dummy:Destroy()
	end

	deathEvent[humanoid]:Connect(onDeath)
end

local function setupAllDummies()
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
	setupAllDummies()
end

return EnemyService
