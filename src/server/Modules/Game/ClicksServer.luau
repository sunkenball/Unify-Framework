-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local Packages = ReplicatedStorage.Packages

local Modules = script.Parent.Parent
local Framework = Modules.Framework

local Unify = require(Packages.Unify)

local DataServer: typeof(require(Framework.DataServer))

-- Module
local Clicks = {
	Client = {},
}

function Clicks.Client:Click(...: any)
	return self.Server:Click(...)
end

function Clicks:Click(player: Player)
	local playerData = DataServer:GetAsync(player)

	playerData.Clicks += 1
end

do
	DataServer = Unify:Get("DataServer")
end

return Clicks
