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

local ItemService = Knit.CreateService({
	Name = "ItemService",
	ItemStore = nil, -- Hold an ItemStore for other services -> ensure item spawn
	EquipWeapon = Signal.new(),
	UnequipWeapon = Signal.new(),
	Client = {
		-- 3D / Models
		GetOrb = Knit.CreateSignal(),
		EquipWeapon = Knit.CreateSignal(),
		UnequipWeapon = Knit.CreateSignal(),
		PickupItem = Knit.CreateSignal(),
		-- 2D / UI
		DropCursorItem = Knit.CreateSignal(),
		DropInInventory = Knit.CreateSignal(),
		GrabInInventory = Knit.CreateSignal(),
		AddToInventory = Knit.CreateSignal(),
		RemoveFromInventory = Knit.CreateSignal(),
		UseInventoryItem = Knit.CreateSignal(),
	},
})

local itemDef = require(ReplicatedStorage.Shared.AuthoringData.ItemDefinitions)

local itemDefinitions = itemDef.itemDefinitions
local itemStore = itemDef.itemStore
local equipmentTypeDefinitions = itemDef.equipmentTypeDefinitions
local itemTypes = itemDef.itemTypes
local itemTypeTags = itemDef.itemTypeTags
local itemTypeDefinition = itemDef.itemTypeDefinition
local itemVisualDefinitions = itemDef.itemVisualDefinitions

local PlayerService = nil

-- ITEM SERVICE DEFINITIONS

-- TODO : useItem(player)
local usablesLogicDefinition = {
	["Banana"] = function(player, itemDefinition, itemSprite)
		-- print(itemDefinition.lifeHeal) -- TODO : Heal
		PlayerService:AddIncreasedAttackSpeed(player.UserId, 10)
		print(player.Name .. " Used Banana")
		-- TODO : Destroy sprite
	end,
	["Small XP Orb"] = function(player, itemDefinition, itemModel)
		-- print("Add Small XP Orb to : " .. player.Name)
		-- PlayerService:AddXpToPlayer(10)
		PlayerService:AddScore(player.UserId, itemDefinition.score)
		ItemService:RemoveGroundItem(itemModel)
	end,
}

-- DATA STRUCTS

-- Linked to models and sprite
local ITEM_STRUCT = {
	-- id = 0,
	definitionId = 0,
	-- userId = 0, -- Owner
	additionalData = nil, -- InstanceData or StackCount
}

local UI_ITEM_STRUCT = {
	item = nil,
	spriteLink = "",
}

local INVENTORY_ITEM_STRUCT = {
	item = nil,
	spriteLink = "",
	cellCoord = Vector2.zero,
	itemGridSize = Vector2.zero,
}

-- ITEM RUNTIME
-- Item Visuals = 3D Model -> on ground || Sprite -> UI
-- Items visuals hold "DefinitionId" attribute

-- Hold instanceItems for ground items
-- Each Item model hold "Id" attribute = groundInstanceItems index
local groundInstanceItems = {}
local idCount = 1 -- TODO : Replace with smart ID

-- UTILS

local function isInstanceType(itemType)
	return itemTypeDefinition[itemType][1] == itemTypeTags.Instance
end

local function isManualPickupType(itemType)
	return itemTypeDefinition[itemType][2] == itemTypeTags.Manual
end

local function isAutoPickupType(itemType)
	return itemTypeDefinition[itemType][2] == itemTypeTags.Auto
end

local function isEquipmentType(itemType)
	return itemType == itemTypes.weapon or itemType == itemTypes.gear
end

local function isUsable(itemType)
	return itemType == itemTypes.usable or itemType == itemTypes.autoPickupUsable
end

local function getItemGridSize(itemDefinition)
	local gridSizeX = 0
	local gridSizeY = 0

	if isEquipmentType(itemDefinition.itemType) then
		local equipmentTypeDefinition = equipmentTypeDefinitions[itemDefinition.equipmentType]
		gridSizeX = equipmentTypeDefinition.gridSizeX
		gridSizeY = equipmentTypeDefinition.gridSizeY
	else
		gridSizeX = itemDefinition.gridSizeX
		gridSizeY = itemDefinition.gridSizeY
	end

	-- print("Item gridSize : " .. " X = " .. gridSizeX .. " Y = " .. gridSizeY)

	return Vector2.new(gridSizeX, gridSizeY)
end

-- CREATE ITEMS

local function createItem(definitionId, additionalData)
	local item = Gears.deepCopy(ITEM_STRUCT)
	item.definitionId = definitionId
	item.additionalData = additionalData

	return item
end

