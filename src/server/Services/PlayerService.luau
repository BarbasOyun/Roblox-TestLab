local Players = game:GetService("Players")
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
		ReplicateStore = Knit.CreateSignal(),
		PlayerRemoved = Knit.CreateSignal(),
		ScoreChanged = Knit.CreateSignal(),
		GiveMeAttackSpeed = Knit.CreateSignal(),
	},
})

local ItemService = nil

-- TODO : Implement
-- local STATS_TYPE = {
-- 	["attackSpeed"] = {
-- 		dispatchAction = storeActions.SetIncreasedAttackSpeed,
-- 	},
-- }

-- PickupRange Parameters
local autoPickupParam = OverlapParams.new()
autoPickupParam.FilterType = Enum.RaycastFilterType.Include
autoPickupParam.FilterDescendantsInstances = { workspace.AutoPickup }
autoPickupParam.MaxParts = 50

local AUTO_PICKUP_FRAME = 5 -- AutoPickup every X Frame
local frameCount = 0

-- PLAYERS

-- gameState = data that need to be Replicated when a player join
-- Sent over network to joining Clients -> need to be serializable
local function gameState()
	local state = store:getState()
	local players = {}

	-- TODO : use player struct
	for userId, player in pairs(state.players) do
		players[userId] = {
			username = player.username,
			score = player.score,
			stats = player.stats,
		}
	end

	local gameState = {
		players = players,
		-- other game data
	}

	return gameState
end

function PlayerService:AddPlayer(player, username)
	local userId = player.UserId

	store:dispatch(storeActions.AddPlayer(userId, username))

	-- Events
	self.PlayerAdded:Fire(userId)
	self.Client.PlayerAdded:FireAll(userId, username)

	-- Send the full store to the new player
	local gameState = gameState()
	-- /!\ Negative numbers (Roblox userIds when testting) are automatically turned into strings when sent over network
	self.Client.ReplicateStore:Fire(player, gameState)
end

function PlayerService:RemovePlayer(userId)
	store:dispatch(storeActions.RemovePlayer(userId))

	-- Events
	self.PlayerRemoved:Fire(userId)
	self.Client.PlayerRemoved:FireAll(userId)
end

-- SCORE

function PlayerService:GetScore(userId)
	local score = store:getState().players[userId].score
	return if score ~= nil then score else 0
end

function PlayerService:AddScore(userId, value)
	local score = self:GetScore(userId)
	local newScore = score + value
	store:dispatch(storeActions.SetScore(userId, newScore))

	self.ScoreChanged:Fire(userId, newScore)
	-- Replicate to Clients
	self.Client.ScoreChanged:FireAll(userId, newScore)
end

-- STATS > Move to Combat/Stats Service?

-- Most Stats work like this : baseX * increasedX = x
-- some baseX (eg attackSpeedBase) come from weaponData
-- every used / final x stats is stored in the playerStats (weaponData never mutate)

function PlayerService:GetStats(userId)
	local storeState = store:getState()
	local playerStats = storeState.players[userId].stats
	local weaponData = storeState.players[userId].weaponData

	return playerStats, weaponData
end

