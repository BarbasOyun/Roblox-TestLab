-- Knit Getting Started : https://sleitnick.github.io/Knit/docs/gettingstarted

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
-- local Signal = require(Knit.Util.Signal)
-- local Signal = require(ReplicatedStorage.Packages.Signal)
local Signal = require(ReplicatedStorage.Packages._Index["sleitnick_signal@1.5.0"].signal)

-- print("Hello world, from server!")

-- Create the service:
local MoneyService = Knit.CreateService({
	-- SERVER PROPERTIES
	Name = "MoneyService",
	MoneyPerPlayer = {},
	-- Events
	MoneyChanged = Signal.new(),
	Client = {
		-- CLIENT PROPERTIES
		Money = Knit.CreateProperty(0),
		-- Events
		MoneyChanged = Knit.CreateSignal(),
		GiveMeMoney = Knit.CreateSignal(),
		PlayEffect = Knit.CreateUnreliableSignal(),
	},
})

-- SERVER FUNCTIONS

function MoneyService:KnitInit()
	local rng = Random.new()
	-- Listen for the client to fire this signal, then give random points:
	self.Client.GiveMeMoney:Connect(function(player)
		local money = rng:NextInteger(0, 10)
		self:UpdateMoney(player, money)
		-- print("Gave " .. player.Name .. " " .. money .. " money")
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Clear out the data for the player when the player leaves:
		self.MoneyPerPlayer[player] = nil
	end)

	-- print("MoneyService Initialized")
end

function MoneyService:GetMoney(player)
	-- Using Datastore
	-- local money = someDataStore:GetAsync("money")

	-- Using Property
	local money = self.MoneyPerPlayer[player]
	return if money ~= nil then money else 0 -- Return 0 if no money found for player
end

function MoneyService:UpdateMoney(player, value)
	local money = self:GetMoney(player)
	money += value -- Add Money

	-- Using DataStore
	-- someDataStore:SetAsync("money", money)

	-- Using Property
	self.MoneyPerPlayer[player] = money -- Store Money
	self.Client.Money:SetFor(player, money)

	if value > 0 then
		self.Client.PlayEffect:Fire(player)
	end

	if value ~= 0 then
		self.MoneyChanged:Fire(player, money) -- Fire Event
		self.Client.MoneyChanged:Fire(player, money) -- Fire Client Event
	end
end

-- CLIENT FUNCTIONS

function MoneyService.Client:GetMoney(player)
	-- We already wrote this method, so we can just call the other one.
	-- 'self.Server' will reference back to the root MoneyService.
	return self.Server:GetMoney(player)
end

return MoneyService