local function createGearData(itemDefinition)
	if itemDefinition.itemType ~= itemTypes.gear then
		return
	end

	local gearData = {
		name = itemDefinition.name,
		armor = itemDefinition.armor,
		-- Modifiers
		-- Rarity = "Common",
		-- Modifiers = nil,
	}

	return gearData
end

-- Weapon Definition -> WeaponStats Data Struct instance
local function createWeaponData(itemDefinition, weaponModel)
	if itemDefinition.itemType ~= itemTypes.weapon then
		return
	end

	local handle = weaponModel.Handle

	-- Dynamic Data / Instance
	local weaponData = {
		name = itemDefinition.name,
		-- Model
		weaponSize = weaponModel:GetScale(),
		attackPoint = handle.AttackPoint,
		-- Offense
		damage = itemDefinition.damage, -- Calculate using Weapon Definition + Weapon Modifiers
		attackSpeed = itemDefinition.attackSpeed,
		-- Utility
		aoe = itemDefinition.range,
		-- Misc
		attackVFX = handle.AttackPoint.AttackHitVFX,
		maxCombo = itemDefinition.maxCombo,
		-- Modifiers
		-- Rarity = "Common",
		-- Modifiers = nil,
	}

	return weaponData
end

local function createInstanceItem(itemDefinition, newModel)
	local instanceData = nil

	if itemDefinition.itemType == itemTypes.weapon then
		instanceData = createWeaponData(itemDefinition, newModel)
	elseif itemDefinition.itemType == itemTypes.gear then
		instanceData = createGearData(itemDefinition)
	end

	if not instanceData then
		return
	end

	local newItem = createItem(itemDefinition.id, instanceData)

	return newItem
end

-- Associate a world ItemModel with ItemStruct in groundItem table
local function setupInstanceItem(newItem, newModel)
	idCount += 1
	local instanceId = idCount
	newModel:SetAttribute("Id", instanceId)
	groundInstanceItems[instanceId] = newItem

	return instanceId
end

-- SPAWN ITEMS MODELS

-- Spawn model at Position
local function spawnItemDef(itemDefinition, position)
	-- Spawn Model
	local newModel = itemVisualDefinitions[itemDefinition.id][1]:clone()

	local partToMove = newModel

	if itemDefinition.itemType == itemTypes.weapon then
		partToMove = newModel.Handle
	end

	partToMove.CFrame = CFrame.new(position)
	-- newModel.Name = itemDefinition.name
	newModel.Parent = workspace

	return newModel
end

-- spawnItemDef + Create Instance item & Enable pickup
local function spawnItem(itemDefinition, position, enablePickup)
	local newModel = spawnItemDef(itemDefinition, position)

	-- Add instance type to groundInstanceItems
	if isInstanceType(itemDefinition.itemType) then
		local instanceItem = createInstanceItem(itemDefinition, newModel)
		setupInstanceItem(instanceItem, newModel)
	end

	if enablePickup then
		newModel.Parent = isManualPickupType(itemDefinition.itemType) and workspace.ManualPickup or workspace.AutoPickup
	end

	return newModel
end

local function lootMovement(partToMove, startPos)
	partToMove.CFrame = CFrame.new(startPos)

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
		partToMove.CFrame = CFrame.new(Gears.parabolaPos(startPos, finalTargetPos, height, progress))
		RunService.Heartbeat:Wait()
	end
end

local function lootSetup(itemDefinition, newModel, position)
	local partToMove = newModel

	if itemDefinition.itemType == itemTypes.weapon then
		partToMove = newModel.Handle
	end

	task.wait(lootMovement(partToMove, position))

	newModel.Parent = isManualPickupType(itemDefinition.itemType) and workspace.ManualPickup or workspace.AutoPickup
end

-- Allow other services to spawn item with itemDefinitionId
function ItemService:SpawnItem(itemDefinitionId, position, enablePickup)
	local itemDefinition = itemDefinitions[itemDefinitionId]
	local newModel = spawnItem(itemDefinition, position, enablePickup)

	return newModel, itemDefinition
end

-- SpawnItem + lootMovement
function ItemService:SpawnLoot(itemDefinitionId, position)
	local newModel, itemDefinition = ItemService:SpawnItem(itemDefinitionId, position, false)
	lootSetup(itemDefinition, newModel, position)
end

function ItemService:SpawnManyItem(itemDefinitionId, position, itemCount)
	local itemDefinition = itemDefinitions[itemDefinitionId]

	for i = 0, itemCount, 1 do
		task.spawn(function()
			local newModel = spawnItem(itemDefinition, position, false)
			lootSetup(itemDefinition, newModel, position)
		end)
		task.wait() -- delay
	end
