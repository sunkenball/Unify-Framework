-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local CLIENT_DATA
local ON_CHANGED_CALLBACKS = {}
local ON_LOADED_CALLBACKS = {}

local Packages = ReplicatedStorage.Packages
local Shared = ReplicatedStorage.Shared

local DataServer

local Unify = require(Packages.Unify)
local Promise = require(Packages.Promise)

local Types = require(Shared.Types)

-- Types
type PlayerData = Types.Data
type Promise<T> = typeof(Promise.new())

-- Module
local DataClient = {}

do
	function DataClient:Get(): PlayerData?
		return CLIENT_DATA
	end

	function DataClient:GetAsync(): Promise<PlayerData>
		return Promise.new(function(resolve, reject)
			local playerData = self:Get()

			if not playerData then
				repeat
					task.wait()
				until self:Get()
			end

			DataServer:Get():andThen(resolve):catch(reject)
		end)
	end

	function DataClient:OnChanged(key: string | { string }, callback: (oldValue: any, newValue: any) -> any)
		if type(key) == "string" then
			local onChangedCallbacks = ON_CHANGED_CALLBACKS[key]

			if not onChangedCallbacks then
				onChangedCallbacks = {}

				ON_CHANGED_CALLBACKS[key] = onChangedCallbacks
			end

			table.insert(onChangedCallbacks, callback)
		elseif type(key) == "table" then
			for _, key in key do
				self:OnChanged(key, callback)
			end
		end
	end

	function DataClient:OnLoaded(callback: (playerData: PlayerData) -> any)
		local onLoadedCallbacks = ON_LOADED_CALLBACKS

		if not onLoadedCallbacks then
			onLoadedCallbacks = {}

			ON_LOADED_CALLBACKS = onLoadedCallbacks
		end

		table.insert(onLoadedCallbacks, callback)
	end

	function DataClient.onLoaded(playerData: PlayerData)
		print("Data loaded:", playerData)

		CLIENT_DATA = playerData

		do
			local onLoadedCallbacks = ON_LOADED_CALLBACKS

			if onLoadedCallbacks then
				for i = 1, #onLoadedCallbacks do
					local callback = onLoadedCallbacks[i]

					if callback then
						task.spawn(callback, playerData)
					end
				end
			end
		end
	end

	function DataClient.onChanged(key: string, oldValue: any, newValue: any)
		CLIENT_DATA[key] = newValue

		print("Data changed:", key, oldValue, newValue, CLIENT_DATA)

		do
			local onChangedCallbacks = ON_CHANGED_CALLBACKS[key]

			if onChangedCallbacks then
				for i = 1, #onChangedCallbacks do
					local callback = onChangedCallbacks[i]

					if callback then
						task.spawn(callback, oldValue, newValue)
					end
				end
			end
		end
	end
end

do
	Unify:OnRan()
		:andThen(function()
			DataServer = Unify:Get("DataServer")
		end)
		:finally(function()
			DataServer.Changed:Connect(DataClient.onChanged)

			DataServer.Loaded:Once(DataClient.onLoaded)

			DataClient:GetAsync()
		end)
end

return DataClient
