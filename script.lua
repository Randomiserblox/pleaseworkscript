local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local state = { busy = false, hatchClick = false, eggAmount = 1, inMinigame = false }
local petState = { active = 1 }

local taskState = {
babyEnabled = true,
petEnabled = true,
baby = {
thirsty = true, hungry = true, sleep = true, bath = true,
potty = true, drink = true, eat = true, school = true,
hospital = true, walk = true, ride = true, playground = true,
beach = true, pizza = true, salon = true, campfire = true, cafe = true
},
pet = { pet = true, groom = true, vet = true, fetch = true }
}

local config = {
ghostHunt = true, aimbot = true, autoShoot = true,
autoCollect = true, autoHatch = false, antiAfk = true,
preEventTP = true, babyTasks = true, petTasks = true,
stealthTP = true, cafeTask = true
}

local blockList = { "mystery task", "fetch", "pet" }

local eventZones = {
HauntedMansion = Vector3.new(-5982.613, 10011.106, 9000.880),
CandyVillage = Vector3.new(-2980.047, 4013.270, 5700.248),
PumpkinPatch = Vector3.new(-543.291, 30.475, -1475.572),
WitchTower = Vector3.new(-377.687, 30.960, -1739.829)
}

local farmZones = {
NeonCave = Vector3.new(-3000.868, 7015.486, -5967.612),
FarmShop = Vector3.new(9011.949, 7024.597, 11939.585),
PetPark = Vector3.new(-5995.293, 10042.011, -6024.516),
ToyShop = Vector3.new(-11976.980, 7011.490, -9003.754)
}

local taskZones = {
Fridge = Vector3.new(-5978.937, 4003.617, -17.963),
Shower = Vector3.new(-5992.900, 4003.724, -16.749),
Bed = Vector3.new(-5979.668, 4003.994, -9.075),
Toilet = Vector3.new(-5988.659, 4003.882, -24.019),
Eat = Vector3.new(-5978.937, 4003.617, -17.963),
Drink = Vector3.new(-5978.047, 4003.617, -21.606),
School = Vector3.new(-377.687, 30.960, -1739.829),
Hospital = Vector3.new(-2980.047, 4013.270, 5700.248),
Campfire = Vector3.new(-36.025, 37.444, -1046.458),
Crypt = Vector3.new(-11976.980, 7011.490, -9003.754),
BeachParty = Vector3.new(-543.291, 30.475, -1475.572),
Playground = Vector3.new(-377.687, 30.960, -1739.829),
Pizza = Vector3.new(-3000.868, 7015.486, -5967.612),
Salon = Vector3.new(9011.949, 7024.597, 11939.585),
CatCafe = Vector3.new(-5995.293, 10042.011, -6024.516),
PetBed = Vector3.new(-5979.668, 4003.994, -9.075),
PetBowl = Vector3.new(-5978.937, 4003.617, -17.963),
CafeStand = Vector3.new(-3000.868, 7015.486, -5967.612)
}

local minigameCenter = Vector3.new(-5982.613, 10011.106, 9000.880)
local minigameRadius = 800

local taskMap = {
thirsty="Fridge", hungry="Eat", sleep="Bed", bath="Shower",
school="School", hospital="Hospital", vet="Hospital",
groom="PetBed", pet="PetBowl", cafe="CafeStand",
walk="Walk", ride="Ride", potty="Toilet", drink="Drink",
pizza="Pizza", salon="Salon", campfire="Campfire",
beach="BeachParty", playground="Playground"
}

local petTasksList = {"pet","groom","vet","fetch"}

local function getHRP()
local c = LocalPlayer.Character
return c and c:FindFirstChild("HumanoidRootPart")
end

local function inMinigame()
local h = getHRP()
if not h then return false end
return (h.Position - minigameCenter).Magnitude < minigameRadius
end

local function safeTP(pos)
if config.stealthTP then
for _, p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
if (p.Character.HumanoidRootPart.Position - pos).Magnitude < 60 then return end
end
end
local h = getHRP()
if h then TweenService:Create(h, TweenInfo.new(0.8), {CFrame = CFrame.new(pos + Vector3.new(0,4,0))}):Play() end
else
local h = getHRP()
if h then h.CFrame = CFrame.new(pos + Vector3.new(0,4,0)) end
end
end

local function walkTask()
local h = getHRP()
if not h then return end
local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if not humanoid then return end
for i = 1, 8 do
if inMinigame() then return end
local target = h.Position + Vector3.new(math.random(-40,40), 0, math.random(-40,40))
humanoid:MoveTo(target)
task.wait(1.5)
end
end

