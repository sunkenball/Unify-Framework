-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local DataServer: typeof(require(script.Parent.DataServer))

local Packages = ReplicatedStorage.Packages
local Shared = ReplicatedStorage.Shared
local Configs = Shared.Configs

local Unify = require(Packages.Unify)

local Functions = require(Shared.Functions)

local LeaderstatsConfig = require(Configs.Leaderstats)

local COMMA_THRESHOLD = 100_000

-- Module
local LeaderstatsServer = {}

function LeaderstatsServer:Create(player: Player)
	local playerData = DataServer:GetRawAsync(player, 30)

	local leaderstats = Functions.createInstance("Folder", {
		Name = "leaderstats",
		Parent = player,

		Children = (function()
			local children = {}

			for leaderstatName, dataPath in LeaderstatsConfig do
				local value = playerData[dataPath]

				table.insert(
					children,
					Functions.createInstance("StringValue", {
						Name = leaderstatName,
						Value = Functions.abbreviate(value, COMMA_THRESHOLD),
					})
				)
			end

			return children
		end)(),
	})

	DataServer:OnDataChanged(player, function(key: string, _: any, newValue: any)
		local leaderstatName = Functions.switchKeysAndValues(LeaderstatsConfig)[key]

		if not leaderstatName then
			return
		end

		local leaderstat = leaderstats:FindFirstChild(leaderstatName)

		leaderstat.Value = Functions.abbreviate(newValue, COMMA_THRESHOLD)
	end)
end

do
	DataServer = Unify:Get("DataServer")
end

do
	DataServer:OnPlayerAdded(function(player: Player)
		LeaderstatsServer:Create(player)
	end)
end

return LeaderstatsServer
