local CONTROLLER_ID = 9822837105
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local Debris = game:GetService("Debris")

local adminNameFallback = nil
local admins = {}
local cmdprefix = "!"
local scriptprefix = "\\"
local split = " "

local function std_inTable(tbl, val)
    if tbl == nil then return false end
    for _, v in pairs(tbl) do if v == val then return true end end
    return false
end

local function findPlayerByName(name)
    if not name or name == "" then return nil end
    local nameLower = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find("^"..nameLower) or p.DisplayName:lower():find("^"..nameLower) then
            return p
        end
    end
    return nil
end

local function getPlayerNames(name)
    local nameTable = {}
    name = (name or ""):lower()
    if name == "me" then
        if adminNameFallback then table.insert(nameTable, adminNameFallback) end
    elseif name == "others" then
        for _, v in pairs(Players:GetPlayers()) do if v.Name ~= adminNameFallback then table.insert(nameTable, v.Name) end end
    elseif name == "all" then
        for _, v in pairs(Players:GetPlayers()) do table.insert(nameTable, v.Name) end
    else
        for _, v in pairs(Players:GetPlayers()) do
            local lname = v.Name:lower()
            local i = lname:find(name, 1, true)
            if i == 1 then return { v.Name } end
        end
    end
    return nameTable
end

local function notifyPlayer(player, message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Control System",
            Text = message,
            Icon = "rbxassetid://0",
            Duration = 5
        })
    end)
end

local function isOwner(player)
    if not player then return false end
    return (player.UserId == CONTROLLER_ID)
end

local function isAdminByName(name)
    if not name then return false end
    if adminNameFallback and name == adminNameFallback then return true end
    if admins[name] then return true end
    return false
end

