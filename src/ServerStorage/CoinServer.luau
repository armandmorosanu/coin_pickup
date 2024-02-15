local CollectionService = game:GetService("CollectionService")
local PlayerService = game:GetService("Players")

local COIN_TAG = "coin"
local COIN_VALUE_ATTRIBUTE_NAME = "value"

local CoinRemoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("CoinRemoteEvent")
assert(
	CoinRemoteEvent and CoinRemoteEvent:IsA("RemoteEvent"),
	"Must have a remote event named CoinRemoteEvent under ReplicatedStorage"
)

local playerCoins = {}
PlayerService.PlayerAdded:Connect(function(player)
	playerCoins[player] = 0 --normally, load from datastore
end)
PlayerService.PlayerRemoving:Connect(function(player)
	-- wait for data to save, or write this info to datastore/data module
	-- then avoid mem leaks
	playerCoins[player] = nil
end)

local function isValidCoinPickupRequest(player: Player, coinInstance: BasePart): boolean
	local isDescendantOfWorkspace = coinInstance:IsDescendantOf(workspace)
	if not isDescendantOfWorkspace then
		return false
	end -- can't pick up a coin not in workspace

	local character: Model? = player.Character
	if character == nil then
		return false
	end -- `Player {player} must have character to pickup coins!`

	local primaryPart: BasePart? = character.PrimaryPart
	if primaryPart == nil then
		return false
	end -- `Player {player} must have a primaryPart (humanoidRootPart) to pickup coins!`

	local distance = (primaryPart.Position - coinInstance.Position).Magnitude
	if distance > 10 then
		return false
	end -- `Player {player} must be close enough to pick up coins`

	local hasCoinTag = CollectionService:HasTag(coinInstance, COIN_TAG)
	if hasCoinTag == nil then
		return false
	end -- `Player {player} must pick up a valid coin! {coinInstance} does not have the cs tag.`

	local coinValue = coinInstance:GetAttribute(COIN_VALUE_ATTRIBUTE_NAME)
	if coinValue == nil then
		return false
	end -- `coinInstance {coinInstance} must have a value attribute for {player} to pick it up.`

	--let them have it
	return true
end
CoinRemoteEvent.OnServerEvent:Connect(function(player, coinInstance)
	if not isValidCoinPickupRequest(player, coinInstance) then
		return
	end

	--all checks passed! let them have it!
	local coinValue = coinInstance:GetAttribute(COIN_VALUE_ATTRIBUTE_NAME)
	coinInstance:Destroy()
	playerCoins[player] += coinValue

	CoinRemoteEvent:FireClient(player, playerCoins[player])
end)

local function markAsCoin(instance: BasePart, value: number)
	CollectionService:AddTag(instance, COIN_TAG)
	instance:SetAttribute(COIN_VALUE_ATTRIBUTE_NAME, value)
	-- all this auto replicates so we are golden
	-- plus we can easily author these without any coding in studio
end




return {
	getPlayerCoins = function(player: Player): number
		return playerCoins[player]
	end,
	markAsCoin = markAsCoin,
}
