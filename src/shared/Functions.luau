local Functions = {}

function Functions.uuid()
	return string.lower(string.gsub(game:GetService("HttpService"):GenerateGUID(false), "-", ""))
end

function Functions.deepCopy(array: { [any]: any }): { [any]: any }
	local copy = {}

	for key, value in array do
		if type(value) == "table" then
			copy[key] = Functions.deepCopy(value)
		else
			copy[key] = value
		end
	end

	return copy
end

function Functions.createInstance(className: string, information: { [string]: any }): Instance
	local initialInstance = Instance.new(className)

	local properties = table.clone(information)

	properties.Children = nil

	for property, value in properties do
		initialInstance[property] = value
	end

	if information.Children then
		for _, child in information.Children do
			child.Parent = initialInstance
		end
	end

	return initialInstance
end

function Functions.switchKeysAndValues(array: { [any]: any }): { [any]: any }
	local newArray = {}

	for key, value in array do
		newArray[value] = key
	end

	return newArray
end

function Functions.commify(number: number): string
	return string.gsub(string.reverse(string.gsub(string.reverse(tostring(number)), "(%d%d%d)", "%1,")), "^,", "")
end

function Functions.abbreviate(number: number, commaThreshold: number?): string
	if commaThreshold and number < commaThreshold then
		return Functions.commify(number)
	end

	local abbreviations = { "k", "m", "b", "t", "q", "qn", "s", "o", "n", "d", "ud", "dd", "td" }

	local abbreviationIndex = math.min(math.floor(math.log10(number) / 3), #abbreviations)

	if abbreviationIndex == 0 then
		return tostring(number)
	end

	local abbreviatedNumber = number / (10 ^ (abbreviationIndex * 3))
	local decimalPlaces = abbreviatedNumber % 1
	local maxDecimals = 2

	local decimals = math.floor(decimalPlaces * 10 ^ maxDecimals)

	abbreviatedNumber = math.floor(abbreviatedNumber)

	local viewedDecimals = ""

	while maxDecimals > 0 do
		if decimals % 10 ~= 0 then
			viewedDecimals ..= "." .. decimals
			break
		end

		decimals = math.floor(decimals / 10)
		maxDecimals -= 1
	end

	return `{abbreviatedNumber}{viewedDecimals}{abbreviations[abbreviationIndex]}`
end

return Functions
