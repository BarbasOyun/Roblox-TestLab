-- Roact Getting Started = https://roblox.github.io/roact/guide/installation/

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer.PlayerGui

local Roact = require(ReplicatedStorage.Shared.Roact)

-- COMPONENTS

local Clock = require(ReplicatedStorage.Shared.Components.Clock)

local Greeting = Roact.Component:extend("Greeting")

function Greeting:render()
	return Roact.createElement("TextLabel", {
		Text = "Hello, " .. self.props.name,
		Size = self.props.size,
		Position = self.props.position,
	})
end

local function GreetEveryone()
	return Roact.createElement("ScreenGui", {}, {
		Layout = Roact.createElement("UIListLayout"),

		HelloJoe = Roact.createElement(Greeting, {
			name = "Joe",
			size = UDim2.new(0, 100, 0, 33),
			position = UDim2.new(0.75, 0, 0.5, 0),
		}),

		HelloMary = Roact.createElement(Greeting, {
			name = "Mary",
			size = UDim2.new(0, 100, 0, 33),
			position = UDim2.new(0.75, 0, 0.5, 0),
		}),
	})
end

local function Container(props)
	return Roact.createElement("ScreenGui", {}, {
		Contained = props,
	})
end

local function Button()
	return Roact.createElement("TextButton", {
		Text = "Click me!",
		Size = UDim2.new(0.1, 0, 0.1, 0),
		Position = UDim2.new(0.25, 0, 0.25, 0),

		[Roact.Event.MouseButton1Click] = function(rbx)
			print("The button was clicked!")
		end,
	})
end

-- ELEMENTS

local helloWorld = Roact.createElement("TextLabel", {
	Size = UDim2.new(0, 200, 0, 100),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Text = "Hello, Roact!",
})

local app = Roact.createElement("ScreenGui", {}, {
	-- HelloWorld = helloWorld,
	Button = Button(),
})

local myElement = Roact.createElement("Frame", {
	Size = UDim2.new(0, 0.5, 0, 0.5),
}, {
	-- Create Childs
	SomeChild = Roact.createElement("TextLabel", {
		Size = UDim2.new(0, 100, 0, 100),
		Position = UDim2.new(0, 0, 0, 0),
		Text = "Element 1",
	}),
})

local myNewElement = Roact.createElement("Frame", {}, {
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

-- CREATE INSTANCES

-- Roact.mount(app, PlayerGui)
-- local mainGui = PlayerGui:WaitForChild("RoactTree")

-- local myHandle = Roact.mount(myElement, mainGui)

-- Roact.mount(Container(Button()), mainGui)

-- Component use
-- Roact.mount(hello, mainGui)
-- Roact.mount(GreetEveryone(), mainGui)

-- local handle = Roact.mount(Roact.createElement(Clock), mainGui, "Clock UI")

-- INSTANCES LIFE TIME

-- Roact.unmount(myHandle)
-- myHandle = Roact.update(myHandle, myNewElement)

-- task.wait(10)
-- Roact.unmount(handle)
