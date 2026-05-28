local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Gears = require(ReplicatedStorage.Shared.Gears)

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerService = nil
local EnemyService = nil

local RoduxStore = require(ReplicatedStorage.Shared.RoduxStore)
local store = RoduxStore.Store
local storeActions = RoduxStore.Actions

-- Weapon
local WeaponBaseData = require(ReplicatedStorage.Shared.Data.WeaponData)

local weaponHitParam = OverlapParams.new()
weaponHitParam.FilterType = Enum.RaycastFilterType.Include
weaponHitParam.FilterDescendantsInstances = { workspace.WeaponHit }
weaponHitParam.MaxParts = 100

local ITEM_STRUCT = {
	-- -Name
	-- -Type
	-- -Grid Size
	-- -Icon / Sprite
	-- -TooltipText
	-- -Use Function -> on RClick
}

local CombatService = Knit.CreateService({
	Name = "CombatService",
	items = {
		woodenClub = ReplicatedStorage.Shared.Prefabs.WoodenClub,
		banana = ReplicatedStorage.Shared.Prefabs.Banana,
		stick = ReplicatedStorage.Shared.Prefabs.Stick,
	},
	automaticItems = {
		smallXpOrb = ReplicatedStorage.Shared.Prefabs.SmallXpOrb,
	},
	Client = {
		equipWeapon = Knit.CreateSignal(),
		startAttack = Knit.CreateSignal(),
		finishAttack = Knit.CreateSignal(),
	},
})

-- Player Combat Data
-- Only used by CombatService > not worth to put on store
local expectingAttack = {}
local attackBuffer = {}
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
-- 1) Client : Player Input -> Ask Server to Attack
-- 2) Server : Validation + Setup Expected Attack -> startAttack Event
-- 3) Clients : Animation
-- 4) Server : Attack Callback + validation
-- 5) Server : HitDetection + Damage + Feeback -> finishAttack Event

-- 5) HitDetection + Damage + Feeback
-- Context = After Validation
local function attackFeedback(weaponData, isCrit)
	-- VFX
	weaponData.attackVFX:Emit(5)

	-- Attack SFX
	if isCrit then
		Gears.safePlaySound(weaponData.sounds.crit)
		return
	end

	Gears.safePlaySound(weaponData.sounds.slash)
end

local function attackHit(player, playerStats, weaponData)
	-- Damage
	local damage = playerStats.attackDamage
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

	local hits = workspace:GetPartBoundsInRadius(attackPosition.Position, playerStats.aoe, weaponHitParam)
	local humanoidsHit = {} -- Avoid hitting the same Enemy twice

	-- Debug HitZone
	Gears.executeFor(0.5, function()
		Gears.drawSphere(attackPosition.Position, playerStats.aoe)
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
		-- print(player.Name .. " Hit : " .. humanoid.Parent.Name)
	end

	-- Feedback
	attackFeedback(weaponData, isCrit)
end

-- 4) Attack Callback with server validation
-- After Animation
local function incrementCombo(player, weaponData)
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

local function attackCallback(player)
	local playerStats, weaponData = getStoreData(player)

	local currentTime = tick()
	local attackDelta = currentTime - lastAttacks[player.UserId] -- Time between last attack and now

	-- Check if The Call is Legit
	-- Using setup on step 2)
	if not expectingAttack[player.UserId] and attackDelta >= playerStats.animationTime then
		warn("Unexpected AttackHit from player: " .. player.Name)
		return
	end
	-- Reset Player speed
	player.Character.Humanoid.WalkSpeed = playerStats.movementSpeed
	expectingAttack[player.UserId] = nil
	attackBuffer[player.UserId] = nil

	if not weaponData then
		return
	end

	attackHit(player, playerStats, weaponData)
	incrementCombo(player, weaponData)
end

-- 2) Server Validation + Setup Expected Attack
-- Player is asking to Attack using their Weapon
local function attackValidation(player)
	local playerStats, weaponData = getStoreData(player)

	if not playerStats or not weaponData then
		warn("No playerStats or weaponData")
		return
	end

	-- TODO : Measure animations using frames instead of time
	local currentTime = tick()
	local attackDelta = currentTime - lastAttacks[player.UserId] -- Time between last attack and now
	local isAttackReady = attackDelta > playerStats.animationTime

	local function startAttack()
		-- print("Attack By : " .. player.Name .. " At : " .. tick())
		lastAttacks[player.UserId] = tick()
		expectingAttack[player.UserId] = true
		player.Character.Humanoid.WalkSpeed *= 0.5 -- TODO : Half MS using stats instead

		CombatService.Client.startAttack:Fire(player, comboIndexes[player.UserId] + 1, playerStats.attackSpeed)
	end

	if not isAttackReady then
		-- Input Buffer
		local missingTime = playerStats.animationTime - attackDelta -- Time to wait before attacking

		if missingTime <= 0.1 and attackBuffer[player.UserId] == nil then
			-- print("Attack Buffer: " .. player.Name)
			attackBuffer[player.UserId] = true -- Lock Input Buffer
			task.delay(missingTime, function()
				startAttack()
			end)
		end

		return
	end

	-- print("Attack non buffer: " .. player.Name)
	startAttack()
