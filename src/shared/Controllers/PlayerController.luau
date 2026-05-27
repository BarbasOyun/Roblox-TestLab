local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxStore = require(ReplicatedStorage.Shared.RoduxStore)
local store = RoduxStore.Store -- Client side store -> Custom Client store?
local storeActions = RoduxStore.Actions

local Knit = require(ReplicatedStorage.Packages.Knit)
--  Signal = require(ReplicatedStorage.Packages._Index["sleitnick_signal@1.5.0"].signal)

local CombatService = nil

local PlayerController = Knit.CreateController({ Name = "PlayerController" })

PlayerController.store = store

-- Attack
-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local animationTracks = {}

local isLClickDown = false

-- ANIMATIONS

local function loadAnimation(animationId)
	local anim = Instance.new("Animation")
	anim.AnimationId = animationId

	local animationTrack = animator:LoadAnimation(anim)
	animationTrack.Priority = Enum.AnimationPriority.Action

	animationTrack:GetMarkerReachedSignal("AttackHit"):Connect(function()
		--print("Hit Event Triggered by player: " .. player.Name)
		CombatService.finishAttack:Fire()
	end)

	return animationTrack
end

local function loadAllAnimations()
	local horizontalSlash = loadAnimation("rbxassetid://88145589618998") -- Combo 1
	local verticalSlash = loadAnimation("rbxassetid://119339188916178") -- Combo 2

	table.insert(animationTracks, horizontalSlash)
	table.insert(animationTracks, verticalSlash)
end

-- On Respawn
local function onCharacterAdded(newCharacter)
	-- print("Character Added for player: " .. player.Name)
	animator = newCharacter:WaitForChild("Humanoid"):WaitForChild("Animator")
	table.clear(animationTracks)
	loadAllAnimations()
end

-- CONTROLLER

function PlayerController:KnitInit()
	print("PlayerController Init")
end

function PlayerController:KnitStart()
	print("PlayerController Start")

	CombatService = Knit.GetService("CombatService")
	local PlayerService = Knit.GetService("PlayerService")

	-- Players Join/Leave Events
	PlayerService.PlayerAdded:Connect(function(userId, username)
		-- Replicate Action Client side
		store:dispatch(storeActions.AddPlayer(userId, username))
	end)

	PlayerService.PlayerRemoved:Connect(function(userId)
		store:dispatch(storeActions.RemovePlayer(userId))
	end)

	-- Score
	PlayerService.ScoreChanged:Connect(function(userId, newScore)
		-- Update Score instead of Increment
		store:dispatch(storeActions.SetScore(userId, newScore))
	end)

	-- 3) Clients : Animation
	-- Server Validated the attack
	CombatService.startAttack:Connect(function(animationId, animationSpeed) -- animationId = comboIndex + 1
		-- print(localPlayer.Name .. " Combo: " .. animationId .. " Animation Speed: " .. animationSpeed)
		animationTracks[animationId]:Play()
		animationTracks[animationId]:AdjustSpeed(animationSpeed)
	end)

	-- CONTROLS

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		--print("Input detected: " .. tostring(input.UserInputType) .. "Game processed: " .. tostring(gameProcessed))
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- CombatService.startAttack:Fire()
			isLClickDown = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isLClickDown = false
		end
	end)

	RunService.Heartbeat:Connect(function()
		if isLClickDown then
			print("Ask Server to Attack")
			CombatService.startAttack:Fire()
		end
	end)

	loadAllAnimations()
end

return PlayerController
