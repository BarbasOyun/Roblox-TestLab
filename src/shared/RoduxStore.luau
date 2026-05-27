local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gears = require(ReplicatedStorage.Shared.Gears)
local Rodux = require(ReplicatedStorage.Shared.Rodux)

-- Rodux hold a table of players, key = player.UserId
local PLAYER_STRUCT = {
	username = "",
	score = 0,
	inventory = {},
	stats = {},
	weaponData = nil,
	lifeRegenUpdate = nil,
}

-- PlayerStats Data > Move to file
local PLAYER_BASE_STATS = {
	-- Level
	level = 1,
	currentXp = 0,
	increasedXp = 0,
	levelUpXp = 10,
	-- Offensive
	increasedAttackDamage = 0,
	critChance = 5,
	critMultiplier = 50,
	attackSpeed = 0,
	animationTime = 1,
	aoe = 0,
	-- Defensive
	maxLife = 100,
	lifeRegen = 1,
	damageReduction = 0,
	-- Utility
	movementSpeed = 15,
	basePickupRange = 10,
	increasedPickupRange = 0,
	pickupRange = 10,
}

local ITEM_STRUCT = {
	type = 0,
	sprite = nil,
	prefab = nil,
	size_x = 1,
	size_y = 1,
}

local INVENTORY_STRUCT = {
	inventory_space = {}, -- bool flattened array
	items = {}, -- Key = 2D Position
}

-- Default values
local INVENTORY_ROW_SIZE = 10
local INVENTORY_COL_SIZE = 10

-- RODUX ACTIONS

local Actions = {
	-- Players
	AddPlayer = function(userId, username)
		return {
			type = "AddPlayer",
			userId = userId,
			username = username,
		}
	end,

	RemovePlayer = function(userId)
		return {
			type = "RemovePlayer",
			userId = userId,
		}
	end,

	-- Score
	IncrementScore = function(userId, value)
		return {
			type = "IncrementScore",
			userId = userId,
			value = value,
		}
	end,

	SetScore = function(userId, score)
		return {
			type = "SetScore",
			userId = userId,
			score = score,
		}
	end,

	-- Inventory
	AddItem = function(item, position)
		return {
			type = "AddItem",
			item = item,
			position = position,
		}
	end,

	RemoveItem = function(item)
		return {
			type = "RemoveItem",
			item = item,
		}
	end,

	-- Stats

	SetWeaponData = function(userId, weaponData)
		return {
			type = "SetWeaponData",
			userId = userId,
			weaponData = weaponData,
		}
	end,
}

-- RODUX REDUCERS

local playerReducer = Rodux.createReducer({}, {
	-- Players
	AddPlayer = function(state, action)
		local players = table.clone(state) or {} -- Shallow copy the players table
		players[action.userId] = Gears.deepCopy(PLAYER_STRUCT) -- Deep copy the default Player Data
		players[action.userId].username = action.username
		players[action.userId].stats = Gears.deepCopy(PLAYER_BASE_STATS)
		return players
	end,

	RemovePlayer = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId] = nil
		return players
	end,

	-- Score
	IncrementScore = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId].score += action.value

		return players
	end,

	SetScore = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId].score = action.score

		return players
	end,

	-- Inventory
	AddItem = function(state, action)
		local players = {}

		-- TODO

		return players
	end,

	RemoveItem = function(state, action)
		local players = {}

		-- TODO

		return players
	end,

	-- Stats
	SetWeaponData = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId].weaponData = action.weaponData
		return players
	end,
})

-- STORE

local reducer = Rodux.combineReducers({
	players = playerReducer,
	-- Other game data
})

local store = Rodux.Store.new(reducer, nil, {
	Rodux.loggerMiddleware,
})

return {
	Store = store,
	Actions = Actions,
}
