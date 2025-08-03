-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local Packages = ReplicatedStorage.Packages

local Unify = require(Packages.Unify)

local TestServer

-- Module
local TestClient = {}

do
	TestServer = Unify:Get("TestServer")

	TestServer:Test("a", 1):andThen(function(player: Player, testValue: string, testValue2: number)
		print(player, testValue, testValue2)
	end)
end

return TestClient
