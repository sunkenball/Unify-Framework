-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local Packages = ReplicatedStorage.Packages

local Unify = require(Packages.Unify)

local TestServer

-- Module
local TestClient = {}

do
	Unify:OnRan()
		:andThen(function()
			TestServer = Unify:Get("TestServer")
		end)
		:finally(function()
			TestServer:Test("a", 1):andThen(function(player: Player, testValue: string, testValue2: number)
				print(player, testValue, testValue2)
			end)
		end)
end

return TestClient
