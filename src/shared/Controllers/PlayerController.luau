local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
--  Signal = require(ReplicatedStorage.Packages._Index["sleitnick_signal@1.5.0"].signal)

local RoduxStore = require(ReplicatedStorage.Shared.RoduxStore)
local store = RoduxStore.Store -- Client side store -> Custom Client store?
local storeActions = RoduxStore.Actions

local PlayerController = Knit.CreateController({ Name = "PlayerController" })

PlayerController.store = store

function PlayerController:KnitInit()
	print("PlayerController Init")

	local PlayerService = Knit.GetService("PlayerService")

	PlayerService.PlayerAdded:Connect(function(userId)
		print("Player Added = " .. userId)

		-- Replicate Action Client side
		store:dispatch(storeActions.AddPlayer(userId))
	end)

	-- When other players leave
	PlayerService.PlayerRemoved:Connect(function(userId)
		print("Player Removed = " .. userId)
		store:dispatch(storeActions.RemovePlayer(userId))
	end)

	PlayerService.ScoreChanged:Connect(function(userId, newScore)
		print("Player = " .. userId .. " Score Chnaged to : " .. newScore)

		-- Update Score instead of Increment
		store:dispatch(storeActions.UpdateScore(userId, newScore))
	end)
end

function PlayerController:KnitStart()
	print("PlayerController Start")
end

return PlayerController
