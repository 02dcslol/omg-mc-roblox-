-- ============================================================
-- AUTOCHEAT — full loop, survives rejoin via queue_on_teleport
-- Pastebin: https://pastebin.com/raw/ACRvJ3zT
-- ============================================================

local SCRIPT_SOURCE = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/02dcslol/omg-mc-roblox-/refs/heads/main/ok.lua"))()]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer

-- ============ CONFIG ============
local SPACING = 0.005
local REPLICATION_WAIT = 0.15
local MAX_WAIT_FOR_DEATH = 5
local MIN_SCORE = 50
local SCAN_DELAY_AFTER_JOIN = 4
local LOOP_DELAY = 2
local HOP_DELAY = 2
local MAX_KILLS_BEFORE_HOP = 3

-- ============ GUARD (per-server, not persistent) ============
local now = tick()
local lastBoot = getgenv().__autocheat_last_boot or 0
if (now - lastBoot) < 5 then
    warn("[AutoCheat] booted <5s ago, abort duplicate")
    return
end
getgenv().__autocheat_last_boot = now
getgenv().__autocheat_running = true
print("[AutoCheat] booting on PlaceId", game.PlaceId, "JobId", game.JobId)

-- ============ QUEUE-ON-TELEPORT ============
local function queueSelf()
    local fn = queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
        or getgenv().queue_on_teleport
    if fn then
        local ok, err = pcall(fn, SCRIPT_SOURCE)
        print("[AutoCheat] queue_on_teleport:", ok and "OK" or ("FAIL: "..tostring(err)))
    else
        warn("[AutoCheat] queue_on_teleport UNAVAILABLE in this executor")
    end
end
queueSelf()

-- ============ DAMAGE IMMUNITY ============
if not getgenv().__autocheat_hooked then
    getgenv().__autocheat_hooked = true
    if hookmetamethod then
        local oldNC
        oldNC = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            if m == "TakeDamage" and self:IsA("Humanoid") and self.Parent == LP.Character then return end
            return oldNC(self, ...)
        end)
    end
end

-- ============ AUTO JOIN ============
local function autoJoin()
    local pg = LP:WaitForChild("PlayerGui", 30)
    local msg = pg:WaitForChild("MasterScreenGui", 30)
    if not msg then return end
    task.wait(2)

    for attempt = 1, 15 do
        if LP.Character then break end
        print("[AutoJoin] attempt", attempt)

        -- PRIMARY: click PlayButton
        local btn = msg:FindFirstChild("TitleScreen")
        if btn then btn = btn:FindFirstChild("Worlds") end
        if btn then btn = btn:FindFirstChild("PrototypeWorld") end
        if btn then btn = btn:FindFirstChild("PlayButton") end
        if btn and btn.AbsoluteSize.X > 0 then
            local pos = btn.AbsolutePosition + btn.AbsoluteSize/2
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
            print("[AutoJoin] VIM click at", pos.X, pos.Y)
        else
            print("[AutoJoin] button not ready (size:", btn and btn.AbsoluteSize.X, ")")
        end

        task.wait(2)
        if LP.Character then break end

        -- FALLBACK: module calls
        pcall(function()
            local GameState = require(RS.Client.States.GameState)
            GameState.setTitleScreenWindow(nil)
        end)
        pcall(function()
            local PlayersSystem = require(RS.Systems.PlayersSystem)
            PlayersSystem.client_sendRespawnRequest()
        end)
        task.wait(1.5)
    end

    if LP.Character then
        print("[AutoJoin] joined")
    else
        warn("[AutoJoin] FAILED after 15 attempts")
    end
end