local statsCalcFunctions = {
	calculateAttackDamage = function(userId)
		local playerStats, weaponData = PlayerService:GetStats(userId)

		if not playerStats or not weaponData then
			return
		end

		-- baseAttackDamage = weaponData.damage
		local attackDamage = weaponData.damage * Gears.increaseToMultiplier(playerStats.increasedAttackDamage)

		store:dispatch(storeActions.SetAttackDamage(userId, attackDamage))

		-- print("Attack Damage = " .. attackDamage)
	end,

	calculateAttackSpeed = function(userId)
		local playerStats, weaponData = PlayerService:GetStats(userId)

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
		local playerStats, weaponData = PlayerService:GetStats(userId)

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

function PlayerService:CalculateAllStats(userId)
	for _, calculateStat in pairs(statsCalcFunctions) do
		calculateStat(userId)
	end

	-- TODO : Send to Client -> Display on Client side character stats sheet
end

function PlayerService:ApplyStats(userId)
	-- Make the current stats effective
	-- eg restart lifeRegen thread

	self:CalculateAllStats(userId)
	-- weapon:ScaleTo(weaponInfo.weaponSize * Gears.IncreaseToMultiplier(playerStat.aoe))
	-- MS
end

--[[ TODO : Implement
function PlayerService:AddIncreasedStat(userId, statType, value)
	-- Get stat
	local newStat = store:getState().players[userId][statType] + value
	store:dispatch(STATS_TYPE[statType](userId, newStat))
end
]]

function PlayerService:AddIncreasedAttackSpeed(userId, value)
	local newincreasedAttackSpeed = store:getState().players[userId].stats.increasedAttackSpeed + value
	store:dispatch(storeActions.SetIncreasedAttackSpeed(userId, newincreasedAttackSpeed))

	statsCalcFunctions.calculateAttackSpeed(userId)
end

function PlayerService:AddXpToPlayer(player, xp)
	-- print(player.Name .. " Gained : " .. xp .. " XP")
	-- local playerStat = playersStats[player.UserId]
	-- playerStat.currentXp.Value += xp * Gears.increaseToMultiplier(playerStat.increasedXp)

	-- if playerStat.currentXp.Value >= playerStat.levelUpXp.Value then
	-- 	playersStats.LevelUp(player, playerStat)
	-- end

	-- Dispatch xp
end

function PlayerService:LevelUp(player, playerStat)
	-- Compute XP
	-- local overXp = playerStat.currentXp.Value - playerStat.levelUpXp.Value
	-- playerStat.waitingLevel += 1
	-- playerStat.currentXp.Value = 0
	-- playerStat.levelUpXp.Value *= 1.1
	-- print(player.Name .. " Leveled Up")

	-- playersStats.SendAugment(player, playerStat)
	-- levelUpEvent:FireClient(player, playerStat.level, playerStat.waitingLevel)

	-- playersStats.AddXpToLvl(player, overXp)

	-- Dispatch Lvl
end

-- Auto Pickup
local function autoPickup(player, itemModel)
	if not itemModel.Parent or itemModel.Parent ~= workspace.AutoPickup then
		return
	end

	itemModel.Parent = game.Workspace
	itemModel.CanCollide = false

	-- Lerp itemModel
	local startPos = itemModel.CFrame

	local steps = 20
	local progress = 0
	local speed = 1 / steps / 4
	local acceleration = (1 / steps - speed) / (steps / 2)

	for _ = 1, steps do
		progress += speed
		speed += acceleration
		itemModel.CFrame = startPos:Lerp(player.character:GetPivot(), progress)
		RunService.Heartbeat:Wait()
	end

	ItemService:PickupItem(player, itemModel)
end

local function autoPickupRange()
	if frameCount < AUTO_PICKUP_FRAME then
		frameCount += 1
		return
	end

	frameCount = 0

	local storeState = store:getState()

	for _, player in ipairs(Players:GetPlayers()) do
		local playerData = storeState.players[player.userId]

		if not playerData then
			continue
		end

		local playerStats = playerData.stats
		local character = player.Character or player.CharacterAdded:Wait()

		local playerPos = character.HumanoidRootPart.CFrame.Position
		local pickupRange = playerStats.pickupRange

		-- DEBUG
		-- Gears.DisplayHitBox(position, pickupRange, 0.1)

		local autoPickupItems = workspace:GetPartBoundsInRadius(playerPos, pickupRange, autoPickupParam)

		for _, itemModel in ipairs(autoPickupItems) do
			autoPickup(player, itemModel)
		end
	end
end

-- Unit Tests

-- Start Service
function PlayerService:KnitInit()
	print("PlayerService Initialized")

	self.Client.GiveMeAttackSpeed:Connect(function(player)
		-- Validation + Spend money
		self:AddIncreasedAttackSpeed(player.UserId, 100)
	end)
end

function PlayerService:KnitStart()
	-- print("PlayerService Start")

	ItemService = Knit.GetService("ItemService")

	RunService.Heartbeat:Connect(autoPickupRange)
end

return PlayerService
