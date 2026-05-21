local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
-- local Signal = require(Knit.Util.Signal)

local PointService = Knit.CreateService({
	Name = "PointService",
	Client = {},
})

function PointService:EventTest()
	local MoneyService = Knit.GetService("MoneyService")

	MoneyService.MoneyChanged:Connect(function(player, points)
		print("Points changed for " .. player.Name .. ":", points)
	end)
end
