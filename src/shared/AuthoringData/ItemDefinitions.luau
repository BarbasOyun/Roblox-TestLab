local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ITEM SYSTEM DESIGN
-- Endgame setup = csv file

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

	--[[
	["IronMace"] = {
		weaponType = "Mace",
		damage = 35,
		attackSpeed = 0.8,
		range = 8,
	},
	["IronSword"] = {
		weaponType = "Sword",
		damage = 20,
		attackSpeed = 1,
		range = 6,
	},
	["IronAxe"] = {
		weaponType = "Axe",
		damage = 30,
		attackSpeed = 1,
		range = 7,
	},
    ]]

	-- Gear
	{
		id = 5,
		name = "Iron Body Armor",
		itemType = "Gear",
		toolTipText = "Iron Body Armor",
		gearType = "Body",
		armor = 10, -- Defense type = armor, evasion, ...
	},
}

-- Item name to ID
local itemStore = {
	Banana = 1,
	SmallXpOrb = 2,
	Stick = 3,
	WoodenClub = 4,
	IronBodyArmor = 5,
}

local equipmentTypeDefinitions = {
	["Mace"] = {
		gridSizeX = 2,
		gridSizeY = 6,
	},
	["Body"] = {
		gridSizeX = 2,
		gridSizeY = 6,
	},
	-- Two-handed Mace
	-- One-handed Sword
	-- ...
}

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
	["Usable"] = { itemTypeTags.Defined, itemTypeTags.Manual },
	["AutoPickupUsable"] = { itemTypeTags.Defined, itemTypeTags.Auto },
	["Orb"] = { itemTypeTags.Defined, itemTypeTags.Auto },
	["Reagent"] = { itemTypeTags.Defined, itemTypeTags.Manual },
	["AutoPickupReagent"] = { itemTypeTags.Defined, itemTypeTags.Auto },
	["Weapon"] = { itemTypeTags.Instance, itemTypeTags.Manual },
	["Gear"] = { itemTypeTags.Instance, itemTypeTags.Manual },
}

local itemVisualDefinitions = {
	{ ReplicatedStorage.Shared.Prefabs.Banana, "rbxassetid://102081417185866" }, -- eg id 0 = Banana Prefab + Sprite
	{ ReplicatedStorage.Shared.Prefabs.SmallXpOrb }, -- Orbs don't use Sprite
	{ ReplicatedStorage.Shared.Prefabs.Stick, "rbxassetid://109738929660031" },
	{ ReplicatedStorage.Shared.Prefabs.WoodenClub, "rbxassetid://139246229160408" },
	{ ReplicatedStorage.Shared.Prefabs.IronBodyArmor },
}

return {
	itemDefinitions = itemDefinitions,
	itemStore = itemStore,
	equipmentTypeDefinitions = equipmentTypeDefinitions,
	itemTypes = itemTypes,
	itemTypeTags = itemTypeTags,
	itemTypeDefinition = itemTypeDefinition,
	itemVisualDefinitions = itemVisualDefinitions,
}