end

function ItemService:GenerateLoot(player, enemyHumanoid)
	-- TODO : Generate Loot based on : PlayerStats, Enemy type + Modifier, Area Modifiers

	local orbsRng = math.random(1, 3)
	self:SpawnManyItem(itemStore.SmallXpOrb, enemyHumanoid.Parent:GetPivot().Position, orbsRng)
end

function ItemService:RemoveGroundItem(itemModel, instanceId)
	if instanceId then
		groundInstanceItems[instanceId] = nil
	end

	-- TODO : Object Pooling
	itemModel:Destroy()
end

-- GET ITEMS

local function findAvailableInventorySpace(gridSize)
	-- TODO -> used for auto add to inventory
	local cellCoord = Vector2.new(0, 0)
	return cellCoord
end

-- cellCoord = top left
-- > Space = gridSize
local function isSpaceAvailable(player, cellCoord, itemGridSize)
	-- print("isSpaceAvailable : ")
	-- print("Coord : " .. "X = " .. cellCoord.X .. " Y = " .. cellCoord.Y)
	-- print("Space Size : " .. "X = " .. itemGridSize.X .. " Y = " .. itemGridSize.Y)

	local playerState = store:getState().players[player.UserId]
	local xLimit = playerState.inventory.columns
	local yLimit = playerState.inventory.rows
	-- TODO : Check yLimit -> get rowCount

	-- 1) cellCoord outside of inventory grid?
	if cellCoord.X > xLimit or cellCoord.Y > yLimit then
		print("cellCoord outside of inventory")
		return false
	end

	local itemSizeX = cellCoord.X + itemGridSize.X
	local itemSizeY = cellCoord.Y + itemGridSize.Y

	-- 2) Check itemGridSize outside of inventory grid?
	if itemSizeX > xLimit or itemSizeY > yLimit then
		print("item outside of inventory")
		return false
	end

	-- 3) Check for other items
	-- TODO : Use bool array and check near cells instead -> better for large inventory

	for _, inventoryItem in pairs(playerState.inventory.items) do
		local itemDef = itemDefinitions[inventoryItem.item.definitionId]
		local coord = inventoryItem.cellCoord
		local gridSize = getItemGridSize(itemDef)

		local sizeX = coord.X + gridSize.X
		local sizeY = coord.X + gridSize.Y

		local overlapX = cellCoord.X < coord.X and coord.X < itemSizeX or cellCoord.X < sizeX and sizeX < itemSizeX
		local overlapY = cellCoord.Y < coord.Y and coord.Y < itemSizeY or cellCoord.Y < sizeY and sizeY < itemSizeY

		if overlapX and overlapY then
			print("Another item overlap")
			return false
		end
	end

	return true
end

local function addToInventory(player, cellCoord, item)
	-- Validation
	local itemDef = itemDefinitions[item.definitionId]
	local gridSize = getItemGridSize(itemDef)

	if not isSpaceAvailable(player, cellCoord, gridSize) then
		return
	end

	-- Add item in Inventory
	local inventoryItem = Gears.deepCopy(INVENTORY_ITEM_STRUCT)
	inventoryItem.item = item
	inventoryItem.spriteLink = itemVisualDefinitions[item.definitionId][2]
	inventoryItem.cellCoord = cellCoord
	inventoryItem.itemGridSize = gridSize

	store:dispatch(storeActions.AddItemToInventory(player.UserId, inventoryItem))
	ItemService.Client.AddToInventory:Fire(player, inventoryItem)

	-- Delete Cursor Item
	store:dispatch(storeActions.SetCursorItem(player.UserId, nil))
	ItemService.Client.PickupItem:Fire(player, nil)
end

local function autoAddToInventory(player, item)
	local cellCoord = findAvailableInventorySpace()

	if cellCoord ~= Vector2.zero then
		addToInventory(player, cellCoord, item)
		return true
	end

	return false
end

-- When player pickup item with inventory closed
local function autoAddFromGround(player, item, itemModel, instanceId)
	local success = autoAddToInventory(player, item)

	if success then
		ItemService:RemoveGroundItem(itemModel, instanceId)
	end

	-- TODO : Drop item on ground at player pos
end

local function removeFromInventory(player, inventoryItem)
	-- store smart id in item?
	local playerState = store:getState().players[player.UserId]
	local removeIndex = table.find(playerState.inventory.items, inventoryItem)

	store:dispatch(storeActions.RemoveItemFromInventory(player.UserId, removeIndex))
	ItemService.Client.RemoveFromInventory:Fire(player, removeIndex)
