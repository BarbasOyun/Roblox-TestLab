local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Gears = require(ReplicatedStorage.Shared.Gears)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages._Index["sleitnick_signal@1.5.0"].signal)

local RoduxStore = require(ReplicatedStorage.Shared.RoduxStore)
local store = RoduxStore.Store
local storeActions = RoduxStore.Actions

-- ITEM SYSTEM DESIGN
-- Items = Can go in Inventory + Interaction

-- Item Data Types :
-- 1) Defined Items = Item instance use definition Data eg minor health potion
-- 2) Instance Items = Item Instance use instantiated Data (from definition) eg iron sword

-- Pickup Behaviors :
-- 1) Manual = Click
-- 2) Auto = Vacuumed + Can't be clicked

-- Item Types :
-- 1) Equipment :
--  Can be placed in appropriate equipment Slot -> used with character actions
--  Subtypes = Weapon & Gear
--  Item Data Type = Instance Items
--  Pickup Behavior = Manual

-- 2) Usable :
--  Effect on right click
--  Subtype = Consumable = item destroyed
-- 3) AutoPickup Usables
-- 	Subtype = Orb -> consumed on pickup ~item eg XpOrbs

-- 4) Reagent = Used in crafting
--  Item Data Type = Defined Items
--  Pickup Behavior = Manual
-- 5) AutoPickupReagent

-- ITEM DEFINITIONS
-- Authoring Data > Move to file
-- Endgame setup = csv file

-- Usables are first to find their logic
-- TODO : Split per type -> avoid Item Editing Nightmare
local itemDefinitions = {
	-- Usables
	{
		id = 1,
		name = "Banana",
		itemType = "Usable",
		-- sprite = nil, -- Found using id
		-- prefab = nil, -- Found using id
		gridSizeX = 1,
		gridSizeY = 1,
		toolTipText = "A Banana",
		-- useFunction = nil, -- Found using id
		-- Additional data
		maxStack = 10,
		lifeHeal = 10, -- On Use
	},

	{
		id = 2,
		name = "Small XP Orb",
		itemType = "Orb",
		-- xp = 10,
		score = 1,
	},

	-- Reagents
	{
		id = 3,
		name = "Stick",
		itemType = "Reagent",
		gridSizeX = 2,
		gridSizeY = 1,
		toolTipText = "A Stick",
		maxStack = 5,
	},

	-- Weapons
	{
		id = 4,
		name = "Wooden Club",
		itemType = "Weapon",
		toolTipText = "Wooden Club",
		weaponType = "Mace",
		damage = 25,
		attackSpeed = 0.75,
		range = 6,
		maxCombo = 2,
	},

	-- Gear
	-- eg ironBodyArmor
}

-- Item name to ID
local itemStore = {
	Banana = 1,
	SmallXpOrb = 2,
	Stick = 3,
	WoodenClub = 4,
}

local equipmentTypeDefinitions = {
	["Mace"] = {
		gridSizeX = 2,
		gridSizeY = 6,
	},
	-- Two-handed Mace
	-- One-handed Sword
	-- Body Armor
	-- ...
}

local ItemService = Knit.CreateService({
	Name = "ItemService",
	ItemStore = itemStore, -- Hold an ItemStore for other services -> ensure item spawn
	EquipWeapon = Signal.new(),
	UnequipWeapon = Signal.new(),
	Client = {
		GetOrb = Knit.CreateSignal(),
		EquipWeapon = Knit.CreateSignal(),
		UnequipWeapon = Knit.CreateSignal(),
	},
})

local PlayerService = nil

-- ITEM SERVICE DEFINITIONS
-- can't be in anywhere else

local itemTypes = {
	usable = "Usable",
	autoPickupUsable = "AutoPickupUsable",
	orb = "Orb",
	reagent = "Reagent",
	autoPickupReagent = "AutoPickupReagent",
	weapon = "Weapon",
	gear = "Gear",
}

local itemTypeTags = {
	-- Data source type
	Defined = "Defined",
	Instance = "Instance",
	-- Pickup Behavior
	Manual = "Manual",
	Auto = "Auto",
}

local itemTypeDefinition = {
	["Usable"] = { "Defined", "Manual" },
	["AutoPickupUsable"] = { "Defined", "Auto" },
	["Orb"] = { "Defined", "Auto" },
	["Reagent"] = { "Defined", "Manual" },
	["AutoPickupReagent"] = { "Defined", "Auto" },
	["Weapon"] = { "Instance", "Manual" },
	["Gear"] = { "Instance", "Manual" },
}

local itemVisualDefinitions = {
	{ ReplicatedStorage.Shared.Prefabs.Banana, "rbxassetid://102081417185866" }, -- eg id 0 = Banana Prefab + Sprite
	ReplicatedStorage.Shared.Prefabs.SmallXpOrb,
	{ ReplicatedStorage.Shared.Prefabs.Stick },
	{ ReplicatedStorage.Shared.Prefabs.WoodenClub },
}

