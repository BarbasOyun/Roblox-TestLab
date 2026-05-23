-- Roact Getting Started = https://roblox.github.io/roact/guide/installation/

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Shared.Roact)
local PlayerGui = Players.LocalPlayer.PlayerGui

-- COMPONENTS

local Greeting = Roact.Component:extend("Greeting")

function Greeting:render()
	return Roact.createElement("TextLabel", {
		Size = UDim2.new(0, 100, 0, 33),
		Position = UDim2.new(0.75, 0, 0.5, 0),
		Text = "Hello, " .. self.props.name,
	})
end

local function GreetEveryone()
	return Roact.createElement("ScreenGui", {}, {
		Layout = Roact.createElement("UIListLayout"),

		HelloJoe = Roact.createElement(Greeting, {
			name = "Joe",
		}),

		HelloMary = Roact.createElement(Greeting, {
			name = "Mary",
		}),
	})
end

local Clock = Roact.Component:extend("Clock")

function Clock:init()
	-- In init, we can use setState to set up our initial component state.
	self:setState({
		currentTime = 0,
	})
end

function Clock:render()
	-- As a convention, we'll pull currentTime out of state right away.
	local currentTime = self.state.currentTime

	return Roact.createElement("ScreenGui", {}, {
		TimeLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(0.5, 0, 0.5, 0),
			Position = UDim2.new(0.25, 0, 0.25, 0),
			Text = "Time Elapsed: " .. currentTime,
		}),
	})
end

-- Set up our loop in didMount, so that it starts running when our
-- component is created.
function Clock:didMount()
	-- Set a value that we can change later to stop our loop
	self.running = true

	-- We don't want to block the main thread, so we spawn a new one!
	task.spawn(function()
		while self.running do
			-- Because we depend on the previous state, we use the function
			-- variant of setState. This will matter more when Roact gets
			-- asynchronous rendering!
			self:setState(function(state)
				return {
					currentTime = state.currentTime + 1,
				}
			end)

			task.wait(1)
		end
	end)
end

-- Stop the loop in willUnmount, so that our loop terminates when the
-- component is destroyed.
function Clock:willUnmount()
	self.running = false
end

local function Container(props)
	return Roact.createElement("ScreenGui", {}, {
		Contained = props,
	})
end

-- ELEMENTS

local app = Roact.createElement("ScreenGui", {}, {
	HelloWorld = Roact.createElement("TextLabel", {
		Size = UDim2.new(0, 400, 0, 300),
		Text = "Hello, Roact!",
	}),
})

local myElement = Roact.createElement("Frame", {
	Size = UDim2.new(0, 0.5, 0, 0.5),
}, {
	-- Create Childs
	SomeChild = Roact.createElement("TextLabel", {
		Size = UDim2.new(0, 1, 0, 1),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Text = "Element 1",
	}),
})

local myNewElement = Roact.createElement("ScreenGui", {}, {
	SomeChild = Roact.createElement("TextLabel", {
		Size = UDim2.new(0, 400, 0, 300),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Text = "Element 2",
	}),
})

local hello = Roact.createElement("ScreenGui", {}, {
	Hello = Roact.createElement(Greeting, {
		name = "Rick James",
	}),
})

local button = Roact.createElement("TextButton", {
	Text = "Click me!",
	Size = UDim2.new(0, 400, 0, 300),

	[Roact.Event.MouseButton1Click] = function(rbx)
		print("The button was clicked!")
	end,
})

-- CREATE INSTANCES

-- Roact.mount(app, PlayerGui)
-- local myHandle = Roact.mount(myElement, PlayerGui)

Roact.mount(Container(button), PlayerGui)

-- Component use
-- Roact.mount(hello, PlayerGui)
Roact.mount(GreetEveryone(), PlayerGui)

local handle = Roact.mount(Roact.createElement(Clock), PlayerGui, "Clock UI")

-- INSTANCES LIFE TIME

-- Roact.unmount(myHandle)
-- myHandle = Roact.update(myHandle, myNewElement)

task.wait(10)
Roact.unmount(handle)
