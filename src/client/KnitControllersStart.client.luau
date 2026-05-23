local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddControllers(ReplicatedStorage.Shared.Controllers)

Knit.Start():catch(warn):await()
-- Knit.Start({ServicePromises = false}):catch(warn):await() -- Disable promises
