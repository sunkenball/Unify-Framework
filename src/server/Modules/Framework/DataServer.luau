-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Variables
local Packages = ReplicatedStorage.Packages
local Shared = ReplicatedStorage.Shared
local Configs = Shared.Configs

local ON_PLAYER_REMOVING_CALLBACKS = {}
local ON_PLAYER_ADDED_CALLBACKS = {}
local ON_DATA_CHANGED_CALLBACKS = {}

local IS_STUDIO = RunService:IsStudio()

local STUDIO_VERSION = "0.0.0"
local GAME_VERSION = "0.0.0"

local SHOULD_SAVE = true

local MOCK = true

local DATA_VERSION = if IS_STUDIO then STUDIO_VERSION else GAME_VERSION

local MAX_DATA_RETRIES = 10
local DATA_RETRY_DELAY = 1

local DATA_TEMPLATE = require(Configs.Template)

local ProfileStore = require(Packages.ProfileStore)

local Functions = require(Shared.Functions)

local PlayersData: { [Player]: typeof(DATA_TEMPLATE) } = {}
local PlayersSessions: { [Player]: typeof(ProfileStore.New()) } = {}

-- Module
local DataServer = {
	Client = {},
}

function DataServer.Client:Get(...: any)
	return self.Server:GetRaw(...)
end

function DataServer.Client.Changed(...: any)
	return
end

function DataServer.Client.Loaded(...: any)
	return
end

function DataServer:Get(player: Player)
	return PlayersData[player]
end

function DataServer:GetAsync(player: Player, timeout: number?)
	local start = os.clock()

	repeat
		task.wait()
	until PlayersData[player] or os.clock() - start >= (timeout or 60)

	return PlayersData[player]
end

function DataServer:GetRaw(player: Player)
	local mimic = self:Get(player)

	if not mimic then
		return
	end

	return getmetatable(mimic).__index
end

function DataServer:GetRawAsync(player: Player, timeout: number?)
	local start = os.clock()

	repeat
		task.wait()
	until self:GetRaw(player) or os.clock() - start >= (timeout or 60)

	return self:GetRaw(player)
end

function DataServer:Create(player: Player)
	local playerSession
	local userId = player.UserId

	for _ = 1, MAX_DATA_RETRIES do
		playerSession = self._profileStore:StartSessionAsync(`{userId}_{DATA_VERSION}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		if playerSession then
			break
		end

		task.wait(DATA_RETRY_DELAY)
	end

	if not playerSession then
		return player:Kick(
			`Failed to load session after {MAX_DATA_RETRIES * DATA_RETRY_DELAY} seconds and {MAX_DATA_RETRIES} attempts.`
		)
	end

	playerSession:AddUserId(userId)

	playerSession:Reconcile()

	do
		local onSessionEnd

		onSessionEnd = playerSession.OnSessionEnd:Connect(function()
			local callbacks = ON_PLAYER_REMOVING_CALLBACKS[player]

			if callbacks then
				for i = 1, #callbacks do
					local callback = callbacks[i]

					if callback then
						task.spawn(callback, player)
					end
				end
			end

			ON_PLAYER_REMOVING_CALLBACKS[player] = nil

			PlayersData[player] = nil
			PlayersSessions[player] = nil

			onSessionEnd:Disconnect()
		end)
	end

	local playerData = if SHOULD_SAVE then playerSession.Data else Functions.deepCopy(playerSession.Data)

	local dataMimic = setmetatable({}, {
		__index = playerData,
		__tostring = function()
			return "Print a specific index of the player data, or print using DataServer:GetRaw(<Player>)"
		end,
		__newindex = function(_, key: string, newValue: any)
			do
				local callbacks = ON_DATA_CHANGED_CALLBACKS[player]

				for i = 1, #callbacks do
					local callback = callbacks[i]

					if callback then
						task.spawn(callback, key, playerData[key], newValue)
					end
				end
			end

			local oldValue = playerData[key]

			playerData[key] = newValue

			DataServer.Client.Changed:Fire(player, key, oldValue, newValue)
		end,
	})

	do
		for i = 1, #ON_PLAYER_ADDED_CALLBACKS do
			local callback = ON_PLAYER_ADDED_CALLBACKS[i]

			if callback then
				task.spawn(callback, player)
			end
		end
	end

	return playerData, dataMimic, playerSession
end

function DataServer:OnPlayerRemoving(player: Player, callback: () -> any)
	ON_PLAYER_REMOVING_CALLBACKS[player] = ON_PLAYER_REMOVING_CALLBACKS[player] or {}

	table.insert(ON_PLAYER_REMOVING_CALLBACKS[player], callback)
end

function DataServer:OnPlayerAdded(callback: (player: Player) -> any)
	table.insert(ON_PLAYER_ADDED_CALLBACKS, callback)
end

function DataServer:OnDataChanged(player: Player, callback: (key: string, oldValue: any, newValue: any) -> any)
	ON_DATA_CHANGED_CALLBACKS[player] = ON_DATA_CHANGED_CALLBACKS[player] or {}

	table.insert(ON_DATA_CHANGED_CALLBACKS[player], callback)
end

function DataServer.onPlayerAdded(player: Player)
	local rawData, mimicData, session = DataServer:Create(player)

	PlayersData[player] = mimicData
	PlayersSessions[player] = session

	DataServer.Client.Loaded:Fire(player, rawData)
end

function DataServer.onPlayerRemoving(player: Player)
	local playerSession = PlayersSessions[player]

	if not playerSession then
		return
	end

	ON_DATA_CHANGED_CALLBACKS[player] = nil

	playerSession:EndSession()
end

do
	local profileStore = ProfileStore.New(if IS_STUDIO then "Studio" else "Game", DATA_TEMPLATE)

	DataServer._profileStore = if MOCK then profileStore.Mock else profileStore
end

do
	Players.PlayerAdded:Connect(DataServer.onPlayerAdded)
	Players.PlayerRemoving:Connect(DataServer.onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		task.spawn(DataServer.onPlayerAdded, player)
	end
end

return DataServer
