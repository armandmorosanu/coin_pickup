local CoinServer = require(game:GetService("ServerStorage").src.CoinServer)


--add a new coin, for testing
local willBeACoin = workspace:FindFirstChild("willBeACoin")
if willBeACoin ~= nil then
	CoinServer.markAsCoin(willBeACoin, 1000)
end

task.wait(10)
if willBeACoin.Parent ~= nil then
    willBeACoin:Destroy() --check that this deletes on client side
end

--------