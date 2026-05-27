local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gears = require(ReplicatedStorage.Shared.Gears)

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerService = nil
local EnemyService = nil

local RoduxStore = require(ReplicatedStorage.Shared.RoduxStore)
local store = RoduxStore.Store
local storeActions = RoduxStore.Actions

local CombatService = Knit.CreateService({
	Name = "CombatService",
	Client = {
		equipWeapon = Knit.CreateSignal(),
		startAttack = Knit.CreateSignal(),
		finishAttack = Knit.CreateSignal(),
	},
})

-- Weapon
local WeaponBaseData = require(ReplicatedStorage.Shared.Data.WeaponData)

local weaponHitParam = OverlapParams.new()
weaponHitParam.FilterType = Enum.RaycastFilterType.Include
weaponHitParam.FilterDescendantsInstances = { workspace.WeaponHit }
weaponHitParam.MaxParts = 100

-- Player Combat Data > Only used by CombatService > not worth to put on store
local expectingAttack = {}
local lastAttacks = {}
local comboIndexes = {} -- For Weapon Animation
local comboReset = {}

local function getStoreData(player)
	local storeState = store.getState(store)
	local playerStats = storeState.players[player.UserId].stats
	local weaponData = storeState.players[player.UserId].weaponData

	return playerStats, weaponData
end

-- ATTACK
-- 1) Client : Call on Player Input
-- 2) Server : Validation + Setup Expected Attack -> startAttack Event
-- 3) Clients : Animation
-- 4) Server : Attack Callback + validation
-- 5) Server : HitDetection + Damage + Feeback -> finishAttack Event

-- 5) HitDetection + Damage + Feeback
-- Context = After Validation
local function AttackFeedback(weaponData, isCrit)
	-- VFX
	-- weaponData.attackVFX:Emit(5)

	-- Attack SFX
	if isCrit then
		Gears.safePlaySound(weaponData.sounds.crit)
		return
	end

	Gears.safePlaySound(weaponData.sounds.slash)
end

local function AttackHit(player, playerStats, weaponData)
	-- Damage
	local damage = weaponData.damage
	local isCrit = false
	local critRoll = math.random(0, 100)
	-- print("Crit roll : " .. critRoll .. " Crit Chance : " .. playerStats.critChance)

	if critRoll <= playerStats.critChance then
		damage *= Gears.increaseToMultiplier(playerStats.critMultiplier)
		-- print("Crit " .. damage)
		weaponData.sounds.crit:Play()
		isCrit = true
	end

	-- Hit Detection
	local attackPosition = weaponData.attackPoint.WorldCFrame

	local hits = workspace:GetPartBoundsInRadius(attackPosition.Position, weaponData.aoe, weaponHitParam)
	local humanoidsHit = {} -- Avoid hitting the same Enemy twice

	-- Debug HitZone
	Gears.executeFor(0.5, function()
		Gears.drawSphere(attackPosition.Position, weaponData.aoe)
	end)

	for _, hit in ipairs(hits) do
		-- print("Hit Part: " .. hit.Name)
		local humanoid = Gears.FindHumanoidFromPart(hit)

		if not humanoid or humanoid.Parent == player.Character or humanoidsHit[humanoid] == true then
			continue
		end

		-- Enemy Hit
		humanoidsHit[humanoid] = true
		EnemyService:DamageEnemy(player.UserId, humanoid, damage)
		print(player.Name .. " Hit : " .. humanoid.Parent.Name)
	end

	-- Feedback
	AttackFeedback(weaponData, isCrit)
end

-- 4) Attack Callback with server validation
-- After Animation
local function IncrementCombo(player, weaponData)
	comboIndexes[player.UserId] = (comboIndexes[player.UserId] + 1) % weaponData.maxCombo

	-- Reset Combo Index -> after 2 sec of not Attacking
	-- if playerStat.comboReset then
	-- 	task.cancel(playerStat.comboReset)
	-- end

	-- playerStat.comboReset = task.delay(2, function()
	-- 	print("Combo Reset")
	-- 	playerStat.comboIndex = 0
	-- end)
end

function CombatService:AttackCallback(player)
	-- Check if The Call is Legit
	-- Using setup on step 2)
	if not expectingAttack[player.UserId] then
		warn("Unexpected AttackHit from player: " .. player.Name)
		return
	end

	local playerStats, weaponData = getStoreData(player)

	-- Reset Player speed
	player.Character.Humanoid.WalkSpeed = playerStats.movementSpeed
	expectingAttack[player.UserId] = nil

	if not weaponData then
		return
	end

	AttackHit(player, playerStats, weaponData)
	IncrementCombo(player, weaponData)
end

-- 2) Server Validation + Setup Expected Attack
-- Player is asking to Attack using their Weapon
function CombatService:AttackValidation(player)
	local playerStats, weaponData = getStoreData(player)

	if not playerStats or not weaponData then
		warn("No playerStats or weaponData")
		return
	end

	local currentTime = tick()
	local attackDelta = currentTime - lastAttacks[player.UserId] -- Time between last attack and now
	local timeOffset = 0.001
	local isAttackReady = attackDelta > playerStats.animationTime + timeOffset

	local function StartAttack()
		-- print("Attack By : " .. player.Name)
		lastAttacks[player.UserId] = tick()
		expectingAttack[player.UserId] = true
		player.Character.Humanoid.WalkSpeed *= 0.5 -- TODO : Half MS using stats instead

		self.Client.startAttack:Fire(player, comboIndexes[player.UserId] + 1, weaponData.attackSpeed)
	end

	if not isAttackReady then
		-- Input Buffer
		local missingTime = playerStats.animationTime - attackDelta -- Time to wait before attacking

		if missingTime <= 0.1 then
			-- print("Attack Buffer: " .. player.Name)
			lastAttacks[player.UserId] = currentTime -- Lock Input Buffer
			task.delay(missingTime + timeOffset, function()
				StartAttack()
			end)
		end

		return
	end

	-- print("Attack non buffer: " .. player.Name)
	StartAttack()
