local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxStore = require(ReplicatedStorage.Shared.RoduxStore)
local store = RoduxStore.Store
local storeActions = RoduxStore.Actions

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await()

local PlayerService = Knit.GetService("PlayerService")

Players.PlayerAdded:Connect(function(player)
	local userId = player.UserId

	PlayerService:AddPlayer(userId, player.Name)

	PlayerService:IncrementScore(userId, 1)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	PlayerService:RemovePlayer(userId)
end)