local cmds = {}
local function addcmd(name, desc, alias, func) cmds[#cmds + 1] = { NAME = name; DESC = desc; ALIAS = alias or {}; FUNC = func; } end

local function findCmd(cmd_name)
    for _, v in pairs(cmds) do
        if v.NAME:lower() == cmd_name:lower() then return v end
        for _, a in pairs(v.ALIAS or {}) do if a:lower() == cmd_name:lower() then return v end end
    end
    return nil
end

local function std_endat(str, val)
    local z = str:find(val, 1, true)
    if z then return str:sub(1, z - #val), true else return str, false end
end

local function getCmdName(msg)
    local cmd, hassplit = std_endat(msg:lower(), split)
    if hassplit then return { cmd, true } else return { cmd, false } end
end

local function getArgsFromString(str)
    local args = {}
    local s = str
    while true do
        local new_arg, hassplit = std_endat(s, split)
        if new_arg ~= '' then
            table.insert(args, new_arg)
            if not hassplit then break end
            s = s:sub(#new_arg + #split + 1)
        else break end
    end
    return args
end

local function execCmd(str, plr)
    local s_cmd = getCmdName(str)
    local cmd = findCmd(s_cmd[1])
    if not cmd then return end
    local a = str:sub(#s_cmd[1] + #split + 1)
    local args = {}
    if a and #a > 0 then args = getArgsFromString(a) end
    pcall(function() cmd.FUNC(args, plr) end)
end

local function execString(str)
    local f, err = loadstring(str)
    if not f then warn("loadstring error:", err) return end
    pcall(f)
end

local function getprfx(strn)
    if strn:sub(1, #cmdprefix) == cmdprefix then return {'cmd', #cmdprefix + 1} end
    if strn:sub(1, #scriptprefix) == scriptprefix then return {'exec', #scriptprefix + 1} end
    return nil
end

local function do_exec(str, plr)
    if not isOwner(plr) then return end
    str = str:gsub('/e ', '')
    local t = getprfx(str)
    if not t then return end
    str = str:sub(t[2])
    if t[1] == 'exec' then execString(str) elseif t[1] == 'cmd' then execCmd(str, plr) end
end

local function updateEvents()
    for _, p in pairs(Players:GetPlayers()) do
        p.Chatted:Connect(function(msg)
            if msg:sub(1,1) == cmdprefix or msg:sub(1,1) == scriptprefix then do_exec(msg, p) end
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if isOwner(p) then adminNameFallback = p.Name; notifyPlayer(p, "You are the owner! Use !help for commands") end
    p.Chatted:Connect(function(msg) if msg:sub(1,1) == cmdprefix or msg:sub(1,1) == scriptprefix then do_exec(msg, p) end end)
end)

for _, p in pairs(Players:GetPlayers()) do if isOwner(p) then adminNameFallback = p.Name break end end

_G.exec_cmd = execCmd

addcmd('ff','gives ff to player',{},function(args) local players = getPlayerNames(args[1]) for i,v in pairs(players)do local target = Players:FindFirstChild(v) if target and target.Character then Instance.new("ForceField", target.Character) end end end)
addcmd('unff','takes away ff from player',{},function(args) local players = getPlayerNames(args[1]) for i,v in pairs(players)do local target = Players:FindFirstChild(v) if target and target.Character then for _,c in pairs(target.Character:GetChildren()) do if c:IsA("ForceField") then c:Destroy() end end end end end)
addcmd('fire','set a player on fire',{},function(args) local players = getPlayerNames(args[1]) local r = tonumber(args[2]) or 1 local g = tonumber(args[3]) or 0 local b = tonumber(args[4]) or 0 for _,v in pairs(players)do local target = Players:FindFirstChild(v) if target and target.Character then local ch = target.Character local function makeFire(part) if part and part:IsA("BasePart") then local f = Instance.new("Fire", part) f.Color = Color3.new(r,g,b) f.SecondaryColor = Color3.new(r,g,b) end end makeFire(ch:FindFirstChild("Head")) makeFire(ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso")) makeFire(ch:FindFirstChild("Left Arm") or ch:FindFirstChild("LeftUpperArm")) makeFire(ch:FindFirstChild("Right Arm") or ch:FindFirstChild("RightUpperArm")) makeFire(ch:FindFirstChild("Left Leg") or ch:FindFirstChild("LeftLowerLeg")) makeFire(ch:FindFirstChild("Right Leg") or ch:FindFirstChild("RightLowerLeg")) end end end)
addcmd('nofire','extinguish a player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local target = Players:FindFirstChild(v) if target and target.Character then for _,part in pairs(target.Character:GetChildren()) do if part:IsA("Fire") then part:Destroy() end end end end end)
addcmd('sparkles','give a player sparkles',{},function(args) local players = getPlayerNames(args[1]) local r = tonumber(args[2]) or 1 local g = tonumber(args[3]) or 1 local b = tonumber(args[4]) or 1 for _,v in pairs(players)do local target = Players:FindFirstChild(v) if target and target.Character then local ch = target.Character local function newSpark(part) if part and part:IsA("BasePart") then local s = Instance.new("Sparkles", part) pcall(function() s.Color = Color3.new(r,g,b) end) end end newSpark(ch:FindFirstChild("Head")) newSpark(ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso")) newSpark(ch:FindFirstChild("Left Arm") or ch:FindFirstChild("LeftUpperArm")) newSpark(ch:FindFirstChild("Right Arm") or ch:FindFirstChild("RightUpperArm")) newSpark(ch:FindFirstChild("Left Leg") or ch:FindFirstChild("LeftLowerLeg")) newSpark(ch:FindFirstChild("Right Leg") or ch:FindFirstChild("RightLowerLeg")) end end end)
addcmd('nosparkles','remove sparkles from a player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local target = Players:FindFirstChild(v) if target and target.Character then for _,c in pairs(target.Character:GetChildren()) do if c:IsA("Sparkles") then c:Destroy() end end end end end)
addcmd('smoke','give a player smoke',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local t = Players:FindFirstChild(v) if t and t.Character and (t.Character:FindFirstChild("Torso") or t.Character:FindFirstChild("UpperTorso")) then local torso = t.Character:FindFirstChild("Torso") or t.Character:FindFirstChild("UpperTorso") Instance.new("Smoke", torso) end end end)
addcmd('unsmoke','remove smoke from a player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local t = Players:FindFirstChild(v) if t and t.Character then for _,c in pairs(t.Character:GetChildren()) do if c:IsA("Smoke") then c:Destroy() end end end end end)
addcmd('btools','gives a player btools',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t:FindFirstChild("Backpack") then local hb = Instance.new("HopperBin", t.Backpack) hb.BinType = 2 local hb2 = Instance.new("HopperBin", t.Backpack) hb2.BinType = 3 local hb3 = Instance.new("HopperBin", t.Backpack) hb3.BinType = 4 end end end)
addcmd('devuzi','dev uzi',{},function(args) end)
addcmd('god','gods player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.MaxHealth = math.huge end end end end)
addcmd('sgod','silently god player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local t = Players:FindFirstChild(v) if t and t.Character then spawn(function() local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.MaxHealth = 10000000 wait() hum.Health = 10000000 end end) end end end)
addcmd('ungod','removes god from a player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.MaxHealth = 100 hum.Health = 100 end end end end)
addcmd('heal','resets a players health',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.Health = hum.MaxHealth end end end end)
addcmd('decalspam','decal spam',{},function(args) local id = args[1] if not id then return end local function exPro(root) for _, obj in pairs(root:GetChildren()) do if obj:IsA("Decal") and obj.Texture ~= "http://www.roblox.com/asset/?id="..id then obj.Parent = nil elseif obj:IsA("BasePart") then obj.Material = "Plastic" obj.Transparency = 0 for i=1,6 do local d = Instance.new("Decal", obj) d.Texture = "http://www.roblox.com/asset/?id="..id end end exPro(obj) end end exPro(game.Workspace) end)
addcmd('sky','sets the sky',{},function(args) local s = Instance.new("Sky") s.Name = "Sky" s.Parent = game.Lighting local skyboxID = args[1] if skyboxID then s.SkyboxBk = "http://www.roblox.com/asset/?id="..skyboxID s.SkyboxDn = "http://www.roblox.com/asset/?id="..skyboxID s.SkyboxFt = "http://www.roblox.com/asset/?id="..skyboxID s.SkyboxLf = "http://www.roblox.com/asset/?id="..skyboxID s.SkyboxRt = "http://www.roblox.com/asset/?id="..skyboxID s.SkyboxUp = "http://www.roblox.com/asset/?id="..skyboxID game.Lighting.TimeOfDay = 12 end end)
addcmd('freeze','freezes a player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and (t.Character:FindFirstChild("Torso") or t.Character:FindFirstChild("UpperTorso")) then local torso = t.Character:FindFirstChild("Torso") or t.Character:FindFirstChild("UpperTorso") torso.Anchored = true end end end)
addcmd('thaw','unfreezes a player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and (t.Character:FindFirstChild("Torso") or t.Character:FindFirstChild("UpperTorso")) then local torso = t.Character:FindFirstChild("Torso") or t.Character:FindFirstChild("UpperTorso") torso.Anchored = false end end end)
addcmd('kill','kills a player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.MaxHealth = 0 hum.Health = 0 end end end end)
addcmd('sound','plays a sound',{},function(args) local function dels(instance) for _,c in pairs(instance:GetChildren()) do if c:IsA("Sound") then c:Destroy() end dels(c) end end dels(workspace) local c = args[1] or 'stop' if c:lower() == 'stop' then return end local s = Instance.new("Sound", workspace) s.Name = "IYsound" s.Looped = true s.SoundId = "rbxassetid://" .. c s.Volume = 1 s:Play() end)
addcmd('volume','changes volume of sound',{},function(args) for _,v in pairs(game.Workspace:GetChildren()) do if v:IsA("Sound") and v.Name == "IYsound" then v.Volume = tonumber(args[1]) end end end)
addcmd('pitch','changes pitch of sound',{},function(args) for _,v in pairs(game.Workspace:GetChildren()) do if v:IsA("Sound") and v.Name == "IYsound" then v.Pitch = tonumber(args[1]) end end end)
addcmd('explode','explode a player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local char = Players:FindFirstChild(v) if char and char.Character and char.Character:FindFirstChild("Torso") then local e = Instance.new("Explosion") e.Position = char.Character.Torso.Position e.Parent = workspace end end end)
addcmd('flood','makes a flood',{},function(args) workspace.Terrain:SetCells(Region3int16.new(Vector3int16.new(-100,-100,-100), Vector3int16.new(100,100,100)), 17, "Solid", "X") end)
addcmd('spookyify','makes it spooky',{},function(args) local music = Instance.new("Sound", workspace) music.SoundId = "http://www.roblox.com/asset/?id=257569267" music.Volume = 20 music.Looped = true music:Play() local textures = {"http://www.roblox.com/asset/?id=185495987","http://www.roblox.com/asset/?id=260858020","http://www.roblox.com/asset/?id=149213919","http://www.roblox.com/asset/?id=171905673"} for _,obj in pairs(workspace:GetChildren()) do if obj:IsA("BasePart") then local pe = Instance.new("ParticleEmitter", obj) pe.Texture = textures[4] pe.VelocitySpread = 5 end end local playerLeaderstats = {} for i, v in pairs(game.Players:GetChildren()) do table.insert(playerLeaderstats, v) end for i, v in pairs(playerLeaderstats) do if v.Character and v.Character:FindFirstChild("Torso") then local pe = Instance.new("ParticleEmitter",v.Character.Torso) pe.Texture = "http://www.roblox.com/asset/?id=171905673" pe.VelocitySpread = 50 end end local texture = "http://www.roblox.com/asset/?id=185495987" local images = {169585459,169585475,169585485,169585502,169585515,169585502,169585485,169585475} local Sky = Instance.new("Sky", game.Lighting) for i=1,#workspace:GetChildren() do end spawn(function() while true do for _,img in ipairs(images) do pcall(function() Sky.SkyboxBk = "http://www.roblox.com/asset/?id="..img Sky.SkyboxDn = "http://www.roblox.com/asset/?id="..img Sky.SkyboxFt = "http://www.roblox.com/asset/?id="..img Sky.SkyboxLf = "http://www.roblox.com/asset/?id="..img Sky.SkyboxRt = "http://www.roblox.com/asset/?id="..img Sky.SkyboxUp = "http://www.roblox.com/asset/?id="..img end) wait(0.15) end end end) end)
addcmd('loopheal','loop heals player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then local pchar = t.Character if pchar:FindFirstChild("LoopHeal") then pchar.LoopHeal.Name = "NotLoopHeal" wait(0.1) pchar.NotLoopHeal:Destroy() end local LoopHeal = Instance.new("StringValue", pchar) LoopHeal.Name = "LoopHeal" repeat wait(0.1) local hum = pchar:FindFirstChildOfClass("Humanoid") if hum then hum.Health = hum.MaxHealth end until LoopHeal.Name == "NotLoopHeal" end end end)
addcmd('unloopheal','stops loop heal',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and t.Character:FindFirstChild("LoopHeal") then t.Character.LoopHeal.Name = "NotLoopHeal" wait(0.1) t.Character.NotLoopHeal:Destroy() end end end)
addcmd('fling','flings player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and t.Character:FindFirstChild("Humanoid") then local pchar = t.Character local xran local zran repeat xran = math.random(-9999,9999) until math.abs(xran) >= 5555 repeat zran = math.random(-9999,9999) until math.abs(zran) >= 5555 pchar.Humanoid.Sit = true if pchar:FindFirstChild("Torso") then pchar.Torso.Velocity = Vector3.new(0,0,0) local BF = Instance.new("BodyForce", pchar.Torso) BF.Force = Vector3.new(xran * 4, 9999 * 5, zran * 4) end end end end)
addcmd('nograv','makes player have moon gravity',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and t.Character:FindFirstChild("Torso") then for _,c in pairs(t.Character.Torso:GetChildren()) do if c.Name == "NoGrav" then c:Destroy() end end local BF = Instance.new("BodyForce", t.Character.Torso) BF.Name = "NoGrav" BF.Force = Vector3.new(0,2700,0) end end end)
addcmd('grav','restore grav',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and t.Character:FindFirstChild("Torso") then for _,c in pairs(t.Character.Torso:GetChildren()) do if c.Name == "NoGrav" then c:Destroy() end end end end end)
addcmd('seizure','makes player have a seizure',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then local pchar = t.Character if pchar:FindFirstChild("Seizure") then end local Seizure = Instance.new("StringValue", pchar) Seizure.Name = "Seizure" pchar.Humanoid.PlatformStand = true repeat wait() if pchar:FindFirstChild("Torso") then pchar.Torso.Velocity = Vector3.new(math.random(-10,10),-5,math.random(-10,10)) pchar.Torso.RotVelocity = Vector3.new(math.random(-5,5),math.random(-5,5),math.random(-5,5)) end until Seizure.Name == "NotSeizure" end end end)
addcmd('unseizure','stops seizure',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and t.Character:FindFirstChild("Seizure") then t.Character.Humanoid.PlatformStand = false t.Character.Seizure.Name = "NotSeizure" wait(0.1) t.Character.NotSeizure:Destroy() end end end)
addcmd('wtrbtools','wtrbtools',{},function(args) local assets = {73089166,73089204,73089190,58880579,60791062} for _,id in pairs(assets) do pcall(function() local x = InsertService:LoadAsset(id) for _,c in pairs(x:GetChildren()) do if Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("Backpack") then c.Parent = Players.LocalPlayer.Backpack end end x:Destroy() end) end end)
addcmd('sphere','puts sphere around player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then local SS = Instance.new("SelectionSphere", t.Character) SS.Adornee = SS.Parent end end end)
addcmd('loadmap','loads map',{},function(args) pcall(function() for i,v in pairs(workspace:GetChildren()) do if v.Name ~= "Camera" and v.Name ~= "Terrain" then v:Destroy() end end workspace.Terrain:Clear() for i,v in pairs(game.Players:GetChildren()) do local prt = Instance.new("Model", workspace) prt.Name = v.Name Instance.new("Part", prt).Name="Torso" Instance.new("Part", prt).Name="Head" Instance.new("Humanoid", prt).Name="Humanoid" v.Character = prt end if args[1] then local b = InsertService:LoadAsset(tonumber(args[1])) b.Parent = workspace b:MakeJoints() end end) end)
addcmd('ambient','changes ambient',{},function(args) game.Lighting.Ambient = Color3.new(tonumber(args[1]) or 1, tonumber(args[2]) or 1, tonumber(args[3]) or 1) end)
addcmd('gui','gives GUI',{},function(args) if args[1] then pcall(function() loadstring(InsertService:LoadAsset(tonumber(args[1])).Source)() end) end end)
addcmd('jail','jails player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players)do local t = Players:FindFirstChild(v) if t and t.Character and DATA and DATA.JAIL then local JailPlayer = DATA.JAIL:Clone() JailPlayer.Parent = workspace JailPlayer:MoveTo(t.Character.Torso.Position) JailPlayer.Name = "JAIL_" .. t.Name if t.Character:FindFirstChild("HumanoidRootPart") then t.Character.HumanoidRootPart.CFrame = JailPlayer.MAIN.CFrame end end end end)
addcmd('unjail','unjails player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do pcall(function() workspace["JAIL_" .. v]:Destroy() end) end end)
addcmd('shutdown','shuts the server down',{},function(args) for i,v in pairs(game.Players:GetPlayers()) do pcall(function() v:Kick("Server shutting down") end) end end)
addcmd('animation','animates player',{},function(args) local players = getPlayerNames(args[1]) local id = args[2] for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum and id then pcall(function() hum:LoadAnimation(Instance.new("Animation", hum)).AnimationId = "rbxassetid://"..id end) end end end end)
addcmd('thirdp','third person',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t then t.CameraMode = "Classic" end end end)
addcmd('chat','forces player to chat',{},function(args) local players = getPlayerNames(args[1]) local MSG = table.concat(args, " ") local newMSG = string.gsub(MSG, args[1] .. " ", "") for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and t.Character:FindFirstChild("Head") then game.Chat:Chat(t.Character.Head, newMSG) end end end)
addcmd('insert','inserts a model',{},function(args) if args[1] then local model = InsertService:LoadAsset(tonumber(args[1])) model.Parent = workspace end end)
addcmd('name','names player',{},function(args) local players = getPlayerNames(args[1]) local msg = table.concat(args, " ") local newmsg = string.gsub(msg, args[1] .. " ", "") for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then for _,mod in pairs(t.Character:GetChildren()) do if mod:FindFirstChild("TAG") then t.Character.Head.Transparency = 0 mod:Destroy() end end local char = t.Character local model = Instance.new("Model", char) model.Name = newmsg local clone = char.Head:Clone() local hum = Instance.new("Humanoid", model) hum.Name = "TAG" hum.MaxHealth = 100 hum.Health = 100 local weld = Instance.new("Weld", clone) clone.Parent = model weld.Part0 = clone weld.Part1 = char.Head char.Head.Transparency = 1 end end end)
addcmd('unname','unnames player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then for _,mod in pairs(t.Character:GetChildren()) do if mod:FindFirstChild("TAG") then t.Character.Head.Transparency = 0 mod:Destroy() end end end end end)
addcmd('stun','stuns player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.PlatformStand = true end end end end)
addcmd('unstun','unstuns player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.PlatformStand = false end end end end)
addcmd('sit','sit player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.Sit = true end end end end)
addcmd('confuse','confuse',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed = -16 end end end end)
addcmd('unconfuse','unconfuse',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then local hum = t.Character:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed = 16 end end end end)
addcmd('clone','clones player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then t.Character.Archivable = true local clone = t.Character:Clone() clone.Parent = workspace clone:MoveTo(t.Character:GetModelCFrame().p) clone:MakeJoints() t.Character.Archivable = false end end end)
addcmd('spin','spins player',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and t.Character:FindFirstChild("Torso") then local Torso = t.Character.Torso for _,c in pairs(Torso:GetChildren()) do if c.Name == "Spinning" then c:Destroy() end end local BG = Instance.new("BodyGyro", Torso) BG.Name = "Spinning" BG.maxTorque = Vector3.new(0, math.huge, 0) BG.P = 11111 BG.cframe = Torso.CFrame repeat wait(1/44) BG.CFrame = BG.CFrame * CFrame.Angles(0,math.rad(30),0) until not BG or BG.Parent ~= Torso end end end)
addcmd('unspin','unspin',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character and t.Character:FindFirstChild("Torso") then for _,c in pairs(t.Character.Torso:GetChildren()) do if c.Name == "Spinning" then c:Destroy() end end end end end)
addcmd('dog','dogify',{},function(args) local players = getPlayerNames(args[1]) for _,v in pairs(players) do local t = Players:FindFirstChild(v) if t and t.Character then for _,c in pairs(t.Character:GetChildren()) do if c:IsA("Hat") then c:Destroy() end end end end end)
addcmd('admin','gives a player admin',{},function(args) if not args[1] then return end local players = getPlayerNames(args[1]) for _,v in pairs(players) do admins[v] = true end end)
addcmd('unadmin','removes admin',{},function(args) if not args[1] then return end local players = getPlayerNames(args[1]) for _,v in pairs(players) do admins[v] = nil end end)
addcmd('help','shows commands',{},function(args, plr) local names = {} for _, v in pairs(cmds) do table.insert(names, v.NAME) end if plr then notifyPlayer(plr, "Commands: "..table.concat(names, ", ")) else print("Commands: "..table.concat(names, ", ")) end end)

addcmd('partner','attach player1 to player2',{},function(args) if not args[1] or not args[2] then return end local list1 = getPlayerNames(args[1]) local list2 = getPlayerNames(args[2]) for _,v in pairs(list1) do for _,u in pairs(list2) do local pl1 = Players:FindFirstChild(v) local pl2 = Players:FindFirstChild(u) if pl1 and pl1.Character and pl2 and pl2.Character and pl1.Character:FindFirstChild("HumanoidRootPart") and pl2.Character:FindFirstChild("HumanoidRootPart") then local weld = Instance.new("Weld") weld.Name = "PartnerWeld_"..pl2.Name weld.Part0 = pl1.Character:FindFirstChild("HumanoidRootPart") weld.Part1 = pl2.Character:FindFirstChild("HumanoidRootPart") weld.C0 = CFrame.new(0,0,0) weld.Parent = pl1.Character:FindFirstChild("HumanoidRootPart") end end end end)

addcmd('unpartner','remove partner welds',{},function(args) local target = args[1] or "all" local list = {} if target == "all" then for _,p in pairs(Players:GetPlayers()) do table.insert(list, p.Name) end else list = getPlayerNames(target) end for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then for _,w in pairs(pl.Character.HumanoidRootPart:GetChildren()) do if w:IsA("Weld") and tostring(w.Name):match("^PartnerWeld_") then pcall(function() w:Destroy() end) end end end end end)

addcmd('shrekify','shrekify a player',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character then for _,part in pairs(pl.Character:GetChildren()) do if part:IsA("BasePart") then part.BrickColor = BrickColor.new("Earth green") part.Material = Enum.Material.SmoothPlastic end end end end end)
addcmd('unshrek','restore player appearance',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character then for _,part in pairs(pl.Character:GetChildren()) do if part:IsA("BasePart") then part.BrickColor = BrickColor.new("Medium stone grey") part.Material = Enum.Material.Plastic end end end end end)

addcmd('ghost','make player ghost',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character then for _,c in pairs(pl.Character:GetChildren()) do if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" then c.Transparency = 0.7 c.CanCollide = false end end end end end)
addcmd('unghost','undo ghost',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character then for _,c in pairs(pl.Character:GetChildren()) do if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" then c.Transparency = 0 c.CanCollide = true end end end end end)

addcmd('shrink','make player tiny',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character then for _,part in pairs(pl.Character:GetChildren()) do if part:IsA("BasePart") then part.Size = part.Size * 0.5 end end end end end)
addcmd('giant','make player big',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character then for _,part in pairs(pl.Character:GetChildren()) do if part:IsA("BasePart") then part.Size = part.Size * 2 end end end end end)
addcmd('normalsize','restore size',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character then pcall(function() pl.Character:WaitForChild("Humanoid").HipHeight = 2 end) end end end)

addcmd('rainbow','start rainbow body',{},function(args) local target = args[1] or "all" local function startOn(player) if not player or not player.Character then return end spawn(function() while player and player.Character and player.Character.Parent do for i=1,360 do local col = Color3.fromHSV(i/360,1,1) for _,part in pairs(player.Character:GetChildren()) do if part:IsA("BasePart") then pcall(function() part.Color = col end) end end wait(0.05) end end end) end if target == "all" then for _,p in pairs(Players:GetPlayers()) do startOn(p) end else local list = getPlayerNames(target) for _,name in pairs(list) do startOn(Players:FindFirstChild(name)) end end end)
addcmd('unrainbow','stop rainbow',{},function(args) local target = args[1] or "all" for _,p in pairs(Players:GetPlayers()) do if target == "all" or table.find(getPlayerNames(target), p.Name) then for _,part in pairs(p.Character and p.Character:GetChildren() or {}) do if part:IsA("BasePart") then pcall(function() part.Color = Color3.new(0.8,0.8,0.8) end) end end end end end)

addcmd('fly','toggle fly for player',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then local root = pl.Character.HumanoidRootPart if root:FindFirstChild("FlyBV") then pcall(function() root.FlyBV:Destroy() root.FlyBG:Destroy() end) else local bv = Instance.new("BodyVelocity", root); bv.Name = "FlyBV"; bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Velocity = Vector3.new(0,0,0) local bg = Instance.new("BodyGyro", root); bg.Name = "FlyBG"; bg.MaxTorque = Vector3.new(1e5,1e5,1e5); bg.CFrame = root.CFrame end end end end)

addcmd('noclip','make player noclip',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character then for _,part in pairs(pl.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = false end end end end end)
addcmd('clip','restore collisions',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character then for _,part in pairs(pl.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = true end end end end end)

addcmd('smite','smite player with lightning',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character and (pl.Character:FindFirstChild("Torso") or pl.Character:FindFirstChild("HumanoidRootPart")) then local pos = (pl.Character:FindFirstChild("HumanoidRootPart") or pl.Character:FindFirstChild("Torso")).Position local ex = Instance.new("Explosion", workspace) ex.Position = pos ex.BlastRadius = 6 ex.BlastPressure = 500000 end end end)
addcmd('nuke','nuke area around player',{},function(args) local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then local center = pl.Character.HumanoidRootPart.Position for i=1,6 do local ex = Instance.new("Explosion", workspace) ex.Position = center + Vector3.new(math.random(-10,10), math.random(0,10), math.random(-10,10)) ex.BlastRadius = 12 + i*2 ex.BlastPressure = 1000000 + i*500000 wait(0.15) end end end end)
addcmd('burnall','set everyone on fire',{},function(args) for _,p in pairs(Players:GetPlayers()) do if p and p.Character then for _,obj in pairs(p.Character:GetChildren()) do if obj:IsA("BasePart") then local f = Instance.new("Fire", obj) f.Heat = 10 f.Size = 5 end end end end end)

addcmd('discoext','disco lights and music',{},function(args) local music = Instance.new("Sound", workspace) music.SoundId = "rbxassetid://184748789" music.Looped = true; music.Volume = 3; music:Play() spawn(function() while music.Parent do local r,g,b = math.random(),math.random(),math.random() pcall(function() game.Lighting.Ambient = Color3.new(r,g,b) end) wait(0.3) end end) end)

addcmd('fart','play fart sound on player',{},function(args) local id = args[2] or "142070127" local list = getPlayerNames(args[1]) for _,name in pairs(list) do local pl = Players:FindFirstChild(name) if pl and pl.Character and pl.Character:FindFirstChild("Head") then local s = Instance.new("Sound", pl.Character.Head) s.SoundId = "rbxassetid://"..id s.Volume = 5 s:Play() Debris:AddItem(s, 6) end end end)

addcmd('admins','list admins',{},function(args) local t = {} for n,v in pairs(admins or {}) do if v then table.insert(t, n) end end if #t == 0 then print("No admins set.") else print("Admins: "..table.concat(t, ", ")) end end)
addcmd('bans','list bans',{},function(args) if _G.BannedPlayers then print("Banned players: "..table.concat(_G.BannedPlayers, ", ")) else print("No ban list found.") end end)
addcmd('cmdsfull','list cmds (full)',{},function(args) local names = {} for _, v in pairs(cmds) do table.insert(names, v.NAME) end print("Commands: "..table.concat(names, ", ")) end)
addcmd('prefix','change command prefix',{},function(args) local p = args[1] if not p then return end cmdprefix = p print("Prefix changed to: "..p) end)
addcmd('version','show version',{},function(args) print("Control System - full combined script") end)
addcmd('restoreenv','restore lighting & remove global effects',{},function(args) pcall(function() if game and game.Lighting then local L = game.Lighting if L and L:IsA("Lighting") then if L.Default then end end end for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Fire") or v:IsA("Explosion") or v:IsA("ParticleEmitter") then pcall(function() v:Destroy() end) end end end) end)

print("Unified control system activated! Prefix is '"..cmdprefix.."'")
print("Controller ID: "..tostring(CONTROLLER_ID))
updateEvents()
