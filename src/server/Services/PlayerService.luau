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
	PlayerAdded = Signal.new(),
	PlayerRemoved = Signal.new(),
	Client = {
		PlayerAdded = Knit.CreateSignal(),
		PlayerRemoved = Knit.CreateSignal(),
		ScoreChanged = Knit.CreateSignal(),
	},
})

local lifeRegenUpdates = {} -- per player

-- SERVER FUNCTIONS

function PlayerService:KnitInit()
	print("PlayerService Initialized")
end

function PlayerService:KnitStart()
	-- print("PlayerService Start")
end

-- Players
function PlayerService:AddPlayer(userId, username)
	store:dispatch(storeActions.AddPlayer(userId, username))

	-- Events
	self.PlayerAdded:Fire(userId)
	self.Client.PlayerAdded:FireAll(userId, username)
end

function PlayerService:RemovePlayer(userId)
	store:dispatch(storeActions.RemovePlayer(userId))

	-- Events
	self.PlayerRemoved:Fire(userId)
	self.Client.PlayerRemoved:FireAll(userId)
end

-- Score
function PlayerService:GetScore(userId)
	local score = store:getState().players[userId].score
	return if score ~= nil then score else 0
end

function PlayerService:IncrementScore(userId, value)
	local score = self:GetScore(userId)
	local newScore = score + value
	store:dispatch(storeActions.SetScore(userId, newScore))

	-- Replicate to Clients
	self.Client.ScoreChanged:FireAll(userId, newScore)
end

-- STATS > Move to Combat/Stats Service?
-- Most Stats work like this : baseX * increasedX = x
-- some baseX (eg attackSpeedBase) come from weaponData
-- every used / final x stats is stored in the playerStats (weaponData never mutate)

-- TODO : Global access
local function getStoreData(userId)
	local storeState = store.getState(store)
	local playerStats = storeState.players[userId].stats
	local weaponData = storeState.players[userId].weaponData

	return playerStats, weaponData
end

local playerStatsCalculation = { -- Fill with functions
	calculateAttackDamage = function(userId)
		local playerStats, weaponData = getStoreData(userId)

		if not playerStats or not weaponData then
			return
		end

		-- baseAttackDamage = weaponData.damage
		local attackDamage = weaponData.damage * Gears.increaseToMultiplier(playerStats.increasedAttackDamage)

		store:dispatch(storeActions.SetAttackDamage(userId, attackDamage))

		-- print("Attack Damage = " .. attackDamage)
	end,

	calculateAttackSpeed = function(userId)
		local playerStats, weaponData = getStoreData(userId)

		if not playerStats or not weaponData then
			return
		end

		local attackSpeed = weaponData.attackSpeed * Gears.increaseToMultiplier(playerStats.increasedAttackSpeed)
		local animationTime = 1 / attackSpeed

		store:dispatch(storeActions.SetAttackSpeed(userId, attackSpeed, animationTime))

		-- print("Attack Speed = " .. attackSpeed)
		-- print("Animation Time = " .. animationTime)
	end,

	calculateAoe = function(userId)
		local playerStats, weaponData = getStoreData(userId)

		if not playerStats or not weaponData then
			return
		end

		local aoe = weaponData.aoe * Gears.increaseToMultiplier(playerStats.increasedAoe)

		-- disspatch
		store:dispatch(storeActions.SetAoe(userId, aoe))

		-- print("AOE = " .. aoe)
	end,

	-- DR
	-- PickupRange
}

function PlayerService.CalculateAllStats(userId)
	for _, calculateStat in pairs(playerStatsCalculation) do
		calculateStat(userId)
	end

	-- TODO : Send to Client -> Display on Client side character stats sheet
end

function PlayerService:ApplyStats(userId)
	-- Make the current stats effective
	-- eg restart lifeRegen thread

	self.CalculateAllStats(userId)
	-- weapon:ScaleTo(weaponInfo.weaponSize * Gears.IncreaseToMultiplier(playerStat.aoe))
	-- MS
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
