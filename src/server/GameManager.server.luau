local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await()

local PlayerService = Knit.GetService("PlayerService")
local ItemService = Knit.GetService("ItemService")

-- In World UI
local weaponSpawnButton = workspace.WeaponSpawner.Surface.SurfaceGui.TextButton
local weaponSpawnPos = workspace.WeaponSpawner.SpawnPoint.Position

local bananaSpawnButton = workspace.BananaSpawner.Surface.SurfaceGui.TextButton
local bananaSpawnPos = workspace.BananaSpawner.SpawnPoint.Position

local stickSpawnButton = workspace.StickSpawner.Surface.SurfaceGui.TextButton
local stickSpawnPos = workspace.StickSpawner.SpawnPoint.Position

Players.PlayerAdded:Connect(function(player)
	PlayerService:AddPlayer(player, player.Name)

	-- Manual Tests
	-- local userId = player.UserId

	-- PlayerService:IncrementScore(userId, 1) -- Test Score

	-- Stress Test Attack Speed
	-- Server Error at 2400% Increased attack speed
	-- PlayerService:AddIncreasedAttackSpeed(userId, 1000)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	PlayerService:RemovePlayer(userId)
end)

-- In World UI
weaponSpawnButton.MouseButton1Click:Connect(function()
	ItemService:SpawnLoot(ItemService.ItemStore.WoodenClub, weaponSpawnPos)
end)

bananaSpawnButton.MouseButton1Click:Connect(function()
	ItemService:SpawnLoot(ItemService.ItemStore.Banana, bananaSpawnPos)
end)

stickSpawnButton.MouseButton1Click:Connect(function()
	ItemService:SpawnLoot(ItemService.ItemStore.Stick, stickSpawnPos)
end)
