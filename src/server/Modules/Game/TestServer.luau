-- Module
local TestServer = {
    Client = {}
}

function TestServer.Client:Test(...: any)
    return self.Server:Test(...)
end

function TestServer:Test(player: Player, testValue: string, testValue2: number)
    print(player, testValue, testValue2)

    return player, testValue, testValue2
end

return TestServer