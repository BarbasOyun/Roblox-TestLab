local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer.PlayerGui
local UserInputService = game:GetService("UserInputService")

local RoactRodux = require(ReplicatedStorage.Shared.RoactRodux)
local Roact = require(ReplicatedStorage.Shared.Roact)

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await() -- Wait for KnitControllersStart

local PlayerController = Knit.GetController("PlayerController")

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

	return Roact.createElement("Frame", {
		Size = UDim2.new(0.2, 0, 0.5, 0),
		-- Position = UDim2.new(0.8, 0, 0, 0),
		BackgroundTransparency = 0.5,
	}, {
		Title = Roact.createElement("TextLabel", {
			Text = "Score Board",
			Size = UDim2.new(1, 0, 0.2, 0),
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),
		-- Use Fragment?
		Layout = Roact.createElement("UIListLayout"),
		playerScores = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
		}, playerScores),
	})
end

ScoreBoard = RoactRodux.connect(function(state, props)
	-- mapStateToProps
	local players = state.players

	return {
		players = players,
	}
end)(ScoreBoard)

-- MouseItem
local MouseItem = Roact.Component:extend("MouseItem")

function MouseItem:init()
	self:setState({
		cursorPos = Vector2.new(0, 0),
	})
end

function MouseItem:didMount()
	self.inputConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			self:setState({
				cursorPos = input.Position,
			})
		end
	end)
end

function MouseItem:willUnmount()
	if self.inputConnection then
		self.inputConnection:Disconnect()
	end
end

function MouseItem:render()
	return Roact.createElement("ImageLabel", {
		Position = UDim2.new(0, self.state.cursorPos.X, 0, self.state.cursorPos.Y),
		Size = UDim2.fromOffset(50, 50),
		Image = self.props.imageLink,
		BackgroundTransparency = 1,
	})
end

MouseItem = RoactRodux.connect(function(state, props)
	-- mapStateToProps
	local imageLink = ""
	local playerState = state.players[Players.LocalPlayer.UserId]

	if playerState then
		imageLink = playerState.mouseItem and playerState.mouseItem.imageLink or ""
	end

	return {
		-- position = UDim2.new(0.45, 0, 0, 0),
		-- size = UDim2.new(0.2, 0, 0.2, 0),
		imageLink = imageLink,
	}
end)(MouseItem)

local app = Roact.createElement(RoactRodux.StoreProvider, {
	store = PlayerController.store,
}, {
	-- MainGUI
	Roact.createElement("ScreenGui", {}, {
		-- ScoreText = Roact.createElement(PlayerScoreMain),
		ScoreBoard = Roact.createElement(ScoreBoard),
		MouseItem = Roact.createElement(MouseItem),
	}),
})

Roact.mount(app, PlayerGui)