end

-- WEAPON : Setup & Equip

function CombatService:InstantiateWeapon(position, weaponPrefab)
	local weapon = weaponPrefab:Clone()
	-- weapon:GetTag
end

local function SetWeaponData(player, weaponData)
	-- print(player.Name .. " new Weapon Data")
	store:dispatch(storeActions.SetWeaponData(player.UserId, weaponData))
end

local function AddSounds(weaponData, player)
	local playerGUi = player.PlayerGui

	-- Create Sounds
	local prefabs = ReplicatedStorage.Shared.Prefabs
	prefabs.Unsheath:clone().Parent = playerGUi
	prefabs.Slash:clone().Parent = playerGUi
	prefabs.CriticalSlash:clone().Parent = playerGUi

	weaponData.sounds = {
		unsheath = playerGUi.Unsheath,
		slash = playerGUi.Slash,
		crit = playerGUi.CriticalSlash,
	}
end

local function OnEquipped(combatService, weapon, weaponData)
	local character = weapon.Parent
	local player = Players:GetPlayerFromCharacter(character)
	-- print(weapon.Name .. " Equipped by player: " .. player.Name)

	-- TODO : Check if sounds are available + Spawn & Delete sounds
	AddSounds(weaponData, player)

	SetWeaponData(player, weaponData)
	PlayerService:ApplyStats(player)

	weaponData.sounds.unsheath:Play()

	combatService.Client.equipWeapon:Fire(player, true) -- { weaponData.sounds.slash, weaponData.sounds.buildingHit, weaponData.sounds.crit }
end

local function OnUnequipped(combatService, weapon)
	if not weapon or weapon.Parent == nil then
		return
	end

	local player = weapon.Parent.Parent

	if not player or Players:FindFirstChild(player.Name, false) == nil then
		return
	end

	-- print(weapon.Name .. " Unequipped by player: " .. player.Name)

	local weaponData = store.getState().players[player.UserId].weaponData

	-- Remove Sounds
	for _, sound in pairs(weaponData.sounds) do
		sound:Destroy()
	end

	-- Reset Data
	SetWeaponData(player, nil)
	expectingAttack[player.UserId] = nil
	comboIndexes[player.UserId] = nil
	comboReset[player.UserId] = nil

	PlayerService.ApplyStats(player)

	combatService.equipWeapon:Fire(player, false)
end

local function CreateWeaponData(weapon, weaponType)
	local weaponData = WeaponBaseData[weaponType]
	local handle = weapon.Handle

	return {
		-- Weapon
		weapon = weapon,
		weaponSize = weapon:GetScale(),
		handle = handle,
		attackPoint = handle.AttackPoint,
		weaponType = weaponData.WeaponType,
		-- Offense
		baseDamage = weaponData.BaseDamage,
		damage = weaponData.BaseDamage,
		baseAttackSpeed = weaponData.AttackSpeed,
		attackSpeed = weaponData.AttackSpeed,
		-- Utility
		baseAoe = weaponData.Range,
		aoe = weaponData.Range,
		-- Misc
		attackVFX = handle.AttackPoint.AttackHitVFX,
		maxCombo = weaponData.maxCombo,
	}
end

local function SetupWeaponInstances(combatService, weaponType)
	local function setupWeapon(weapon)
		local weaponData = CreateWeaponData(weapon, weaponType)

		weapon.Equipped:Connect(function()
			OnEquipped(combatService, weapon, weaponData)
		end)

		weapon.Unequipped:Connect(function()
			OnUnequipped(combatService, weapon)
		end)
	end

	-- Setup Existing Weapon
	for _, weapon in pairs(CollectionService:GetTagged(weaponType)) do
		setupWeapon(weapon)
	end

	-- Setup Future Weapon
	CollectionService:GetInstanceAddedSignal(weaponType):Connect(function(weapon)
		setupWeapon(weapon)
	end)
end

-- KNIT INIT/START

function CombatService:KnitInit()
	print("CombatService Init")

	-- Move to GameManager?
	SetupWeaponInstances(self, "WoodenClub")
	-- SetupWeaponInstances("IronMace")
	-- SetupWeaponInstances("IronAxe")

	self.Client.startAttack:Connect(function(player)
		self:AttackValidation(player)
	end)

	self.Client.finishAttack:Connect(function(player)
		self:AttackCallback(player)
	end)
end

function CombatService:KnitStart()
	PlayerService = Knit.GetService("PlayerService")
	EnemyService = Knit.GetService("EnemyService")

	PlayerService.PlayerAdded:Connect(function(userId)
		lastAttacks[userId] = 0
		comboIndexes[userId] = 0
	end)

	PlayerService.PlayerRemoved:Connect(function(userId)
		lastAttacks[userId] = nil
		comboIndexes[userId] = nil
	end)
end

return CombatService
