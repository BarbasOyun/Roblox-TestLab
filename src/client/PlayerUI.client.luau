local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer.PlayerGui

local RoactRodux = require(ReplicatedStorage.Shared.RoactRodux)
local Roact = require(ReplicatedStorage.Shared.Roact)

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await() -- Wait for KnitControllersStart

local PlayerController = Knit.GetController("PlayerController")

local player = Players.LocalPlayer
local attackSpeedButton = workspace.GetAttackSpeed.SurfaceGui.TextButton

-- IN WORLD UI

attackSpeedButton.MouseButton1Click:Connect(function()
	local PlayerService = Knit.GetService("PlayerService")
	PlayerService.GiveMeAttackSpeed:Fire()
end)

-- ROACT COMPONENTS

-- Score
local function PlayerScore(props)
	local position = props.position or UDim2.new(0, 0, 0, 0)
	local size = props.size or UDim2.new(0.2, 0, 0.2, 0)

	local username = props.username or "Player"
	local text = props.text or "Score: "
	local score = props.score or 0

	return Roact.createElement("TextLabel", {
		Text = username .. text .. score,
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	})
end

PlayerScoreMain = RoactRodux.connect(function(state, props)
	-- mapStateToProps
	-- print("Local player UserID : ", Players.LocalPlayer.UserId)
	local score = 0
	local username = ""

	if state.players[Players.LocalPlayer.UserId] then
		score = state.players[Players.LocalPlayer.UserId].score
		username = state.players[Players.LocalPlayer.UserId].username
	end

	return {
		position = UDim2.new(0.45, 0, 0, 0), -- X_pos = 0.5 (half screen) - size.x / 2
		size = UDim2.new(0.2, 0, 0.2, 0),
		username = username,
		score = score,
	}
end)(PlayerScore)

-- ScoreBoard
local function ScoreBoard(props)
	local players = props.players
	local playerScores = {}

	for userId, player in pairs(players) do
		playerScores[userId] = Roact.createElement(PlayerScore, {
			position = UDim2.new(0, 0, 0, 0),
			size = UDim2.new(1, 0, 0.2, 0),
			username = player.username,
			text = ": ",
			score = player.score,
		})
	end

	local playersFragment = Roact.createFragment(playerScores)
	local scoreList = Roact.createElement("Frame", {
		Position = UDim2.fromScale(0, 0.2),
		Size = UDim2.fromScale(1, 0.8),
		BackgroundTransparency = 1,
	}, { Layout = Roact.createElement("UIListLayout"), ListItems = playersFragment })

	return Roact.createElement("Frame", {
		-- Position = UDim2.fromScale(0.8, 0),
		Size = UDim2.fromScale(0.2, 0.7),
		BackgroundTransparency = 0.5,
	}, {
		Title = Roact.createElement("TextLabel", {
			Text = "Score Board",
			Size = UDim2.fromScale(1, 0.2),
			BackgroundTransparency = 0.75,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),
		ScoreList = scoreList,
	})
end

ScoreBoard = RoactRodux.connect(function(state, props)
	-- mapStateToProps
	local players = state.players

	return {
		players = players,
	}
end)(ScoreBoard)

-- Item on Cursor
local CursorItem = require(ReplicatedStorage.Shared.Components.CursorItem)

CursorItem = RoactRodux.connect(function(state, props)
	-- mapStateToProps
	local spriteLink = ""
	local playerState = state.players[player.UserId]

	if playerState then
		spriteLink = playerState.cursorItem and playerState.cursorItem.spriteLink or ""
	end

	-- print("Cursor Item Image Link: " .. spriteLink)

	return {
		spriteLink = spriteLink,
	}
end)(CursorItem)

-- Inventory
local Inventory = require(ReplicatedStorage.Shared.Components.Inventory)

Inventory = RoactRodux.connect(function(state, props)
	local playerState = state.players[player.UserId]

	if playerState then
		return {
			inventory = playerState.inventory,
		}
	end

	return {
		inventory = {},
	}
end)(Inventory)

local PlayerInventory = Roact.Component:extend("PlayerInventory")

function PlayerInventory:render()
	if not self.props.isVisible then
		return nil
	end

	return Roact.createElement("Frame", {
		Position = UDim2.fromScale(0.7, 0.125),
		Size = UDim2.fromScale(0.3, 0.75), -- 30% of screen
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	}, {
		Label = Roact.createElement("TextLabel", {
			Text = "Inventory",
			Size = UDim2.fromScale(1, 0.1),
		}),
		Inventory = Roact.createElement(Inventory, {
			xSize = 0.3,
			ySize = 0.75,
			Position = UDim2.fromScale(0, 0.1),
			cellXSize = 0.095, -- 0.095 -> found using equation described in Inventory:render function
		}),
	})
end

PlayerInventory = RoactRodux.connect(function(state, props)
	local playerState = state.players[player.UserId]

	if playerState then
		return {
			isVisible = playerState.isInventoryOpen,
		}
	end

	return {
		isVisible = false,
	}
end)(PlayerInventory)

-- App
local app = Roact.createElement(RoactRodux.StoreProvider, {
	store = PlayerController.store,
}, {
	-- MainGUI
	Roact.createElement("ScreenGui", {}, {
		-- ScoreText = Roact.createElement(PlayerScoreMain),
		ScoreBoard = Roact.createElement(ScoreBoard),
		PlayerInventory = Roact.createElement(PlayerInventory),
		CursorItem = Roact.createElement(CursorItem),
	}),
})

Roact.mount(app, PlayerGui)
