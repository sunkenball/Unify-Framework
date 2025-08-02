-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")

-- Variables
local Shared = ReplicatedStorage.Shared

local Functions = require(Shared.Functions)

local ANALYTIC_BATCH_SIZE = 100
local BATCH_SEND_INTERVAL = 60
local LAST_SENT_BATCH = os.clock()
local ANALYTIC_BATCH: { FunnelData | CustomData } = {}

local SESSION_IDS: { [number]: string } = {}

-- Types
export type FunnelData = {
	player: Player,
	type: "OnboardingFunnel" | "Funnel",
	step: number,
	stepName: string,
	funnelName: string,
	uniqueId: string?,
	customFields: { [Enum.AnalyticsCustomFieldKeys]: any }?,
}

export type CustomData = {
	player: Player,
	type: "Custom",
	eventName: string,
	value: number?,
	customFields: { [Enum.AnalyticsCustomFieldKeys]: any }?,
}

export type EconomyData = {
	player: Player,
	type: "Economy",
	flowType: Enum.AnalyticsEconomyFlowType,
	currencyType: string,
	increment: number,
	newValue: number,
	transactionType: Enum.AnalyticsEconomyTransactionType,
	skuId: string?,
	customFields: { [Enum.AnalyticsCustomFieldKeys]: any }?,
}

-- Module
local AnalyticsServer = {}

function AnalyticsServer:AddToBatch(data: FunnelData | CustomData | EconomyData)
	table.insert(ANALYTIC_BATCH, data)
end

function AnalyticsServer:SendBatch()
	for i = 1, #ANALYTIC_BATCH do
		local data = ANALYTIC_BATCH[i]

		if data then
			self:ProcessEvent(data)
		end
	end

	table.clear(ANALYTIC_BATCH)
end

function AnalyticsServer:ProcessEvent(data: FunnelData | CustomData | EconomyData)
	if data.type == "OnboardingFunnel" then
		AnalyticsService:LogOnboardingFunnelStepEvent(data.player, data.step, data.stepName, data.customFields)
	elseif data.type == "Funnel" then
		AnalyticsService:LogFunnelStepEvent(
			data.player,
			data.funnelName,
			data.uniqueId,
			data.step,
			data.stepName,
			data.customFields
		)
	elseif data.type == "Custom" then
		AnalyticsService:LogCustomEvent(data.player, data.eventName, data.value, data.customFields)
	elseif data.type == "Economy" then
		AnalyticsService:LogEconomyEvent(
			data.player,
			data.flowType,
			data.currencyType,
			data.increment,
			data.newValue,
			data.transactionType,
			data.skuId,
			data.customFields
		)
	end
end

function AnalyticsServer:ProcessCustomFields(customFields: { [Enum.AnalyticsCustomFieldKeys]: any }?)
	if customFields then
		for key, value in customFields do
			local isCustomField = table.find(Enum.AnalyticsCustomFieldKeys:GetEnumItems(), key)

			if isCustomField then
				customFields[key] = nil
				customFields[key.Name] = value
			end
		end

		return customFields
	end
end

function AnalyticsServer:SendFunnel(
	player: Player,
	step: number,
	stepName: string,
	customFields: { [Enum.AnalyticsCustomFieldKeys]: any }?,
	onboarding: boolean?,
	funnelName: string?,
	uniqueId: boolean?
)
	if onboarding then
		self:AddToBatch({
			player = player,
			type = "OnboardingFunnel",
			step = step,
			stepName = stepName,
			customFields = self:ProcessCustomFields(customFields),
		})
	else
		self:AddToBatch({
			player = player,
			type = "Funnel",
			step = step,
			stepName = stepName,
			funnelName = funnelName,
			uniqueId = if uniqueId then self:GetPlayerSessionId(player) else nil,
			customFields = self:ProcessCustomFields(customFields),
		})
	end
end

function AnalyticsServer:SendCustom(
	player: Player,
	eventName: string,
	value: number?,
	customFields: { [Enum.AnalyticsCustomFieldKeys]: any }?
)
	self:AddToBatch({
		player = player,
		type = "Custom",
		eventName = eventName,
		value = value,
		customFields = self:ProcessCustomFields(customFields),
	})
end

function AnalyticsServer:SendEconomy(
	player: Player,
	flowType: Enum.AnalyticsEconomyFlowType,
	currencyType: string,
	increment: number,
	newValue: number,
	transactionType: Enum.AnalyticsEconomyTransactionType,
	skuId: string?,
	customFields: { [Enum.AnalyticsCustomFieldKeys]: any }?
)
	self:AddToBatch({
		player = player,
		type = "Economy",
		flowType = flowType,
		currencyType = currencyType,
		increment = increment,
		newValue = newValue,
		transactionType = transactionType.Name,
		skuId = skuId,
		customFields = self:ProcessCustomFields(customFields),
	})
end

function AnalyticsServer:GetPlayerSessionId(player: Player)
	return SESSION_IDS[player.UserId]
end

function AnalyticsServer.onPlayerAdded(player: Player)
	SESSION_IDS[player.UserId] = Functions.uuid()
end

do
	RunService.Heartbeat:Connect(function()
		local timeSince = os.clock() - LAST_SENT_BATCH

		if (timeSince >= BATCH_SEND_INTERVAL and #ANALYTIC_BATCH > 0) or #ANALYTIC_BATCH >= ANALYTIC_BATCH_SIZE then
			LAST_SENT_BATCH = os.clock()

			AnalyticsServer:SendBatch()
		end
	end)
end

do
	Players.PlayerAdded:Connect(AnalyticsServer.onPlayerAdded)

	for _, player in Players:GetPlayers() do
		task.spawn(AnalyticsServer.onPlayerAdded, player)
	end
end

return AnalyticsServer
