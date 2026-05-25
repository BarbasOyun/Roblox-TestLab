--RoactRodux Example : https://roblox.github.io/roact-rodux/guide/usage/

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer.PlayerGui

local Rodux = require(ReplicatedStorage.Shared.Rodux)
local RoactRodux = require(ReplicatedStorage.Shared.RoactRodux)
local Roact = require(ReplicatedStorage.Shared.Roact)

-- RODUX ACTION

local function IncrementAction()
	return {
		type = "IncrementAction",
	}
end

local function TimeAction()
	return {
		type = "TimeAction",
	}
end

-- RODUX REDUCER

local incrementReducer = Rodux.createReducer(0, {
	IncrementAction = function(state, action)
		local newState = state or 0

		newState += 1

		return newState
	end,
})

local timeReducer = Rodux.createReducer(0, {
	TimeAction = function(state, action)
		local newState = state or 0

		newState += 1

		return newState
	end,
})

local reducer = Rodux.combineReducers({
	value = incrementReducer,
	gameTime = timeReducer,
})

local store = Rodux.Store.new(reducer)

-- ROACT COMPONENTS

-- Increment Button
local function IncrementComponent(props)
	-- Values from Rodux can be accessed just like regular props
	local value = props.value
	local onClick = props.onClick

	return Roact.createElement("ScreenGui", nil, {
		Label = Roact.createElement("TextButton", {
			-- ...and used in your components!
			Text = "Current value: " .. value,
			Size = UDim2.new(0.25, 0, 0.25, 0),
			Position = UDim2.new(0, 0, 0.25, 0),

			[Roact.Event.Activated] = onClick,
		}),
	})
end

-- `connect` accepts two optional functions:
-- `mapStateToProps` accepts your store's state and returns props
-- `mapDispatchToProps` accepts a dispatch function and returns props

-- Both functions should return a table containing props that will be passed to
-- your component!

-- `connect` returns a function, so we call that function, passing in our
-- component, getting back a new component!
IncrementComponent = RoactRodux.connect(function(state, props)
	-- mapStateToProps is run every time the store's state updates.
	-- It's also run whenever the component receives new props.
	return {
		value = state.value,
	}
end, function(dispatch)
	-- mapDispatchToProps only runs once, so create functions here!
	return {
		onClick = function()
			dispatch(IncrementAction())
		end,
	}
end)(IncrementComponent)

local Clock = Roact.Component:extend("Clock")

function Clock:render()
	return Roact.createElement("TextLabel", {
		Text = "Time: " .. self.props.gameTime, -- The component just uses props
		Size = UDim2.new(0, 200, 0, 50),
	})
end

-- Create the connected component
local ClockContainer = RoactRodux.connect(function(state, props)
	-- mapStateToProps Clock
	return {
		gameTime = state.gameTime,
	}
end)(Clock)

--[[
-- Rodux store available for any components
local app = Roact.createElement(RoactRodux.StoreProvider, {
	store = store,
}, {
	-- Miss used fragment
	-- MyFragment = Roact.createFragment({
	-- 	IncrementButton = Roact.createElement(IncrementComponent),
	-- 	Clock = Roact.createElement(ClockContainer),
	-- }),

	-- MainGUI
	Roact.createElement("ScreenGui", {}, {
		IncrementButton = Roact.createElement(IncrementComponent),
		Clock = Roact.createElement(ClockContainer),
	}),
})

Roact.mount(app, PlayerGui)

-- LIFETIME : store / GlobalState

while true do
	task.wait(1)
	-- print(store.getState(store))
	store:dispatch(TimeAction())
end
]]