-- ============ LOOT TABLE ============
local UtilsItems
pcall(function() UtilsItems = require(RS.Systems.ItemsSystem.UtilsItems) end)
local VALUE_BY_NAME = {
    netherite_sword=1000,netherite_axe=900,netherite_pickaxe=800,netherite_shovel=400,
    netherite_helmet=700,netherite_chestplate=800,netherite_leggings=700,netherite_boots=600,
    netherite_ingot=500,netherite_scrap=300,ancient_debris=250,netherite_block=4500,
    diamond_sword=400,diamond_axe=350,diamond_pickaxe=300,diamond_shovel=200,
    diamond_helmet=250,diamond_chestplate=300,diamond_leggings=250,diamond_boots=200,
    diamond=100,diamond_block=900,diamond_ore=80,
    mythril_sword=350,mythril_axe=300,mythril_pickaxe=250,mythril_ingot=150,mythril_ore=120,
    khepesh=350,fire_sword=400,olmec_hammer=300,mythril_bow=300,bow=80,
    iron_sword=80,iron_axe=70,iron_pickaxe=60,iron_shovel=40,
    iron_helmet=50,iron_chestplate=70,iron_leggings=60,iron_boots=40,
    iron_ingot=30,iron_ore=20,iron_block=270,
    golden_sword=60,golden_axe=50,golden_pickaxe=40,golden_apple=200,
    golden_helmet=40,golden_chestplate=50,golden_leggings=45,golden_boots=35,
    golden_ingot=25,gold_ore=20,
    emerald=120,emerald_block=1080,enchanted_book=200,
}
local VALUE_BY_ID = {}
if UtilsItems and UtilsItems.itemIdFromName then
    for name, val in pairs(VALUE_BY_NAME) do
        local id = UtilsItems.itemIdFromName(name)
        if id then VALUE_BY_ID[id] = val end
    end
end

local function scoreOf(p)
    local invJson = p:GetAttribute("inventory")
    if not invJson then return 0 end
    local ok, inv = pcall(function() return HttpService:JSONDecode(invJson) end)
    if not ok or type(inv) ~= "table" then return 0 end
    local total = 0
    for _, cell in pairs(inv) do
        if type(cell) == "table" and cell.id and cell.id ~= 0 then
            local val = VALUE_BY_ID[cell.id]
            if val then total = total + val * (cell.qty or 1) end
        end
    end
    return total
end

local function findRichest()
    local best, bestScore = nil, MIN_SCORE - 1
    local ranking = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local realHp = p:GetAttribute("health") or 0
            if realHp > 0 then
                local s = scoreOf(p)
                table.insert(ranking, {name=p.Name, score=s})
                if s > bestScore then best, bestScore = p, s end
            end
        end
    end
    table.sort(ranking, function(a,b) return a.score > b.score end)
    print("=== Top targets ===")
    for i, r in ipairs(ranking) do
        if i > 5 then break end
        print(string.format("  #%d %s -> %d", i, r.name, r.score))
    end
    return best, bestScore
end

