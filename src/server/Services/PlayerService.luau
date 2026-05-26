-- local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gears = require(ReplicatedStorage.Shared.Gears)
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

-- STATS > Move to CombatService?

local playerStatsCalculation = {} -- Fill with functions

function PlayerService.CalculateAllStats(userId)
	for _, calculateStat in ipairs(playerStatsCalculation) do
		calculateStat(userId)
	end
end

function PlayerService:ApplyStats(userId)
	-- TODO
	-- Make the current stats effective
	-- Send to Client -> Display on stats screen
end

function PlayerService.AddXpToPlayer(player, xp)
	-- print(player.Name .. " Gained : " .. xp .. " XP")
	-- local playerStat = playersStats[player.UserId]
	-- playerStat.currentXp.Value += xp * Gears.increaseToMultiplier(playerStat.increasedXp)

	-- if playerStat.currentXp.Value >= playerStat.levelUpXp.Value then
	-- 	playersStats.LevelUp(player, playerStat)
	-- end
end

function PlayerService.LevelUp(player, playerStat)
	-- Compute XP
	-- local overXp = playerStat.currentXp.Value - playerStat.levelUpXp.Value
	-- playerStat.waitingLevel += 1
	-- playerStat.currentXp.Value = 0
	-- playerStat.levelUpXp.Value *= 1.1
	-- print(player.Name .. " Leveled Up")

	-- playersStats.SendAugment(player, playerStat)
	-- levelUpEvent:FireClient(player, playerStat.level, playerStat.waitingLevel)

	-- playersStats.AddXpToLvl(player, overXp)
end

return PlayerService
