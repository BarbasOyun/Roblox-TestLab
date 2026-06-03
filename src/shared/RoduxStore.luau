local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gears = require(ReplicatedStorage.Shared.Gears)
local Rodux = require(ReplicatedStorage.Shared.Rodux)

-- TODO : Move to PlayerService
-- Rodux store hold a table of players
-- key = player.UserId
local PLAYER_STRUCT = {
	username = "",
	score = 0,
	inventory = {},
	cursorItem = nil, -- Item on cursor
	stats = nil,
	weaponData = nil,
	-- gearData
}

-- 1) Define PlayerStats struct
-- 2) Authoring Data > Move to file
-- TODO : Change keys to strings -> Common access
local PLAYER_STATS_STRUCT = {
	-- Level
	level = 1,
	currentXp = 0,
	increasedXp = 0,
	levelUpXp = 10,
	-- Offensive
	increasedAttackDamage = 0,
	attackDamage = 0,
	critChance = 5,
	critMultiplier = 50,
	increasedAttackSpeed = 0,
	attackSpeed = 0, -- Attacks / Second
	animationTime = 1, -- Get lower as attackSpeed get higher
	increasedAoe = 0,
	aoe = 0,
	-- Defensive
	-- baseLife = 100
	-- increasedLife = 0
	maxLife = 100,
	life = 100,
	lifeRegen = 1,
	damageReduction = 0,
	-- Utility
	movementSpeed = 15,
	manualPickupRange = 5,
	basePickupRange = 10,
	increasedPickupRange = 0,
	pickupRange = 10,
}

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
	SetScore = function(userId, score)
		return {
			type = "SetScore",
			userId = userId,
			score = score,
		}
	end,

	-- Inventory
	SetCursorItem = function(userId, item)
		return {
			type = "SetCursorItem",
			userId = userId,
			cursorItem = item,
		}
	end,

	AddItemToInventory = function(userId, item, position)
		return {
			type = "AddItemToInventory",
			userId = userId,
			item = item,
			position = position,
		}
	end,

	RemoveItemFromInventory = function(userId, item)
		return {
			type = "RemoveItemFromInventory",
			userId = userId,
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

	SetAttackDamage = function(userId, attackDamage)
		return {
			type = "SetAttackDamage",
			userId = userId,
			attackDamage = attackDamage,
		}
	end,

	SetIncreasedAttackSpeed = function(userId, increasedAttackSpeed)
		return {
			type = "SetIncreasedAttackSpeed",
			userId = userId,
			increasedAttackSpeed = increasedAttackSpeed,
		}
	end,

	SetAttackSpeed = function(userId, attackSpeed, animationTime)
		return {
			type = "SetAttackSpeed",
			userId = userId,
			attackSpeed = attackSpeed,
			animationTime = animationTime,
		}
	end,

	SetAoe = function(userId, aoe)
		return {
			type = "SetAoe",
			userId = userId,
			aoe = aoe,
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
		players[action.userId].stats = Gears.deepCopy(PLAYER_STATS_STRUCT)
		-- players[action.userId].inventory = Gears.deepCopy(INVENTORY_STRUCT)
		return players
	end,

	RemovePlayer = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId] = nil
		return players
	end,

	-- Score
	SetScore = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId].score = action.score

		return players
	end,

	-- Inventory
	SetCursorItem = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId].cursorItem = action.cursorItem

		return players
	end,

	AddItemToInventory = function(state, action)
		local players = {}

		-- TODO
		-- if action.position == nil -> auto add to inventory

		return players
	end,

	RemoveItemFromInventory = function(state, action)
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

	SetAttackDamage = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId].stats.attackDamage = action.attackDamage
		return players
	end,

	SetIncreasedAttackSpeed = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId].stats.increasedAttackSpeed = action.increasedAttackSpeed
		return players
	end,

	SetAttackSpeed = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId].stats.attackSpeed = action.attackSpeed
		players[action.userId].stats.animationTime = action.animationTime
		return players
	end,

	SetAoe = function(state, action)
		local players = table.clone(state) or {}
		players[action.userId].stats.aoe = action.aoe
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