-- ============ SERVER HOP ============
local function serverHop()
    queueSelf()
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    print("[Hop] searching new server")
    local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
    local success, raw = pcall(function()
        if syn and syn.request then return syn.request({Url=url, Method="GET"}).Body
        elseif http_request then return http_request({Url=url, Method="GET"}).Body
        elseif request then return request({Url=url, Method="GET"}).Body
        elseif fluxus and fluxus.request then return fluxus.request({Url=url, Method="GET"}).Body
        else return game:HttpGet(url) end
    end)
    if not success or not raw then
        print("[Hop] HTTP failed → generic teleport")
        TeleportService:Teleport(placeId, LP)
        return
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or not data.data then
        TeleportService:Teleport(placeId, LP)
        return
    end
    local candidates = {}
    for _, srv in ipairs(data.data) do
        if srv.id ~= currentJobId and srv.playing < srv.maxPlayers then
            table.insert(candidates, srv)
        end
    end
    print("[Hop] "..#candidates.." available servers")
    if #candidates == 0 then
        TeleportService:Teleport(placeId, LP)
        return
    end
    local pick = candidates[math.random(1, math.min(#candidates, 20))]
    print("[Hop] -> "..pick.id)
    pcall(function() TeleportService:TeleportToPlaceInstance(placeId, pick.id, LP) end)
end

-- ============ KILL LOGIC ============
local AttackRemote = RS.Systems.ActionsSystem.Network.Attack

local WEAPON_DMG = {
    wooden_sword=3,stone_sword=4,iron_sword=5,golden_sword=5,
    diamond_sword=6,mythril_sword=6,fire_sword=6,khepesh=6,netherite_sword=7,
    wooden_axe=3,stone_axe=4,iron_axe=5,diamond_axe=6,netherite_axe=7,olmec_hammer=6,
}
local function bestSlot()
    local invJson = LP:GetAttribute("inventory")
    if not invJson then return "1" end
    local ok, inv = pcall(function() return HttpService:JSONDecode(invJson) end)
    if not ok then return "1" end
    local bestS, bestD = nil, 0
    for slot, cell in pairs(inv) do
        if type(cell) == "table" and cell.id and cell.id ~= 0 then
            local name = UtilsItems and UtilsItems.itemNameFromId and UtilsItems.itemNameFromId(cell.id)
            local d = (name and WEAPON_DMG[name]) or 0
            if d > bestD then bestD, bestS = d, tostring(slot) end
        end
    end
    if not bestS then
        for slot, cell in pairs(inv) do
            if type(cell) == "table" and cell.id and cell.id ~= 0 then return tostring(slot) end
        end
        return "1"
    end
    return bestS
end

local function getHRP() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end

local function killAndLoot()
    local target, score = findRichest()
    if not target or score < MIN_SCORE then
        print(string.format("[Main] no worthy target (best %d < %d)", score or 0, MIN_SCORE))
        return "no_target"
    end
    local targetChar = target.Character
    if not targetChar or not targetChar.PrimaryPart then return "failed" end
    print(string.format("[Main] >>> %s score=%d hp=%d", target.Name, score, target:GetAttribute("health") or 0))

    local slot = bestSlot()
    local lastKnownPos = targetChar.PrimaryPart.Position
    local tHum = targetChar:FindFirstChildOfClass("Humanoid")
    local diedConn, ancConn
    if tHum then
        diedConn = tHum.Died:Connect(function()
            if targetChar.PrimaryPart then lastKnownPos = targetChar.PrimaryPart.Position end
        end)
    end
    ancConn = targetChar.AncestryChanged:Connect(function(_, parent)
        if not parent and targetChar.PrimaryPart then lastKnownPos = targetChar.PrimaryPart.Position end
    end)

    local myHRP = getHRP()
    if not myHRP then return "failed" end
    myHRP.CFrame = targetChar.PrimaryPart.CFrame * CFrame.new(0, 2, -2)
    myHRP.AssemblyLinearVelocity = Vector3.zero
    task.wait(REPLICATION_WAIT)
    if targetChar.PrimaryPart then lastKnownPos = targetChar.PrimaryPart.Position end

    local trueCount, falseCount, killed = 0, 0, false
    task.spawn(function()
        for i = 1, 5000 do
            if killed then break end
            task.spawn(function()
                local _, r = pcall(function() return AttackRemote:InvokeServer(targetChar, slot) end)
                if r == true then trueCount = trueCount + 1 else falseCount = falseCount + 1 end
            end)
            local h = getHRP()
            if h and targetChar.PrimaryPart then
                h.CFrame = targetChar.PrimaryPart.CFrame * CFrame.new(0, 2, -2)
                h.AssemblyLinearVelocity = Vector3.zero
            end
            task.wait(SPACING)
        end
    end)

    local t0 = tick()
    while tick() - t0 < MAX_WAIT_FOR_DEATH do
        if targetChar.PrimaryPart then lastKnownPos = targetChar.PrimaryPart.Position end
        local realHp = target:GetAttribute("health") or 0
        if realHp <= 0 or not targetChar.Parent then
            print(string.format("[Main] DOWN %d/%d", trueCount, trueCount+falseCount))
            killed = true
            break
        end
        task.wait(0.05)
    end
    task.wait(0.2)
    if diedConn then diedConn:Disconnect() end
    if ancConn then ancConn:Disconnect() end

    if lastKnownPos then
        local h = getHRP()
        if h then
            h.CFrame = CFrame.new(lastKnownPos + Vector3.new(0, 3, 0))
            print("[Main] looting at", lastKnownPos)
        end
        task.wait(2)
    end
    return killed and "killed" or "failed"
end

-- ============ MAIN ============
task.spawn(function()
    autoJoin()

    local t0 = tick()
    while not LP.Character and tick() - t0 < 30 do task.wait(0.5) end
    if not LP.Character then
        warn("[Main] no character after 30s, hopping")
        serverHop()
        return
    end
    LP.Character:WaitForChild("HumanoidRootPart", 15)
    print("[Main] character ready, waiting "..SCAN_DELAY_AFTER_JOIN.."s for inventories")
    task.wait(SCAN_DELAY_AFTER_JOIN)

    LP.CharacterAdded:Connect(function(c)
        c:WaitForChild("HumanoidRootPart", 10)
        print("[Main] respawned")
    end)

    local kills = 0
    while true do
        local result = killAndLoot()
        if result == "killed" then
            kills = kills + 1
            print("[Main] kills this server:", kills)
            if kills >= MAX_KILLS_BEFORE_HOP then
                task.wait(HOP_DELAY)
                serverHop()
                return
            end
            task.wait(LOOP_DELAY)
        elseif result == "no_target" then
            task.wait(HOP_DELAY)
            serverHop()
            return
        else
            task.wait(LOOP_DELAY)
        end
    end
end)

print("[AutoCheat] loaded — kill loop active")