local function rideTask()
local h = getHRP()
if not h then return end
for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
if t.Name:lower():find("stroller") then
t.Parent = LocalPlayer.Character
task.wait(0.5)
pcall(function() t:Activate() end)
break
end
end
local count = 0
for _, p in pairs(workspace:GetDescendants()) do
if count >= petState.active then break end
if p.Name:lower():find("pet") and p:IsA("Model") then
local hrp = p:FindFirstChild("HumanoidRootPart") or p:FindFirstChildWhichIsA("BasePart", true)
if hrp and (hrp.Position - h.Position).Magnitude < 30 then
for _, d in pairs(p:GetDescendants()) do
if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
if d:IsA("ClickDetector") then pcall(fireclickdetector, d) end
end
count = count + 1
end
end
end
end

local function getGhosts()
local g = {}
for _, o in pairs(workspace:GetDescendants()) do
local n = o.Name:lower()
if n:find("ghost") or n:find("spirit") or n:find("phantom") then
if o:IsA("Model") and o:FindFirstChild("HumanoidRootPart") then
o.HumanoidRootPart.Transparency = 0.5; table.insert(g, o)
elseif o:IsA("BasePart") then
o.Transparency = 0.5; table.insert(g, o)
end
end
end
return g
end

local function aim(t)
local h = getHRP(); if not h then return end
local p = t:IsA("Model") and t.HumanoidRootPart.Position or t.Position
local cam = workspace.CurrentCamera
cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, p), 0.25)
end

local function shoot(t)
if math.random() < 0.15 then return end
local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
if not tool then
for _, x in pairs(LocalPlayer.Backpack:GetChildren()) do
if x:IsA("Tool") then x.Parent = LocalPlayer.Character; tool = x; break end
end
end
if tool then aim(t); task.wait(math.random(15,40)/100); pcall(function() tool:Activate() end) end
end

local function collect()
for _, o in pairs(workspace:GetDescendants()) do
local n = o.Name:lower()
if n:find("soul") or n:find("reward") or n:find("token") or n:find("candy") or n:find("crypt key") then
local h = o:FindFirstChild("Handle") or o
local hrp = getHRP()
if h and h:IsA("BasePart") and hrp and (hrp.Position - h.Position).Magnitude < 80 then
firetouchinterest(hrp, h, 0); firetouchinterest(hrp, h, 1)
end
end
end
end

local function hatch()
if not state.hatchClick then return end
for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
if t.Name:lower():find("egg") then
t.Parent = LocalPlayer.Character
pcall(function() t:Activate() end)
task.wait(0.8)
end
end
end

local function claim()
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextButton") or g:IsA("ImageButton") then
local s = (g.Text or ""):lower()
if s:find("claim") or s:find("collect") or s:find("reward") then
pcall(function() g:Activate() end)
end
end
end
end

local function findTimer()
for _, o in pairs(workspace:GetDescendants()) do
if o:IsA("ValueBase") then
local n = o.Name:lower()
if n:find("timer") or n:find("countdown") or n:find("time") then
local v = tonumber(o.Value)
if v and v > 0 then return v end
end
end
end
return nil
end

local function readTask()
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextLabel") or g:IsA("TextButton") then
local s = (g.Text or ""):lower()
for _, b in pairs(blockList) do
if s:find(b) then return nil end
end
for k in pairs(taskMap) do
if s:find(k) then
local isPet = false
for _, p in pairs(petTasksList) do
if k == p then isPet = true; break end
end
if isPet then
if not taskState.petEnabled then return nil end
if taskState.pet[k] == false then return nil end
else
if not taskState.babyEnabled then return nil end
if taskState.baby[k] == false then return nil end
end
return k
end
end
end
end
return nil
end

local function doTask()
if state.busy or inMinigame() then return end
local key = readTask()
if not key then return end
state.busy = true
if key == "walk" then walkTask()
elseif key == "ride" then rideTask()
else
local zone = taskZones[taskMap[key]]
if zone then
safeTP(zone)
task.wait(1.5)
local hrp = getHRP()
for _, o in pairs(workspace:GetDescendants()) do
if o:IsA("ProximityPrompt") and (hrp.Position - o.Parent.Position).Magnitude < 8 then
pcall(function() fireproximityprompt(o) end)
end
if o:IsA("ClickDetector") and (hrp.Position - o.Parent.Position).Magnitude < 8 then
pcall(fireclickdetector, o)
end
end
end
end
state.busy = false
end

local function babyToggle()
for _, r in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
if r:IsA("RemoteEvent") and (r.Name:lower():find("baby") or r.Name:lower():find("age")) then
pcall(function() r:FireServer() end)
end
end
end

local function preEventTeleport()
if not config.preEventTP then return end
local t = findTimer()
if t and t <= 5 and t > 0 and not state.inMinigame then
state.busy = true
state.inMinigame = true
for _, pos in pairs(eventZones) do safeTP(pos); task.wait(0.3) end
end
if state.inMinigame and not inMinigame() then
state.inMinigame = false
state.busy = false
end
end

