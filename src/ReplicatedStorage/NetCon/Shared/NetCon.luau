local NetCon = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local REMOTE_NAME = "NetConMainChannel"
local Listeners = {}
local isInitialized = false

function NetCon.Fire(actionName, data)
	if RunService:IsClient() then
		local remote = ReplicatedStorage:WaitForChild("NetCon"):WaitForChild("Shared"):WaitForChild(REMOTE_NAME, 5)
		if remote then
			remote:FireServer(actionName, data)
		end
	end
end

function NetCon.On(actionName, callback)
	Listeners[actionName] = callback
end

function NetCon.Init()
	if not RunService:IsClient() or isInitialized then return end
	isInitialized = true

	local success, gameName = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId).Name
	end)
	local targetName = success and gameName or "Unknown Game"

	local remote = ReplicatedStorage:WaitForChild("NetCon"):WaitForChild("Shared"):WaitForChild(REMOTE_NAME, 10)
	if remote then
		remote.OnClientEvent:Connect(function(actionName, data)
			local callback = Listeners[actionName]
			if callback then
				task.spawn(callback, data)
			end
		end)
	end
	warn("NetCon v1 By CTTeddy Running on " .. targetName)
end

return NetCon
