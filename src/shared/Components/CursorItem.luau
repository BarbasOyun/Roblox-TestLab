local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.Shared.Roact)

local CursorItem = Roact.Component:extend("CursorItem")

function CursorItem:init()
	self:setState({
		cursorPos = Vector2.new(0, 0),
	})
end

function CursorItem:didMount()
	self.inputConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if self.props.imageLink and input.UserInputType == Enum.UserInputType.MouseMovement then
			self:setState({
				cursorPos = input.Position,
			})
		end
	end)
end

function CursorItem:willUnmount()
	if self.inputConnection then
		self.inputConnection:Disconnect()
	end
end

function CursorItem:render()
	local imageLink = self.props.imageLink

	local sizeX = 0.1
	local sizeY = 0.1

	local width = game.Workspace.CurrentCamera.ViewportSize.X
	local height = game.Workspace.CurrentCamera.ViewportSize.Y

	local offsetX = self.state.cursorPos.X - width * sizeX / 2
	local offsetY = self.state.cursorPos.Y - height * sizeY / 2

	return Roact.createElement("ImageLabel", {
		Position = UDim2.fromOffset(offsetX, offsetY),
		Size = UDim2.fromScale(sizeX, sizeY),
		ZIndex = 10, -- Always on top
		Image = imageLink,
		BackgroundTransparency = 1,
	})
end

return CursorItem
