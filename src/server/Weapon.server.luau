local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gears = require(ReplicatedStorage.Shared.Gears)

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await()

local PlayerService = Knit.GetService("PlayerService")

local RoduxStore = require(ReplicatedStorage.Shared.RoduxStore)
local store = RoduxStore.Store
local storeActions = RoduxStore.Actions

local WeaponBaseData = require(ReplicatedStorage.Shared.Data.WeaponData)

-- Sounds Prefabs
local slashSoundPrefab = ReplicatedStorage.Prefabs.Slash
local critSoundPrefab = ReplicatedStorage.Prefabs.CriticalSlash
local unsheathSoundPrefab = ReplicatedStorage.Prefabs.Unsheath
local buildingHitSoundPrefab = ReplicatedStorage.Prefabs.BuildingHit

--Remote Events
-- local attackEvent = Events.ToolAttack
-- local equipEvent = Events.ToolEquip
-- local attackHitEvent = Events.AttackHit

-- Players
local expectingAttack = {}

-- Used at runtime
local PLAYER_COMBAT_STRUCT = {
	lastAttack = 0,
	comboCount = 0,
	comboReset = nil,
}

-- WEAPON

local weaponHitParam = OverlapParams.new()
weaponHitParam.FilterType = Enum.RaycastFilterType.Include
weaponHitParam.FilterDescendantsInstances = { workspace.WeaponHit }
weaponHitParam.MaxParts = 100

function FindHumanoidFromPart(part)
	local character = part.Parent

	if character then
		return character:FindFirstChild("Humanoid")
	end

	return nil
end

-- ATTACK
-- 1) Client Call on Player Input
-- 2) Server Validation + Setup Expected Attack
-- 3) Clients Animation
-- 4) Attack Callback with server validation
-- 5) HitDetection + Damage

local function IncrementCombo(playerStat)
	playerStat.comboCount += 1

	if playerStat.comboCount > 1 then
		playerStat.comboCount = 0
	end

	-- Reset Combo Count after 2 sec of not Attacking
	-- if playerStat.comboReset then
	-- 	task.cancel(playerStat.comboReset)
	-- end

	-- playerStat.comboReset = task.delay(2, function()
	-- 	print("Combo Reset")
	-- 	playerStat.comboCount = 0
	-- end)
end

-- 5) HitDetection + Damage
local function HitDetection(player, playerStat, weaponInfo, finalDamage, isCrit)
	local attackPosition = weaponInfo.attackPoint.WorldCFrame
	local hits = workspace:GetPartBoundsInRadius(attackPosition.Position, weaponInfo.finalAoe, weaponHitParam)
	local humanoidsHit = {}
	local isBuilding = false

	-- DEBUG
	Gears.executeFor(0.5, function()
		Gears.drawSphere(attackPosition.Position, weaponInfo.finalAoe)
	end)

	-- VFX
	-- weaponInfo.attackVFX:Emit(5)

	for _, hit in ipairs(hits) do
		-- print("Hit Part: " .. hit.Name)
		-- TODO Remake without Humanoid
		local humanoid = FindHumanoidFromPart(hit)

		if humanoid then
			-- Enemy Hit
			if humanoid.Parent ~= player.Character and humanoidsHit[humanoid] == nil then
				humanoidsHit[humanoid] = true
				humanoid:TakeDamage(finalDamage)
				-- print(player.name .. " Dealt " .. weaponInfo.Damage .. " damage to " .. humanoid.Parent.Name)
				if humanoid.Health <= 0 then
					playerStat.kills.Value += 1
				end
			end
		end
	end

	-- Attack SFX
	if isCrit then
		Gears.safePlaySound(weaponInfo.sounds.crit)
		return
	elseif isBuilding then
		Gears.safePlaySound(weaponInfo.sounds.buildingHit)
		return
	end

	Gears.safePlaySound(weaponInfo.sounds.slash)
end

-- 4) Attack Callback with server validation
-- After Animation
local function AttackCallback(player)
	-- Check if The Call is Legit
	-- Using setup on step 2)
	if not expectingAttack[player.UserId] then
		print("Unexpected AttackHit from player: " .. player.Name)
		return
	end

	local storeState = store.getState()
	local playerStats = storeState.players[player.UserId].stats
	local weaponData = storeState.players[player.UserId].weaponData

	-- Reset Player speed
	player.Character.Humanoid.WalkSpeed = playerStats.mobility
	expectingAttack[player.UserId] = nil

	if not weaponData then
		return
	end

	-- Get Damage & Crit
	local finalDamage = weaponData.finalAttackDamage
	local isCrit = false
	local critRoll = math.random(0, 100)
	-- print("Crit roll : " .. critRoll .. " Crit Chance : " .. playerStats.critChance)

	if critRoll <= playerStats.critChance then
		finalDamage *= Gears.increaseToMultiplier(playerStats.critMultiplier)
		-- print("Crit " .. finalDamage)
		weaponData.sounds.crit:Play()
		isCrit = true
		-- else
		-- 	weaponData.sounds.slash:Play()
	end

	HitDetection(player, playerStats, weaponData, finalDamage, isCrit)
	IncrementCombo(playerStats)
end

