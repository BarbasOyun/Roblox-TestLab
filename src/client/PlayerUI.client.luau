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
	local imageLink = ""
	local playerState = state.players[player.UserId]

	if playerState then
		imageLink = playerState.cursorItem and playerState.cursorItem.imageLink or ""
	end

	-- print("Cursor Item Image Link: " .. imageLink)

	return {
		imageLink = imageLink,
	}
end)(CursorItem)

-- Inventory
local function inventoryCells(props)
	local inventoryCells = {}

	-- Placing cells + offset in a frame :
	-- Goal = find cellSize for perfect fit
	-- x = cellSize, y = cellPerRow, z = offset, total row space = 1
	-- Solve equation -> 1 = x * y + x * z * y

	-- eg :
	-- y = 10, z = 0.05
	-- 1 = x * 10 + x * 0.05 * 10
	-- -> x = 0.95

	local cellCount = props.cellCount
	local cellPerRow = props.cellPerRow

	local width = game.Workspace.CurrentCamera.ViewportSize.X

	local cellXSize = width * 0.0285 -- Inventory = 30% of screen -> 0.95 * 0.3 = 0.0285
	local cellOffSet = cellXSize * 0.05 -- 5%

	for i = 0, cellCount - 1, 1 do
		local x = i % cellPerRow
		local y = i // cellPerRow

		local xPos = x * cellXSize + cellOffSet * x + cellOffSet
		local yPos = y * cellXSize + cellOffSet * y + cellOffSet

		inventoryCells[i] = Roact.createElement("Frame", {
			Position = UDim2.fromOffset(math.ceil(xPos), math.ceil(yPos)),
			Size = UDim2.fromOffset(cellXSize, cellXSize),
		})
	end

	print(inventoryCells)

	return Roact.createElement("Frame", {
		Position = UDim2.fromScale(0, 0.1),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, inventoryCells)
end

local Inventory = Roact.Component:extend("Inventory")

function Inventory:render()
	if not self.props.isVisible then
		return nil
	end

	return Roact.createElement("Frame", {
		Position = UDim2.fromScale(0.7, 0.125),
		Size = UDim2.fromScale(0.3, 0.75),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	}, {
		Label = Roact.createElement("TextLabel", {
			Text = "Inventory",
			Size = UDim2.fromScale(1, 0.1),
		}),
		InventoryCells = inventoryCells({
			cellCount = self.props.cellCount,
			cellPerRow = self.props.cellPerRow,
		}),
	})
end

Inventory = RoactRodux.connect(function(state, props)
	local playerState = state.players[player.UserId]

	local isOpen = false
	local cellCount = 0
	local cellPerRow = 0

	if playerState then
		isOpen = playerState.isInventoryOpen
		cellCount = playerState.inventory.cellCount
		cellPerRow = playerState.inventory.cellPerRow
	end

	return {
		isVisible = isOpen,
		cellCount = cellCount,
		cellPerRow = cellPerRow,
	}
end)(Inventory)

local app = Roact.createElement(RoactRodux.StoreProvider, {
	store = PlayerController.store,
}, {
	-- MainGUI
	Roact.createElement("ScreenGui", {}, {
		-- ScoreText = Roact.createElement(PlayerScoreMain),
		ScoreBoard = Roact.createElement(ScoreBoard),
		Inventory = Roact.createElement(Inventory),
		CursorItem = Roact.createElement(CursorItem),
	}),
})

Roact.mount(app, PlayerGui)