end

-- WEAPON : Setup & Equip

local function setWeaponData(player, weaponData)
	-- print(player.Name .. " new Weapon Data")
	store:dispatch(storeActions.SetWeaponData(player.UserId, weaponData))
end

local function addSounds(weaponData, player)
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

local function onEquipped(weapon, weaponData)
	local character = weapon.Parent
	local player = Players:GetPlayerFromCharacter(character)
	print(weapon.Name .. " Equipped by player: " .. player.Name)

	-- TODO : Check if sounds are available -> Spawn & Delete sounds
	addSounds(weaponData, player)

	setWeaponData(player, weaponData)
	PlayerService:ApplyStats(player.UserId)

	weaponData.sounds.unsheath:Play()

	CombatService.Client.equipWeapon:Fire(player, true)
end

local function onUnequipped(weapon)
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
	setWeaponData(player, nil)
	expectingAttack[player.UserId] = nil
	comboIndexes[player.UserId] = nil
	comboReset[player.UserId] = nil

	PlayerService.ApplyStats(player)

	CombatService.equipWeapon:Fire(player, false)
end

local function createWeaponData(weapon, weaponType)
	local weaponData = WeaponBaseData[weaponType]
	local handle = weapon.Handle

	return {
		-- Weapon
		weapon = weapon,
		weaponType = weaponData.weaponType,
		weaponSize = weapon:GetScale(),
		handle = handle,
		attackPoint = handle.AttackPoint,
		-- Offense
		damage = weaponData.damage,
		attackSpeed = weaponData.attackSpeed,
		-- Utility
		aoe = weaponData.range,
		-- Misc
		attackVFX = handle.AttackPoint.AttackHitVFX,
		maxCombo = weaponData.maxCombo,
	}
end

local function SetupWeaponInstances(weaponType)
	local function setupWeapon(weapon)
		print("Setup weapon : " .. weapon.Name)
		local weaponData = createWeaponData(weapon, weaponType)

		-- TODO : Use custom tool system
		weapon.Equipped:Connect(function()
			onEquipped(weapon, weaponData)
		end)

		weapon.Unequipped:Connect(function()
			onUnequipped(weapon)
		end)
	end

	-- Setup Existing Weapons
	for _, weapon in pairs(CollectionService:GetTagged(weaponType)) do
		setupWeapon(weapon)
	end

	-- Setup Future Weapons
	CollectionService:GetInstanceAddedSignal(weaponType):Connect(function(weapon)
		setupWeapon(weapon)
	end)
end

-- COMBAT SERVICE

function CombatService:KnitInit()
	print("CombatService Init")

	SetupWeaponInstances("WoodenClub")
	-- SetupWeaponInstances("IronMace")
	-- SetupWeaponInstances("IronAxe")

	self.Client.startAttack:Connect(function(player)
		attackValidation(player)
	end)

	self.Client.finishAttack:Connect(function(player)
		attackCallback(player)
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

-- TODO : ItemService

-- Item Types = Equipment, Consumable, Reagent

function lootMovement(item, startPos)
	item.Position = startPos
	item.Parent = workspace

	local targetPos = startPos + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
	local finalTargetPos = targetPos
	local result = workspace:Raycast(targetPos, Vector3.new(0, -10, 0))

	if result then
		finalTargetPos = result.Position
	else
		return
	end

	local steps = 60
	local height = math.random(2, 5)

	for i = 1, steps do
		local progress = i / steps
		item.CFrame = CFrame.new(Gears.parabolaPos(startPos, finalTargetPos, height, progress))
		RunService.Heartbeat:Wait()
	end
end

-- TODO : REDO
-- Manual Pickup
function CombatService:SpawnItem(item, position)
	local newItem = item:clone()
	task.wait(lootMovement(newItem, position))

	newItem.Parent = workspace.Pickup -- Enable Pickup
end

-- Automatic Pickup using PickupRange stat
function CombatService:SpawnAutomaticItem(item, position)
	print(item)
	print(position)

	local newItem = item:clone()
	task.wait(lootMovement(newItem, position))

	newItem.Parent = workspace.AutomaticPickup
end

return CombatService
