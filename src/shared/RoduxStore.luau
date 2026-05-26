local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gears = require(ReplicatedStorage.Shared.Gears)
local Rodux = require(ReplicatedStorage.Shared.Rodux)

-- Rodux hold a table of players, key = player.UserId
local PLAYER_STRUCT = {
	username = "",
	score = 0,
	inventory = {},
}

local INVENTORY_ROW_SIZE = 10

local ITEM_STRUCT = {
	type = 0,
	sprite = nil,
	prefab = nil,
	size_x = 1,
	size_y = 1,
}

-- RODUX ACTIONS

local Actions = {
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

	IncrementScore = function(userId, value)
		return {
			type = "IncrementScore",
			userId = userId,
			value = value,
		}
	end,

	UpdateScore = function(userId, score)
		return {
			type = "UpdateScore",
			userId = userId,
			score = score,
		}
	end,

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
}

-- RODUX REDUCERS

local playerReducer = Rodux.createReducer({}, {
	AddPlayer = function(state, action)
		local newState = table.clone(state) or {} -- Shallow copy the players table
		newState[action.userId] = Gears.deepCopy(PLAYER_STRUCT) -- Deep copy the default Player Data
		newState[action.userId].username = action.username
		return newState
	end,

	RemovePlayer = function(state, action)
		local newState = table.clone(state) or {}
		newState[action.userId] = nil
		return newState
	end,

	IncrementScore = function(state, action)
		local newState = table.clone(state) or {}
		newState[action.userId].score += action.value

		return newState
	end,

	UpdateScore = function(state, action)
		local newState = table.clone(state) or {}
		newState[action.userId].score = action.score

		return newState
	end,

	AddItem = function(state, action)
		local newState = {}

		-- TODO

		return newState
	end,

	RemoveItem = function(state, action)
		local newState = {}

		-- TODO

		return newState
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
