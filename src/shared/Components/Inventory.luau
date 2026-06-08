local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.Shared.Roact)

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await() -- Wait for KnitControllersStart

local PlayerController = Knit.GetController("PlayerController")

-- Inventory
local Inventory = Roact.Component:extend("Inventory")

function Inventory:init()
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

	local inventory = self.props.inventory

	self:setState({
		cellCount = inventory.cellCount,
		columns = inventory.columns,
		rows = inventory.rows,
		items = inventory.items,
	})
end

function Inventory:getCellSize()
	local width = game.Workspace.CurrentCamera.ViewportSize.X
	local cellSize = math.round(width * self.props.cellXSize * self.props.xSize) -- eg PlayerInventory = 30% of screen -> 0.095 * 0.3 = 0.0285 * width = cellSize in Pixels
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

	local inventoryCoordX = math.min(math.floor(localX / totalCellSize), self.state.columns - 1)
	local inventoryCoordY = math.min(math.floor(localY / totalCellSize), self.state.rows - 1)
	local inventoryCoord = Vector2.new(inventoryCoordX, inventoryCoordY)

	return inventoryCoord
end

function Inventory:renderGrid()
	local inventoryCells = {}

	-- Placing cells + offsets in a frame :
	-- Goal = find cellSize for perfect fit
	-- x = cellSize, y = columns, z = offset, total row space = 1
	-- 1 = x * y + x * z * y -> Solve equation for x

	-- eg :
	-- y = 10, z = 0.05
	-- 1 = x * 10 + x * 0.05 * 10 -> 1 = 10x + .5x
	-- -> x = 1 / 10.5 = 0.095

	local cellCount = self.state.cellCount
	local columns = self.state.columns -- columns = cells / row
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

	local inventoryGrid = Roact.createElement("Frame", {
		-- Name = "InventoryGrid",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, inventoryCells)

	return inventoryGrid
end

function Inventory:renderItems()
	-- local items = self.props.items
	local items = self.state.items
	local itemsSprites = {}

	local cellSize, cellOffset = self:getCellSize()

	for i, item in pairs(items) do
		local spriteLink = item.spriteLink

		-- TODO : use addition for perfect placement
		local xPos = item.cellCoord.X * cellSize + item.cellCoord.X * cellOffset
		local yPos = item.cellCoord.Y * cellSize + item.cellCoord.Y * cellOffset

		local xSize = item.itemGridSize.X * cellSize + item.itemGridSize.X * cellOffset
		local ySize = item.itemGridSize.Y * cellSize + item.itemGridSize.Y * cellOffset

		itemsSprites[i] = Roact.createElement("ImageLabel", {
			Position = UDim2.fromOffset(xPos, yPos),
			Size = UDim2.fromOffset(xSize, ySize),
			ZIndex = 2,
			Image = spriteLink,
			BackgroundTransparency = 0.75,
		})
	end

	local inventoryItems = Roact.createElement("Frame", {
		-- Name = "InventoryItems", -- doesn't work
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, itemsSprites)

	return inventoryItems
end

function Inventory:render()
	local inventoryGrid = self:renderGrid()
	local inventoryItems = self:renderItems()

	return Roact.createElement("Frame", {
		Position = self.props.Position,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		-- [Roact.Event.InputBegan] = function(rbx, input)
		-- 	-- Grab item
		-- 	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- 		local cellCoord = self:screenToInventoryCell(rbx, input.Position)
		-- 		print("Left Click PRESSED in Inventory at : " .. "X = " .. cellCoord.X .. " Y = " .. cellCoord.Y)
		-- 		PlayerController:GrabItemInInventory(cellCoord)
		-- 	end
		-- end,
		[Roact.Event.InputEnded] = function(rbx, input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local cellCoord = self:screenToInventoryCell(rbx, input.Position)
				print("Left Click RELEASED in Inventory at : " .. "X = " .. cellCoord.X .. " Y = " .. cellCoord.Y)
				PlayerController:DropItemInInventory(cellCoord)
				-- Grab Item
				PlayerController:GrabItemInInventory(cellCoord)
			end

			-- Use Item
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				local cellCoord = self:screenToInventoryCell(rbx, input.Position)
				print("RClick RELEASED in Inventory at : " .. "X = " .. cellCoord.X .. " Y = " .. cellCoord.Y)
				PlayerController:UseItemInInventory(cellCoord)
			end
		end,
	}, { inventoryGrid, inventoryItems })
end

return Inventory
