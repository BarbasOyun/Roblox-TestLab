local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await()

local PlayerService = Knit.GetService("PlayerService")
local CombatService = Knit.GetService("CombatService")

local weaponSpawnButton = workspace.WeaponSpawner.Surface.SurfaceGui.TextButton
local weaponSpawnPos = workspace.WeaponSpawner.SpawnPoint.Position

local bananaSpawnButton = workspace.BananaSpawner.Surface.SurfaceGui.TextButton
local bananaSpawnPos = workspace.BananaSpawner.SpawnPoint.Position

local stickSpawnButton = workspace.StickSpawner.Surface.SurfaceGui.TextButton
local stickSpawnPos = workspace.StickSpawner.SpawnPoint.Position

Players.PlayerAdded:Connect(function(player)
	local userId = player.UserId

	PlayerService:AddPlayer(userId, player.Name)

	-- PlayerService:IncrementScore(userId, 1) -- Test

	-- Stress Test Attack Speed
	PlayerService:AddIncreasedAttackSpeed(userId, 1000)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	PlayerService:RemovePlayer(userId)
end)

-- In World UI
weaponSpawnButton.MouseButton1Click:Connect(function()
	print("Spawn Weapon")
	CombatService:SpawnWeapon(CombatService.items.woodenClub, weaponSpawnPos)
end)

bananaSpawnButton.MouseButton1Click:Connect(function()
	print("Spawn Banana")
end)

stickSpawnButton.MouseButton1Click:Connect(function()
	print("Spawn Stick")
end)
