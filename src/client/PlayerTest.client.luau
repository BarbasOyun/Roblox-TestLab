local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.Start():catch(warn):await()
-- Knit.Start({ServicePromises = false}):catch(warn):await() -- Disable promises

local MoneyService = Knit.GetService("MoneyService")

-- print("Hello world, from client!")

MoneyService:GetMoney():andThen(function(money)
	print(money)
end)
