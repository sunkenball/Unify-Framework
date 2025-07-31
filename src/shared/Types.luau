-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local Shared = ReplicatedStorage.Shared
local Configs = Shared.Configs

-- Types
export type Data = typeof(require(Configs.Template))

return 0
