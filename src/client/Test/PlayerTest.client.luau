-- Disabled in Roblox

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await() -- Wait for KnitControllersStart

-- print("Hello world, from client!")

-- Get Knit Services/Controllers
local MoneyService = Knit.GetService("MoneyService")
local CameraController = Knit.GetController("CameraController")

CameraController.LockedChanged:Connect(function(isLocked)
	print(if isLocked then "Camera is now locked" else "Camera was unlocked")
end)

-- SERVER EVENTS > Interact

MoneyService.MoneyChanged:Connect(function(money)
	print("Current Money", money)
end)

MoneyService.PlayEffect:Connect(function()
	print("Personal Money VFX")
end)

MoneyService.GiveMeMoney:Fire()

-- SERVER PROPERTIES > Interact

-- The 'Observe' method will fire for the current value and any time the value changes:
MoneyService.Money:Observe(function(money)
	print("Current number of Money:", money)
end)

-- Use Service
MoneyService:GetMoney():andThen(function(money)
	print(money)
end)
