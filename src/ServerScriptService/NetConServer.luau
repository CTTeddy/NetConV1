local NetConServer = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local REMOTE_NAME = "NetConMainChannel"
local Actions = {}

local Cooldowns = {}
local SPAM_LIMIT = 15
local WINDOW_SIZE = 1

local protectionEnabled = true
local isInitialized = false

local netConFolder = ReplicatedStorage:FindFirstChild("NetCon")
if not netConFolder and RunService:IsServer() then
	netConFolder = Instance.new("Folder")
	netConFolder.Name = "NetCon"
	netConFolder.Parent = ReplicatedStorage
end

local sharedFolder = netConFolder:FindFirstChild("Shared")
if not sharedFolder and RunService:IsServer() then
	sharedFolder = Instance.new("Folder")
	sharedFolder.Name = "Shared"
	sharedFolder.Parent = netConFolder
end

local remote = sharedFolder:FindFirstChild(REMOTE_NAME)
if not remote and RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = REMOTE_NAME
	remote.Parent = sharedFolder
end

function NetConServer.SetProtection(isEnabled)
	protectionEnabled = not not isEnabled
end

function NetConServer.Register(actionName, callback)
	Actions[actionName] = callback
end

function NetConServer.FireClient(player, actionName, data)
	if RunService:IsServer() and remote then
		remote:FireClient(player, actionName, data)
	end
end

function NetConServer.FireAllClients(actionName, data)
	if RunService:IsServer() and remote then
		remote:FireAllClients(actionName, data)
	end
end

function NetConServer.Init()
	if not RunService:IsServer() or not remote or isInitialized then return end
	isInitialized = true

	local success, gameName = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId).Name
	end)
	local targetName = success and gameName or "Unknown Game"
	warn("NetCon v1 By CTTeddy Running on " .. targetName)

	remote.OnServerEvent:Connect(function(player, actionName, data)
		if type(actionName) ~= "string" then return end

		local actionFn = Actions[actionName]
		if not actionFn then return end

		if protectionEnabled then
			local userId = player.UserId
			local now = os.clock()

			Cooldowns[userId] = Cooldowns[userId] or { count = 0, reset = now + WINDOW_SIZE }

			if now > Cooldowns[userId].reset then
				Cooldowns[userId].count = 0
				Cooldowns[userId].reset = now + WINDOW_SIZE
			end

			Cooldowns[userId].count += 1
			if Cooldowns[userId].count > SPAM_LIMIT then
				return
			end
		end

		local successCall, err = pcall(function()
			actionFn(player, data)
		end)

		if not successCall then
			warn("[NetCon Error] " .. actionName .. ": " .. tostring(err))
		end
	end)
end

return NetConServer
