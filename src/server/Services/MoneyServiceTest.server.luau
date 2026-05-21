local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(Knit.Util.Signal)

-- print("Hello world, from server!")

-- Create the service:
local MoneyService = Knit.CreateService({
	Name = "MoneyService",
	Client = {},
})

-- Properties
MoneyService.MoneyPerPlayer = {}

-- Signal / Events
MoneyService.MoneyChanged = Signal.new()

-- Add some methods to the service:

function MoneyService:GetMoney(player)
	-- Using Datastore
	-- local money = someDataStore:GetAsync("money")

	-- Using Property
	local money = self.MoneyPerPlayer[player]
	return if money ~= nil then money else 0 -- Return 0 if no money found for player
end

function MoneyService:GiveMoney(player, amount)
	local money = self:GetMoney(player)
	money += amount -- Add Money

	-- Using DataStore
	-- someDataStore:SetAsync("money", money)

	-- Using Property
	self.MoneyPerPlayer[player] = money -- Store Money

	if amount ~= 0 then
		self.PointsChanged:Fire(player, money) -- Fire Event
	end
end

Knit.Start():catch(warn)

function MoneyService.Client:GetMoney(player)
	-- We already wrote this method, so we can just call the other one.
	-- 'self.Server' will reference back to the root MoneyService.
	return self.Server:GetMoney(player)
end
