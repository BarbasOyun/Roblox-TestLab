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
local Inventory = Roact.Component:extend("Inventory")

function Inventory:init()
	local rowCount = math.floor(self.props.cellCount / self.props.columns)

	-- 2 Ways of holding cellSize
	-- 1) %
	-- 2) Pixels
	-- Pixels > % -> Pixel values needed in screenToInventoryCell function

	-- 1) Calculate % ySize of a cell
	--[[
	local width = game.Workspace.CurrentCamera.ViewportSize.X
	local height = game.Workspace.CurrentCamera.ViewportSize.Y
	local xSize = self.props.xSize
	local ySize = self.props.ySize

	local inventoryXPixelSize = width * xSize
	local inventoryYPixelSize = height * ySize
	local inventoryRatio = inventoryXPixelSize / inventoryYPixelSize

	local cellXSize = self.props.cellXSize -- % size of inventory
	local cellYSize = cellXSize * inventoryRatio -- cells are squares

	local cellOffset = cellXSize * 0.05 -- offset = 5% of a cell
	]]

	self:setState({
		rowCount = rowCount,
	})
end

function Inventory:getCellSize()
	local width = game.Workspace.CurrentCamera.ViewportSize.X
	local cellSize = math.round(width * self.props.cellXSize * self.props.xSize) -- Inventory = 30% of screen -> 0.095 * 0.3 = 0.0285 * width = cellSize in Pixels
	local cellOffset = math.round(cellSize * 0.05) -- 5%

	return cellSize, cellOffset
end

function Inventory:screenToInventoryCell(inventory, mousePos)
	local inventoryFramePos = inventory.AbsolutePosition

	-- MousePos inside Inventory
	local localX = mousePos.X - inventoryFramePos.X
	local localY = mousePos.Y - inventoryFramePos.Y

	local cellSize, cellOffset = self:getCellSize()
	local totalCellSize = cellSize + cellOffset

	local inventoryCoordX = math.min(math.floor(localX / totalCellSize), self.props.columns - 1)
	local inventoryCoordY = math.min(math.floor(localY / totalCellSize), self.state.rowCount - 1)
	local inventoryCoord = Vector2.new(inventoryCoordX, inventoryCoordY)

	return inventoryCoord
end

function Inventory:render()
	local inventoryCells = {}

	-- Placing cells + offsets in a frame :
	-- Goal = find cellSize for perfect fit
	-- x = cellSize, y = columns, z = offset, total row space = 1
	-- 1 = x * y + x * z * y -> Solve equation for x

	-- eg :
	-- y = 10, z = 0.05
	-- 1 = x * 10 + x * 0.05 * 10 -> 1 = 10x + .5x
	-- -> x = 1 / 10.5 = 0.095

	local cellCount = self.props.cellCount
	local columns = self.props.columns -- columns = cells / row
	local cellSize, cellOffset = self:getCellSize()

	--[[ Multiplication
	for i = 0, cellCount - 1, 1 do
		local x = i % columns
		local y = i // columns

		local xPos = x * cellSize + cellOffset * x + cellOffset
		local yPos = y * cellSize + cellOffset * y + cellOffset

		inventoryCells[i] = Roact.createElement("Frame", {
			Position = UDim2.fromOffset(xPos, yPos),
			Size = UDim2.fromOffset(cellSize, cellSize),
		})
	end
	]]

	-- Addition
	local lastXPos = cellOffset - cellSize
	local yPos = -cellSize

	for i = 0, cellCount - 1, 1 do
		local x = i % columns

		-- start of a row
		if x == 0 then
			lastXPos = cellOffset - cellSize
			yPos += cellSize + cellOffset
		end

		local xPos = lastXPos + cellOffset + cellSize
		lastXPos = xPos

		inventoryCells[i] = Roact.createElement("Frame", {
			-- using fromScale leads to visual artifacts
			Position = UDim2.fromOffset(xPos, yPos),
			Size = UDim2.fromOffset(cellSize, cellSize),
		})
	end

	return Roact.createElement("Frame", {
		Position = self.props.Position,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[Roact.Event.InputBegan] = function(rbx, input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local cellCoord = self:screenToInventoryCell(rbx, input.Position)
				print("Left Click Pressed in Inventory at Pos : ")
				print(cellCoord)
				PlayerController:GrabItemInInventory(cellCoord)
			end
		end,
		[Roact.Event.InputEnded] = function(rbx, input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local cellCoord = self:screenToInventoryCell(rbx, input.Position)
				print("Left Click Released in Inventory at Pos : ")
				print(cellCoord)
				PlayerController:DropItemInInventory(cellCoord)
			end
		end,
	}, inventoryCells)
end

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
			cellCount = self.props.cellCount,
			columns = self.props.columns,
			xSize = 0.3,
			ySize = 0.75,
			Position = UDim2.fromScale(0, 0.1),
			cellXSize = 0.095, -- 0.095 -> found using equation described in Inventory:render function
		}),
	})
end

PlayerInventory = RoactRodux.connect(function(state, props)
	local playerState = state.players[player.UserId]

	local isOpen = false
	local cellCount = 0
	local columns = 0

	if playerState then
		isOpen = playerState.isInventoryOpen
		cellCount = playerState.inventory.cellCount
		columns = playerState.inventory.columns
	end

	return {
		isVisible = isOpen,
		cellCount = cellCount,
		columns = columns,
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