local usablesLogicDefinition = {
	["Banana"] = function(player, itemDefinition)
		-- heal
	end,
	["Small XP Orb"] = function(player, itemDefinition, itemModel)
		-- print("Add Small XP Orb to : " .. player.Name)
		-- PlayerService:AddXpToPlayer(10)
		PlayerService:AddScore(player.UserId, itemDefinition.score)
		itemModel:Destroy()
	end,
}

-- DATA STRUCTS

-- For Instance Items
local ITEM_STRUCT = {
	-- id = 0,
	definitionId = 0,
	-- userId = 0, -- Owner
	-- name = "",
	-- type = "",
	-- gridSizeX = 1,
	-- gridSizeY = 1,
	-- toolTipText = "",
	additionalData = {},
}

local GROUND_ITEM_STRUCT = {
	model = nil,
	item = nil,
}

local INVENTORY_ITEM_STRUCT = {
	sprite = nil,
	item = nil,
}

local INVENTORY_STRUCT = {
	inventory_space = {}, -- flat bool array
	items = {}, -- Key = 2D Position
}

local INVENTORY_ROW_SIZE = 10
local INVENTORY_COL_SIZE = 5

-- ITEM RUNTIME
-- Item Visuals = 3D Model -> on ground || Sprite -> UI
-- Items visuals hold "DefinitionId" attribute

-- array of un-owned ground items
-- only Instance Items are in it
-- Each Instance Item model also hold "Id" attribute = groundItems index
local groundItems = {}

-- UTILS

local function isInstanceType(itemType)
	return itemTypeDefinition[itemType][1] == itemTypeTags.Instance
end

local function isManualPickupType(itemType)
	return itemTypeDefinition[itemType][2] == itemTypeTags.Manual
end

-- SPAWN ITEMS

local function lootMovement(item, startPos)
	-- item.Position = startPos
	item.CFrame = CFrame.new(startPos)

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

local function spawnItemDef(itemDefinition, position)
	if isInstanceType(itemDefinition.itemType) then
		local newItem = Gears.deepCopy(ITEM_STRUCT)
		newItem.definitionId = itemDefinition.id
	end

	-- Spawn Model
	local newModel = nil

	if itemDefinition.itemType ~= itemTypes.orb then
		newModel = itemVisualDefinitions[itemDefinition.id][1]:clone()
	else
		newModel = itemVisualDefinitions[itemDefinition.id]:clone() -- Orbs don't use sprites
	end

	-- newModel.Name = itemDefinition.name
	newModel.Parent = workspace

	local partToMove = newModel

	if itemDefinition.itemType == itemTypes.weapon then
		partToMove = newModel.Handle
	end

	task.wait(lootMovement(partToMove, position))

	-- Enable Pickup
	if isManualPickupType(itemDefinition.itemType) then
		newModel.Parent = workspace.Pickup
	else
		newModel.Parent = workspace.AutoPickup
	end
end

function ItemService:SpawnItem(itemDefinitionId, position)
	local itemDefinition = itemDefinitions[itemDefinitionId]
	spawnItemDef(itemDefinition, position)
end

function ItemService:SpawnManyItem(itemDefinitionId, position, itemCount)
	local itemDefinition = itemDefinitions[itemDefinitionId]

	for i = 0, itemCount, 1 do
		task.spawn(function()
			spawnItemDef(itemDefinition, position)
		end)
		task.wait() -- delay
	end
end

function ItemService:SpawnWeapon(item, position)
	local newItem = item:clone()
	newItem.Parent = workspace

	task.wait(lootMovement(newItem.Handle, position))

	newItem.Parent = workspace.Pickup -- Enable Pickup
end

-- Automatic Pickup using PickupRange stat
function ItemService:SpawnAutomaticItem(item, position)
	local newItem = item:clone()
	newItem.Parent = workspace

	task.wait(lootMovement(newItem, position))

	newItem.Parent = workspace.AutoPickup
end

-- GET ITEMS

function ItemService:GenerateLoot(player, enemyHumanoid)
	-- TODO : Generate Loot based on : PlayerStats, Enemy type + Modifier, Area Modifiers

	local orbsRng = math.random(1, 3)
	self:SpawnManyItem(itemStore.SmallXpOrb, enemyHumanoid.Parent:GetPivot().Position, orbsRng)
end

function ItemService:GetOrb(orb, player)
	if orb.Name == "SmallXpOrb" then
		-- print("Add Small XP Orb")
		-- PlayerService:AddXpToPlayer(10)
		PlayerService:IncrementScore(player.UserId, 1)
	end

	self.Client.GetOrb:Fire(player)
	orb:Destroy()
end

-- Item Pickup :
-- Autopickup = Add to inventory
-- Orb = Use
-- Manual Item = Set sprite on mouse
function ItemService:PickupItem(player, itemModel)
	local definitionId = itemModel:GetAttribute("DefinitionId")
	local itemDefinition = itemDefinitions[definitionId]

	-- if isUsable(itemDefinition)

	if itemDefinition.itemType == itemTypes.orb then
		-- Use Orb
		usablesLogicDefinition[itemDefinition.name](player, itemDefinition, itemModel) -- Consumables / Orbs need item visual
		self.Client.GetOrb:Fire(player) -- SFX Feedback
	end
