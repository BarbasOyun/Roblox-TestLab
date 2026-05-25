-- Rodux Example : https://roblox.github.io/rodux/example/
-- Can also be used Server Side

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Shared.Rodux)

-- Action creator for the ReceivedNewPhoneNumber action
local function ReceivedNewPhoneNumber(phoneNumber)
	return {
		type = "ReceivedNewPhoneNumber",
		phoneNumber = phoneNumber,
	}
end

-- Action creator for the MadeNewFriends action
local function MadeNewFriends(listOfNewFriends)
	return {
		type = "MadeNewFriends",
		newFriends = listOfNewFriends,
	}
end

-- Reducer for the current user's phone number
local phoneNumberReducer = Rodux.createReducer("", {
	ReceivedNewPhoneNumber = function(state, action)
		return action.phoneNumber
	end,
})

-- Reducer for the current user's list of friends
local friendsReducer = Rodux.createReducer({}, {
	MadeNewFriends = function(state, action)
		local newState = {}

		-- Since state is read-only, we copy it into newState
		for index, friend in ipairs(state) do
			newState[index] = friend
		end

		for _, friend in ipairs(action.newFriends) do
			table.insert(newState, friend)
		end

		return newState
	end,
})

local reducer = Rodux.combineReducers({
	myPhoneNumber = phoneNumberReducer,
	myFriends = friendsReducer,
})

local store = Rodux.Store.new(reducer, nil, {
	-- Rodux.loggerMiddleware,
})

--[[
store:dispatch(ReceivedNewPhoneNumber("12345678"))
store:dispatch(MadeNewFriends({
	"Cassandra",
	"Joe",
}))
]]

--[[
    Expected output to the developer console:

    Action dispatched: {
        phoneNumber = "12345678" (string)
        type = "ReceivedNewPhoneNumber" (string)
    }
    State changed to: {
        myPhoneNumber = "12345678" (string)
        myFriends = {
        }
    }
    Action dispatched: {
        newFriends = {
            1 = "Cassandra" (string)
            2 = "Joe" (string)
        }
        type = "MadeNewFriends" (string)
    }
    State changed to: {
        myPhoneNumber = "12345678" (string)
        myFriends = {
            1 = "Cassandra" (string)
            2 = "Joe" (string)
        }
    }
]]

-- EQUIVALENT :

--[[
local phoneNumberReducer = function(state, action)
    if action.type == "ReceivedNewPhoneNumber" then
        return action.phoneNumber
    end

    return state
end
]]

--[[
local friendsReducer = function(state, action)
        -- The state might be nil the first time this reducer is executed.
        -- In that case, we need to initialize our state to be the empty table.
    state = state or {}

    if action.type == "MadeNewFriends" then
        local newState = {}

        -- Since state is read-only, we copy it into newState
        for index, friend in ipairs(state) do
            newState[index] = friend
        end

        for _, friend in ipairs(action.newFriends)
            table.insert(newState, friend)
        end

        return newState
    end

    return state
end
]]

--[[
    note that the reducer for our entire application is defined by a table of
    sub-reducers where each sub-reducer is responsible for one portion of the
    overall state.

local reducer = function(state, action)
    return {
        myPhoneNumber = phoneNumberReducer(state.myPhoneNumber, action),
        myFriends = friendsReducer(state.myFriends, action),
    }
end
]]