end

-- ITEM PICKUP & DROP

local function setItemOnCursor(player, item)
	-- Create cursorItem
	local cursorItem = Gears.deepCopy(UI_ITEM_STRUCT)
	cursorItem.item = item
	cursorItem.spriteLink = itemVisualDefinitions[item.definitionId][2]

	store:dispatch(storeActions.SetCursorItem(player.UserId, cursorItem))
	ItemService.Client.PickupItem:Fire(player, cursorItem)
end

local function dropCursorItem(player)
	-- Validation
	local storePlayer = store:getState().players[player.UserId]
	local cursorItem = storePlayer and storePlayer.cursorItem

	if not cursorItem then
		return
	end

	local definitionId = cursorItem.item.definitionId
	local itemDefinition = itemDefinitions[definitionId]
	local spawnPos = player.character:GetPivot().Position + player.character:GetPivot().LookVector * 10
	local newModel = spawnItemDef(itemDefinition, spawnPos)

	if isInstanceType(itemDefinition.itemType) then
		local instanceId = setupInstanceItem(cursorItem.item, newModel)

		-- Reset weaponModel
		if itemDefinition.itemType == itemTypes.weapon then
			local handle = newModel.Handle
			groundInstanceItems[instanceId].attackPoint = handle.AttackPoint
			groundInstanceItems[instanceId].attackVFX = handle.AttackPoint.AttackHitVFX
		end
	end

	newModel.Parent = workspace.ManualPickup

	store:dispatch(storeActions.SetCursorItem(player.UserId, nil))
	ItemService.Client.PickupItem:Fire(player, nil)
end

local function dropCursorItemInInventory(player, cellCoord)
	-- Validation
	local playerState = store:getState().players[player.UserId]

	if not playerState or not playerState.cursorItem then
		return
	end

	local itemOnCursor = playerState.cursorItem.item
	local itemDef = itemDefinitions[itemOnCursor.definitionId]

	print(
		player.Name
			.. " Ask to DROP "
			.. itemDef.name
			.. " in inventory at : X = "
			.. cellCoord.X
			.. " Y = "
			.. cellCoord.Y
	)

	local itemGridSize = getItemGridSize(itemDef)

	-- Place item with offset based on its size
	-- cell Offset -> f(x) = ceil(x / 2) - 1
	local cellXOffset = math.ceil(itemGridSize.X / 2) - 1
	local cellYOffset = math.ceil(itemGridSize.Y / 2) - 1

	local offsetCoord = Vector2.new(cellCoord.x - cellXOffset, cellCoord.y - cellYOffset)

	addToInventory(player, offsetCoord, itemOnCursor)
end

local function getItemAt(player, cellCoord)
	print("No item found at : " .. " X = " .. cellCoord.X .. " Y = " .. cellCoord.Y)
	-- for loop
	return nil
end

local function grabItemInInventory(player, cellCoord)
	-- Validation
	local inventoryItem = getItemAt(player, cellCoord)

	if not inventoryItem then
		return
	end
end

local function useItem(player, itemDef, itemVisual)
	-- TODO : Check Orb

	if isEquipmentType(itemDef.itemType) then
		print("Equip") -- Spawn on player
		removeFromInventory(player, itemVisual)
		return true
	end

	if isUsable(itemDef.itemType) then
		usablesLogicDefinition[itemDef.name](player, itemDef)
		removeFromInventory(player, itemVisual)
		return true
	end

	return false
end

local function useInventoryItem(player, cellCoord)
	-- Validation
	local inventoryItem = getItemAt(player, cellCoord)

	if not inventoryItem then
		return
	end

	local item = inventoryItem.item
	local itemDef = itemDefinitions[item.definitionId]

	useItem(player, itemDef)
end

