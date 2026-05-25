-- Create Client side Rodux store :
-- 1) Score
-- 2) Inventory
-- Dumb Inventory > Only hold items data copy & UI Positions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer.PlayerGui

local Rodux = require(ReplicatedStorage.Shared.Rodux)
local RoactRodux = require(ReplicatedStorage.Shared.RoactRodux)
local Roact = require(ReplicatedStorage.Shared.Roact)

-- RODDUX ACTIONS

local function IncrementScore()
	return {
		type = "IncrementScore",
	}
end

local function AddItem(item, position)
	return {
		type = "AddItem",
		item = item,
		position = position,
	}
end

local function RemoveItem(item)
	return {
		type = "RemoveItem",
		item = item,
	}
end

-- RODUX REDUCERS

local incrementScoreReducer = Rodux.createReducer(0, {
	IncrementScore = function(state, action)
		local newState = state or 0

		newState += 1

		return newState
	end,
})

local inventoryReducer = Rodux.createReducer({}, {
	AddItemAction = function(state, action)
		local newState = state or {}

		newState[action.position] = action.item

		return newState
	end,

	RemoveItemAction = function(state, action)
		local newState = state or {}

		table.remove(newState, table.find(newState, action.item))

		return newState
	end,
})

local reducer = Rodux.combineReducers({
	score = incrementScoreReducer,
	inventory = inventoryReducer,
})

local store = Rodux.Store.new(reducer)

-- ROACT COMPONENTS

-- Score
local function ScoreComponent(props)
	local score = props.score

	return Roact.createElement("TextLabel", {
		Text = "Score: " .. score,
		Size = UDim2.new(0.1, 0, 0.1, 0),
		Position = UDim2.new(0.45, 0, 0, 0), -- 0.5 - size.x / 2
		BackgroundTransparency = 1,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	})
end

ScoreComponent = RoactRodux.connect(function(state, props)
	-- mapStateToProps
	return {
		score = state.score,
	}
end)(ScoreComponent)

local app = Roact.createElement(RoactRodux.StoreProvider, {
	store = store,
}, {
	-- MainGUI
	Roact.createElement("ScreenGui", {}, {
		ScoreText = Roact.createElement(ScoreComponent),
	}),
})

Roact.mount(app, PlayerGui)