end

-- WEAPON : SETUP & EQUIP

local function createWeapon(weaponModel, weaponDefinition)
	-- Weapon Definition -> Weapon Data Structure
	local handle = weaponModel.Handle

	-- TODO : Weapon Inventory Item
	-- Dynamic Data / Instance
	local weapon = {
		weaponType = weaponDefinition.weaponType,
		-- definitionId = 0,
		-- Model
		weapon = weaponModel,
		weaponSize = weaponModel:GetScale(),
		handle = handle,
		attackPoint = handle.AttackPoint,
		-- Offense
		damage = weaponDefinition.damage, -- Calculate using Weapon Definition + Weapon Modifiers
		attackSpeed = weaponDefinition.attackSpeed,
		-- Utility
		aoe = weaponDefinition.range,
		-- Misc
		attackVFX = handle.AttackPoint.AttackHitVFX,
		maxCombo = weaponDefinition.maxCombo, -- TODO : Delete -> max combo never change
		-- Modifiers
		-- Rarity = "Common",
		-- Modifiers = nil,
	} -- Weapon Data Structure

	return weapon
end

local function setWeapon(player, weapon)
	-- print(player.Name .. " new Weapon Data")
	store:dispatch(storeActions.SetWeaponData(player.UserId, weapon))
end

local function addSounds(player, weapon)
	local playerGUi = player.PlayerGui

	-- Create Sounds
	local soundsPrefab = ReplicatedStorage.Shared.Prefabs.Sounds
	soundsPrefab.Unsheath:clone().Parent = playerGUi
	soundsPrefab.Slash:clone().Parent = playerGUi
	soundsPrefab.CriticalSlash:clone().Parent = playerGUi

	weapon.sounds = {
		unsheath = playerGUi.Unsheath,
		slash = playerGUi.Slash,
		crit = playerGUi.CriticalSlash,
	}
end

local function onEquipped(weaponModel, weapon)
	local character = weaponModel.Parent
	local player = Players:GetPlayerFromCharacter(character)
	print("Equip Weapon : " .. player.Name .. " -> " .. weaponModel.Name)

	-- TODO : Check if sounds are available -> Spawn & Delete sounds
	addSounds(player, weapon)

	setWeapon(player, weapon)
	PlayerService:ApplyStats(player.UserId)

	weapon.sounds.unsheath:Play()

	ItemService.EquipWeapon:Fire()
	-- Notice client > custom tool system
	ItemService.Client.EquipWeapon:Fire(player, true) -- pass weapon?
end

local function onUnequipped(weaponModel)
	if not weaponModel or weaponModel.Parent == nil then
		return
	end

	local character = weaponModel.Parent
	local player = Players:GetPlayerFromCharacter(character)
	print("Unequip Weapon : " .. player.Name .. " -> " .. weaponModel.Name)

	local playerData = store.getState(store).players[player.UserId]

	if playerData == nil then
		return
	end

	local weaponData = playerData.weaponData

	-- Remove Sounds
	for _, sound in pairs(weaponData.sounds) do
		sound:Destroy()
	end

	-- Reset Data
	setWeapon(player, nil)
	PlayerService:ApplyStats(player.UserId)

	-- Events
	ItemService.UnequipWeapon:Fire(player)
	ItemService.Client.UnequipWeapon:Fire(player)
end

local function SetupWeaponInstances(weaponType)
	local function setupWeapon(weaponModel)
		print("Setup weapon model : " .. weaponModel.Name)

		local definitionId = weaponModel:GetAttribute("DefinitionId")
		local weaponDefinition = itemDefinitions[definitionId]

		local weapon = createWeapon(weaponModel, weaponDefinition)

		-- TODO : Use custom tool system
		weaponModel.Equipped:Connect(function()
			onEquipped(weaponModel, weapon)
		end)

		weaponModel.Unequipped:Connect(function()
			onUnequipped(weaponModel)
		end)
	end

	-- Setup Existing Weapons
	for _, weaponModel in pairs(CollectionService:GetTagged(weaponType)) do
		setupWeapon(weaponModel)
	end

	-- Setup Future Weapons
	CollectionService:GetInstanceAddedSignal(weaponType):Connect(function(weaponModel)
		setupWeapon(weaponModel)
	end)
end

-- KNIT SERVICE

local function unitTest()
	-- Test Everything
end

function ItemService:KnitInit()
	print("ItemService Init")
end

function ItemService:KnitStart()
	PlayerService = Knit.GetService("PlayerService")

	SetupWeaponInstances("WoodenClub")
	-- SetupWeaponInstances("IronMace")
	-- SetupWeaponInstances("IronAxe")

	-- unitTest()
end

return ItemService