-- Per itemType pickup
function ItemService:PickupItem(player, itemModel)
	-- TODO : Validations :
	-- itemModel parent = ManualPickup or AutoPickup -> Only Pickup & Unowned item
	-- Distance item / player

	local definitionId = itemModel:GetAttribute("DefinitionId")
	local itemDefinition = itemDefinitions[definitionId]

	if not itemDefinition then
		warn("Pickup item : itemDefinition not found for " .. itemModel.name)
		return
	end

	print(player.Name .. " Pickup Item : " .. itemDefinition.name)

	-- Orb -> Use
	if itemDefinition.itemType == itemTypes.orb then
		usablesLogicDefinition[itemDefinition.name](player, itemDefinition, itemModel)
		self.Client.GetOrb:Fire(player) -- SFX Feedback
		return
	end

	-- ItemModel to Item Struct
	local item = nil
	local instanceId = nil

	if isInstanceType(itemDefinition.itemType) then
		instanceId = itemModel:GetAttribute("Id")
		item = groundInstanceItems[instanceId]
	else
		item = createItem(definitionId, 1) -- 1 = stack count
	end

	-- Autopickup -> AutoAdd to Inventory
	if isAutoPickupType(itemDefinition.itemType) then
		autoAddFromGround(player, item, itemModel, instanceId)
		return
	end

	-- Manual Pickup
	-- 1) if too far = trigger movement + Pickup
	-- 2) Inventory Open = Set Sprite to mouse, Inventory Closed = AutoAdd to Inventory

	-- TODO
	-- if Inventory Open then
	setItemOnCursor(player, item)
	self:RemoveGroundItem(itemModel, instanceId)
	-- else
	-- autoAddFromGround(player, item, itemModel, instanceId)
end

-- WEAPON : SETUP & EQUIP

local function setWeapon(player, weapon)
	-- print(player.Name .. " new Weapon Data")
	store:dispatch(storeActions.SetWeaponData(player.UserId, weapon))
	PlayerService:ApplyStats(player.UserId)
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

local function onEquipped(weaponModel, weaponData)
	local character = weaponModel.Parent
	local player = Players:GetPlayerFromCharacter(character)
	print("Equip Weapon : " .. player.Name .. " -> " .. weaponModel.Name)

	-- TODO : Check if sounds are available -> Spawn & Delete sounds
	addSounds(player, weaponData)
	setWeapon(player, weaponData)

	weaponData.sounds.unsheath:Play()

	local instanceId = weaponModel:GetAttribute("Id")
	groundInstanceItems[instanceId] = nil

	ItemService.EquipWeapon:Fire()
	-- Signal client > custom tool system
	ItemService.Client.EquipWeapon:Fire(player, true) -- pass weapon?
end

local function onUnequipped(weaponModel)
	if not weaponModel or not weaponModel.Parent then
		return
	end

	local player = weaponModel.Parent.Parent

	if not player then
		return
	end

	print("Unequip Weapon : " .. player.Name .. " -> " .. weaponModel.Name)

	local playerData = store.getState(store).players[player.UserId]

	if not playerData then
		return
	end

	local weaponData = playerData.weaponData

	-- Remove Sounds
	for _, sound in pairs(weaponData.sounds) do
		sound:Destroy()
	end

	-- Reset Data
	setWeapon(player, nil)

	-- Events
	ItemService.UnequipWeapon:Fire(player)
	ItemService.Client.UnequipWeapon:Fire(player)
end

local function SetupWeaponType(weaponType)
	local function setupWeapon(weaponModel)
		if not weaponModel:IsDescendantOf(workspace) then
			return
		end

		print("Setup weapon model : " .. weaponModel.Name)

		local instanceId = weaponModel:GetAttribute("Id")
		local weaponInstance = groundInstanceItems[instanceId]
		local weaponData = nil

		-- Create Data for Pre spawned weapon
		if not weaponInstance then
			local definitionId = weaponModel:GetAttribute("DefinitionId")
			local itemDefinition = itemDefinitions[definitionId]

			local instanceItem = createInstanceItem(itemDefinition, weaponModel)
			setupInstanceItem(instanceItem, weaponModel)
			weaponData = instanceItem.additionalData
		else
			weaponData = groundInstanceItems[instanceId].additionalData
		end

		-- TODO : Use custom tool system
		weaponModel.Equipped:Connect(function()
			onEquipped(weaponModel, weaponData)
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

-- Unit tests

function ItemService:KnitInit()
	print("ItemService Init")

	-- Client ask to pickup item
	self.Client.PickupItem:Connect(function(player, itemModel)
		self:PickupItem(player, itemModel)
	end)

	self.Client.DropCursorItem:Connect(function(player)
		dropCursorItem(player)
	end)

	self.Client.DropInInventory:Connect(function(player, cellCoord)
		dropCursorItemInInventory(player, cellCoord)
	end)

	self.Client.GrabInInventory:Connect(function(player, cellCoord)
		grabItemInInventory(player, cellCoord)
	end)

	self.Client.UseInventoryItem:Connect(function(player, cellCoord)
		useInventoryItem(player, cellCoord)
	end)

	self.ItemStore = itemStore
end

function ItemService:KnitStart()
	PlayerService = Knit.GetService("PlayerService")

	SetupWeaponType("WoodenClub")
	-- SetupWeaponType("IronMace")
	-- SetupWeaponType("IronAxe")
end

return ItemService