LocalPlayer.Backpack.ChildAdded:Connect(function(t)
if t:IsA("Tool") and t.Name:lower():find("crypt key") then
task.wait(0.1)
if t.Parent == LocalPlayer.Character then
t.Parent = LocalPlayer.Backpack
end
end
end)

LocalPlayer.CharacterAdded:Connect(function(c)
c.ChildAdded:Connect(function(t)
if t:IsA("Tool") and t.Name:lower():find("crypt key") then
task.wait(0.1)
t.Parent = LocalPlayer.Backpack
end
end)
end)

LocalPlayer.Idled:Connect(function()
VirtualUser:Button2Down(Vector2.new(0, 0))
task.wait(1)
VirtualUser:Button2Up(Vector2.new(0, 0))
end)

task.spawn(function()
while task.wait(0.05) do
if config.ghostHunt and config.aimbot and not (state.busy and not state.inMinigame) then
local g = getGhosts()
if #g > 0 then
table.sort(g, function(a, b)
local h = getHRP(); if not h then return false end
local pa = a:IsA("Model") and a.HumanoidRootPart.Position or a.Position
local pb = b:IsA("Model") and b.HumanoidRootPart.Position or b.Position
return (h.Position - pa).Magnitude < (h.Position - pb).Magnitude
end)
aim(g[1])
if config.autoShoot then shoot(g[1]) end
end
end
end
end)

task.spawn(function()
while task.wait(0.5) do
if not state.busy and not inMinigame() then
if config.autoCollect then collect() end
if config.autoHatch and state.hatchClick then hatch() end
claim()
end
end
end)

task.spawn(function()
while task.wait(1) do preEventTeleport() end
end)

task.spawn(function()
while task.wait(2) do
if state.busy or state.inMinigame then continue end
local t = findTimer()
if t and t > 5 then doTask() end
end
end)

local Window = Rayfield:CreateWindow({
Name = "Adopt Me + Halloween",
LoadingTitle = "Loading",
LoadingSubtitle = "by Colin",
ConfigurationSaving = {Enabled = false},
KeySystem = false
})

local Main = Window:CreateTab("Main", 4483362458)
local Ghost = Window:CreateTab("Ghost", 4483362458)
local Tasks = Window:CreateTab("Tasks", 4483362458)
local Eggs = Window:CreateTab("Eggs", 4483362458)
local Pets = Window:CreateTab("Pets", 4483362458)
local Baby = Window:CreateTab("Baby", 4483362458)

Main:CreateToggle({Name = "Anti AFK", CurrentValue = true, Callback = function(v) config.antiAfk = v end})
Main:CreateToggle({Name = "Pre-Event TP (5s)", CurrentValue = true, Callback = function(v) config.preEventTP = v end})
Main:CreateToggle({Name = "Stealth Mode", CurrentValue = true, Callback = function(v) config.stealthTP = v end})
Main:CreateButton({Name = "Toggle Baby", Callback = babyToggle})

Ghost:CreateToggle({Name = "Ghost Hunt", CurrentValue = true, Callback = function(v) config.ghostHunt = v end})
Ghost:CreateToggle({Name = "Aimbot", CurrentValue = true, Callback = function(v) config.aimbot = v end})
Ghost:CreateToggle({Name = "Auto Shoot", CurrentValue = true, Callback = function(v) config.autoShoot = v end})

Tasks:CreateToggle({Name = "Baby Tasks Master", CurrentValue = true, Callback = function(v) taskState.babyEnabled = v end})
Tasks:CreateToggle({Name = "Pet Tasks Master", CurrentValue = true, Callback = function(v) taskState.petEnabled = v end})

local babyTasks = {"thirsty","hungry","sleep","bath","potty","drink","eat","school","hospital","walk","ride","playground","beach","pizza","salon","campfire","cafe"}
for _, t in pairs(babyTasks) do
Baby:CreateToggle({Name = t, CurrentValue = true, Callback = function(v) taskState.baby[t] = v end})
end

local petTasks = {"pet","groom","vet","fetch"}
for _, t in pairs(petTasks) do
Pets:CreateToggle({Name = t, CurrentValue = true, Callback = function(v) taskState.pet[t] = v end})
end

Pets:CreateButton({Name = "1 Pet Mode", Callback = function() petState.active = 1 end})
Pets:CreateButton({Name = "2 Pet Mode", Callback = function() petState.active = 2 end})

Eggs:CreateButton({Name = "Start Egg Farm", Callback = function() state.hatchClick = true end})
Eggs:CreateButton({Name = "Stop Egg Farm", Callback = function() state.hatchClick = false end})
Eggs:CreateSlider({Name = "Eggs per Cycle", Range = {1, 50}, Increment = 1, CurrentValue = 1, Callback = function(v) state.eggAmount = v end})
