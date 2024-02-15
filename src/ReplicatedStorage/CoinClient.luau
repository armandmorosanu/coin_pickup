local CollectionService = game:GetService("CollectionService")
local PlayerService = game:GetService("Players")
local LocalPlayer = PlayerService.LocalPlayer

local COIN_TAG = "coin"

local CoinRemoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("CoinRemoteEvent")
assert(
	CoinRemoteEvent and CoinRemoteEvent:IsA("RemoteEvent"),
	"Must have a remote event named CoinRemoteEvent under ReplicatedStorage"
)

-- replace this with actual ui and sfx
CoinRemoteEvent.OnClientEvent:Connect(function(coins)
	warn(`you now have {coins} coins!`)
end)

local coinEvents = {} -- store .touched events

local function initializeCoinEvent(coinInstance: BasePart)
    assert(coinInstance:IsA("BasePart"), `{coinInstance} must be a BasePart to be a coin!`)
	assert(coinEvents[coinInstance] == nil, `instance {coinInstance} is already a coin!`)

	local event = coinInstance.Touched:Connect(function(touchedBy: BasePart)
		local touchedByParent = touchedBy.Parent
		if not touchedByParent:IsA("Model") then
			return
		end --we didn't touch a valid character

		local some_player = PlayerService:GetPlayerFromCharacter(touchedByParent)
		if some_player == nil then
			return
		end -- we didn't touch a player

		if some_player ~= LocalPlayer then
			return
		end -- we didn't touch MY player

		-- here, we touched my player!
		-- Let's ask the server to give us the money for this coin

		CoinRemoteEvent:FireServer(coinInstance)
	end)

	coinEvents[coinInstance] = event
end
local function cleanupCoin(coinInstance: BasePart)
	local event = coinEvents[coinInstance]
	if event ~= nil then
		event:Disconnect()
	end
	coinEvents[coinInstance] = nil
end

for _, coinInstance: BasePart in CollectionService:GetTagged(COIN_TAG) do
	initializeCoinEvent(coinInstance)
end
CollectionService:GetInstanceAddedSignal(COIN_TAG):Connect(function(coinInstance)
	initializeCoinEvent(coinInstance)
end)
CollectionService:GetInstanceRemovedSignal(COIN_TAG):Connect(function(coinInstance)
	-- i believe this event gets called when coinInstance is destroyed, so no need to
	-- hook cleanupCoin into .Destroying
    -- (edit: after testing^ it does get called)

    warn(`cleaning up {coinInstance}!`)
	cleanupCoin(coinInstance)
    print(coinEvents) -- this should only have 3 entries
end)

return {}
