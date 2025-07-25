-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local Packages = ReplicatedStorage.Packages
local Shared = ReplicatedStorage.Shared

local Modules = script.Parent.Parent
local Framework = Modules.Framework

local Unify = require(Packages.Unify)

local Functions = require(Shared.Functions)

local DataServer: typeof(require(Framework.DataServer))

-- Module
local Pets = {}

function Pets:Create(petName: string, petId: string)
	local petData = {}

	petData.Pet = petName
	petData.Id = petId

	return petData
end

function Pets:Give(player: Player, petName: string)
	local playerData = DataServer:GetAsync(player, 5)

	if not playerData then
		return
	end

	local petId = Functions.getId()

	local pets = playerData.Pets

	pets[petId] = self:Create(petName, petId)

	playerData.Pets = pets
end

function Pets.onPlayerAdded(player: Player)
	task.wait(2)

	Pets:Give(player, "Dog")
end

do
	DataServer = Unify:Get("DataServer")

	Players.PlayerAdded:Connect(Pets.onPlayerAdded)

	for _, player in Players:GetPlayers() do
		task.spawn(Pets.onPlayerAdded, player)
	end
end

return Pets
