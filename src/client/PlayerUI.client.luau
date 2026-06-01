local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer.PlayerGui

local RoactRodux = require(ReplicatedStorage.Shared.RoactRodux)
local Roact = require(ReplicatedStorage.Shared.Roact)

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await() -- Wait for KnitControllersStart

local PlayerController = Knit.GetController("PlayerController")

local attackSpeedButton = workspace.GetAttackSpeed.SurfaceGui.TextButton

-- IN WORLD UI
-- 1) "Static" = Roblox UI
-- 2) Per Player in world UI (Adornee) = use Roact

attackSpeedButton.MouseButton1Click:Connect(function()
	local PlayerService = Knit.GetService("PlayerService")
	-- PlayerService:AddIncreasedAttackSpeed(Players.LocalPlayer.UserId, 100)
	PlayerService.GiveMeAttackSpeed:Fire()
end)

-- ROACT COMPONENTS

-- Score
-- TODO : Players Score list
local function PlayerScore(props)
	local score = props.score
	local username = props.username

	return Roact.createElement("TextLabel", {
		Text = username .. " Score: " .. score,
		-- TODO : Adaptative size & pos
		-- Size = UDim2.new(0.2, 0, 0.2, 0),
		-- Position = UDim2.new(0.45, 0, 0, 0), -- X_pos = 0.5 (half screen) - size.x / 2
		Size = UDim2.new(1, 0, 0.2, 0),
		BackgroundTransparency = 1,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	})
end

PlayerScore = RoactRodux.connect(function(state, props)
	-- mapStateToProps
	-- print("Local player UserID : ", Players.LocalPlayer.UserId)
	local score = 0
	local username = ""

	if state.players[Players.LocalPlayer.UserId] then
		score = state.players[Players.LocalPlayer.UserId].score
		username = state.players[Players.LocalPlayer.UserId].username
	end

	return {
		score = score,
		username = username,
	}
end)(PlayerScore)

local function ScoreBoard(props)
	local players = props.players
	local playerScores = {}

	for userId, player in pairs(players) do
		playerScores[userId] = Roact.createElement(PlayerScore, {
			score = player.score,
			username = player.username,
		})
	end

	print("User Scores: ")
	print(playerScores)

	return Roact.createElement("Frame", {
		Size = UDim2.new(0.2, 0, 0.5, 0),
		-- Position = UDim2.new(0.8, 0, 0, 0),
		BackgroundTransparency = 0.5,
	}, {
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

local app = Roact.createElement(RoactRodux.StoreProvider, {
	store = PlayerController.store,
}, {
	-- MainGUI
	Roact.createElement("ScreenGui", {}, {
		-- ScoreText = Roact.createElement(PlayerScore),
		ScoreBoard = Roact.createElement(ScoreBoard),
	}),
})

Roact.mount(app, PlayerGui)