-- 2) Server Validation + Setup Expected Attack
-- Player is asking to Attack using their Weapon
local function Attack(player)
	local storeState = store.getState()
	local playerStats = storeState.players[player.UserId].stats
	local weaponData = storeState.players[player.UserId].weaponData

	if not playerStats or not weaponData then
		return
	end

	-- IsAttackReady
	local currentTime = tick()
	local attackDelta = currentTime - playerStats.lastAttack
	local missingTime = playerStats.animationTime - attackDelta

	local function StartAttack()
		-- print("Attack By : " .. player.Name)
		playerStats.lastAttack = tick() -- TODO : Update
		expectingAttack[player.UserId] = true
		player.Character.Humanoid.WalkSpeed *= 0.5
		-- attackEvent:FireClient(player, playerStats.comboCount + 1, weaponData.finalAttackSpeed) -- Animation
	end

	if attackDelta < playerStats.animationTime then
		-- Input Buffer
		if missingTime <= 0.1 then
			-- print("Attack Buffer: " .. player.Name)
			playerStats.lastAttack = currentTime -- Lock Input Buffer -- TODO : Update
			task.delay(missingTime, function()
				StartAttack()
			end)
		end

		return
	end

	-- print("Attack non buffer: " .. player.Name)
	StartAttack()
end

-- Setup & Equip Weapons

local function AddSounds(weaponData, player)
	local playerGUi = player.PlayerGui

	-- Create Sounds -> Same Sounds for every weapon
	local unsheath = unsheathSoundPrefab:clone()
	unsheath.Parent = playerGUi

	local slash = slashSoundPrefab:clone()
	slash.Parent = playerGUi

	local crit = critSoundPrefab:clone()
	crit.Parent = playerGUi

	local buildingHit = buildingHitSoundPrefab:clone()
	buildingHit.Parent = playerGUi

	weaponData.sounds = {
		unsheath = playerGUi.Unsheath,
		slash = playerGUi.Slash,
		crit = playerGUi.CriticalSlash,
		buildingHit = playerGUi.BuildingHit,
	}
end

local function OnEquipped(weapon, weaponData)
	local character = weapon.Parent
	local player = Players:GetPlayerFromCharacter(character)
	-- print(weapon.Name .. " Equipped by player: " .. player.Name)

	AddSounds(weaponData, player)

	-- TODO : Dispatch weaponData
	-- store.getState().players[player.UserId].combatData.weaponData = weaponData
	PlayerService:ApplyStats(player)

	weaponData.sounds.unsheath:Play()

	-- equipEvent:FireClient(
	-- 	player,
	-- 	true,
	-- 	{ weaponData.sounds.slash, weaponData.sounds.buildingHit, weaponData.sounds.crit }
	-- )
end

local function OnUnequipped(weapon)
	if not weapon or weapon.Parent == nil then
		return
	end

	local player = weapon.Parent.Parent

	if not player or Players:FindFirstChild(player.Name, false) == nil then
		return
	end

	-- print(weapon.Name .. " Unequipped by player: " .. player.Name)

	local storeState = store.getState()
	local playerStats = storeState.players[player.UserId].stats
	local weaponData = storeState.players[player.UserId].weaponData

	-- Remove Sounds
	for _, sound in pairs(playerStats.weaponData.sounds) do
		sound:Destroy()
	end

	-- TODO : Dispatch all
	-- playerStats.weaponData = nil
	-- playerStats.comboCount = 0
	-- playerStats.comboReset = nil
	expectingAttack[player.UserId] = nil

	PlayerService.ApplyStats(player)

	-- equipEvent:FireClient(player, false)
end

local function CreateWeaponData(weapon, weaponTag)
	local handle = weapon.Handle

	return {
		weapon = weapon,
		weaponSize = weapon:GetScale(),
		handle = handle,
		attackPoint = handle.AttackPoint,
		weaponType = WeaponBaseData[weaponTag].WeaponType,
		damage = WeaponBaseData[weaponTag].BaseDamage,
		finalAttackDamage = WeaponBaseData[weaponTag].BaseDamage,
		range = WeaponBaseData[weaponTag].Range,
		finalAoe = WeaponBaseData[weaponTag].Range,
		attackSpeed = WeaponBaseData[weaponTag].AttackSpeed,
		finalAttackSpeed = WeaponBaseData[weaponTag].AttackSpeed,
		attackVFX = handle.AttackPoint.AttackHitVFX,
	}
end

local function setupWeapon(weapon, weaponTag)
	local weaponData = CreateWeaponData(weapon, weaponTag)

	weapon.Equipped:Connect(function()
		OnEquipped(weapon, weaponData)
	end)

	weapon.Unequipped:Connect(function()
		OnUnequipped(weapon)
	end)
end

-- TODO : Implement after Refactoring
-- local function InstantiateWeapon(position, weaponPrefab)
-- 	local weapon = weaponPrefab:Clone()
-- 	-- weapon:GetTa
-- end

local function SetupWeaponInstances(weaponTag)
	-- TODO : Fix Double Setup
	for _, weapon in pairs(CollectionService:GetTagged(weaponTag)) do
		setupWeapon(weapon, weaponTag)
	end

	CollectionService:GetInstanceAddedSignal(weaponTag):Connect(function(weapon)
		setupWeapon(weapon, weaponTag)
	end)
end

-- Setup Existing Weapons
SetupWeaponInstances("WoodenClub")
-- SetupWeaponInstances("IronMace")
-- SetupWeaponInstances("IronAxe")

-- EVENTS SETUP
-- attackEvent.OnServerEvent:Connect(Attack)
-- attackHitEvent.OnServerEvent:Connect(AttackCallback)
