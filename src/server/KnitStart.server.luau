local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Start All Services -> Avoid race conditions
Knit.AddServices(ServerScriptService.Server.Services)

-- Start Knit Engine

Knit.Start():catch(warn)

-- Knit.Start()
-- 	:andThen(function()
-- 		print("Knit started successfully!")
-- 	end)
-- 	:catch(warn)
