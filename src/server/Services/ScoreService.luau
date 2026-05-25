local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
-- local Signal = require(Knit.Util.Signal)

local ScoreService = Knit.CreateService({
	Name = "ScoreService",
	Client = {},
})

function ScoreService:KnitStart()
	local MoneyService = Knit.GetService("MoneyService")

	MoneyService.MoneyChanged:Connect(function(player, points)
		print("Money changed for " .. player.Name .. ":", points)
	end)
end

return ScoreService
