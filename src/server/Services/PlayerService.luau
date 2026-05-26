-- local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages._Index["sleitnick_signal@1.5.0"].signal)

local RoduxStore = require(ReplicatedStorage.Shared.RoduxStore)
local store = RoduxStore.Store
local storeActions = RoduxStore.Actions

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	ScoreChanged = Signal.new(),
	Client = {
		PlayerAdded = Knit.CreateSignal(),
		PlayerRemoved = Knit.CreateSignal(),
		ScoreChanged = Knit.CreateSignal(),
	},
})

-- SERVER FUNCTIONS

function PlayerService:KnitInit()
	print("PlayerService Initialized")
end

function PlayerService:KnitStart()
	-- print("PlayerService Start")
end

function PlayerService:AddPlayer(userId, username)
	store:dispatch(storeActions.AddPlayer(userId, username))
	self.Client.PlayerAdded:FireAll(userId, username)
end

function PlayerService:RemovePlayer(userId)
	store:dispatch(storeActions.RemovePlayer(userId))
	self.Client.PlayerRemoved:FireAll(userId)
end

function PlayerService:GetScore(userId)
	local score = store:getState().players[userId].score
	return if score ~= nil then score else 0
end

function PlayerService:IncrementScore(userId, value)
	store:dispatch(storeActions.IncrementScore(userId, value))
	local newScore = self:GetScore(userId)

	self.Client.ScoreChanged:FireAll(userId, newScore)
end

return PlayerService
