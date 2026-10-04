local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local state = { busy = false, inMinigame = false, lastTP = 0, taskLock = false }

local config = {
ghostHunt = true, aimbot = true, autoShoot = true,
preEventTP = true, stealthTP = true, disableNeeds = false,
taskLoop = true
}

local eventZones = {
HauntedMansion = Vector3.new(-5982.613, 10011.106, 9000.880),
CandyVillage = Vector3.new(-2980.047, 4013.270, 5700.248),
PumpkinPatch = Vector3.new(-543.291, 30.475, -1475.572),
WitchTower = Vector3.new(-377.687, 30.960, -1739.829)
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
potty="Toilet", drink="Drink", pizza="Pizza",
salon="Salon", campfire="Campfire",
beach="BeachParty", playground="Playground"
}

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
if os.clock() - state.lastTP < 1.5 then return end
state.lastTP = os.clock()
local h = getHRP()
if not h then return end
if config.stealthTP then
TweenService:Create(h, TweenInfo.new(0.8), {CFrame = CFrame.new(pos + Vector3.new(0,4,0))}):Play()
else
h.CFrame = CFrame.new(pos + Vector3.new(0,4,0))
end
end

local function disableNeeds()
if not config.disableNeeds then return end
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextLabel") then
local s = (g.Text or ""):lower()
if s:find("hungry") or s:find("thirsty") or s:find("pet needs") then
local p = g.Parent
while p and p ~= LocalPlayer.PlayerGui do
if p:IsA("Frame") then p.Visible = false; break end
p = p.Parent
end
end
end
end
end

local function readTask()
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextLabel") or g:IsA("TextButton") then
local s = (g.Text or ""):lower()
for k in pairs(taskMap) do
if s:find(k) then return k end
end
end
end
return nil
end

local function checkTaskDone()
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextLabel") then
local s = (g.Text or ""):lower()
if s:find("complete") or s:find("done") or s:find("next task") or s:find("well done") then
return true
end
end
end
return false
end

local function doTask()
if state.busy or state.taskLock or state.inMinigame then return end
local key = readTask()
if not key then return end
local zone = taskZones[taskMap[key]]
if not zone then return end

state.taskLock = true
safeTP(zone)
task.wait(2)
local hrp = getHRP()
if hrp then
for _, o in pairs(workspace:GetDescendants()) do
if o:IsA("ProximityPrompt") and (hrp.Position - o.Parent.Position).Magnitude < 12 then
pcall(function() fireproximityprompt(o) end)
end
if o:IsA("ClickDetector") and (hrp.Position - o.Parent.Position).Magnitude < 12 then
pcall(fireclickdetector, o)
end
end
end

-- wait for task to complete, max 15s
local waited = 0
while waited < 15 do
if checkTaskDone() then break end
task.wait(1)
waited = waited + 1
end

state.taskLock = false
end

local function getGhosts()
local g = {}
for _, o in pairs(workspace:GetDescendants()) do
local n = o.Name:lower()
if n:find("ghost") or n:find("spirit") or n:find("phantom") then
if o:IsA("Model") and o:FindFirstChild("HumanoidRootPart") then
table {.insert(g, o)
Enabled elseif o:IsA("BasePart") then
table.insert(g, o)
end
end
end
return g
end

local function aim(t)
= local h = getHRP(); if not h then return false end
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

local function preEventTeleport()
if not config.preEventTP then return end
local t = findTimer()
if t and t <= 5 and t > 0 and not state.inMinigame then
state.inMinigame = true
state.taskLock = false
for _, pos in pairs(eventZones) do safeTP(pos); task.wait(1.5) end
end
if state.inMinigame and not inMinigame() then
state.inMinigame = false
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

LocalPlayer.Idled:Connect(function()
VirtualUser:Button2Down(Vector2.new(0, 0))
task.wait(1)
VirtualUser:Button2Up(Vector2.new(0, 0))
end)

task.spawn(function()
while task.wait(0.1) do
if config.ghostHunt and config.aimbot and (state.inMinigame or not state.taskLock) then
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
while task.wait(1) do
if config.disableNeeds then disableNeeds() end
end
end)

task.spawn(function()
while task.wait(1) do preEventTeleport() end
end)

task.spawn(function()
while task.wait(2) do
if config.taskLoop and not state.inMinigame and not state.taskLock then
doTask()
end
end
end)

local Window = Rayfield:CreateWindow({
Name = "Adopt Me + Halloween",
LoadingTitle = "Loading",
LoadingSubtitle = "by Colin",
ConfigurationSaving =},
KeySystem = false
})

local Main = Window:CreateTab("Main", 4483362458)
local Ghost = Window:CreateTab("Ghost", 4483362458)

Main:CreateToggle({Name = "Anti AFK", CurrentValue = true, Callback = function(v) config.antiAfk = v end})
Main:CreateToggle({Name = "Pre-Event TP (5s)", CurrentValue = true, Callback = function(v) config.preEventTP = v end})
Main:CreateToggle({Name = "Stealth Mode", CurrentValue = true, Callback = function(v) config.stealthTP = v end})
Main:CreateToggle({Name = "Disable Needs UI", CurrentValue = false, Callback = function(v) config.disableNeeds = v end})
Main:CreateToggle({Name = "Task Loop", CurrentValue = true, Callback = function(v) config.taskLoop = v end})

Ghost:CreateToggle({Name = "Ghost Hunt", CurrentValue = true, Callback = function(v) config.ghostHunt = v end})
Ghost:CreateToggle({Name = "Aimbot", CurrentValue = true, Callback = function(v) config.aimbot = v end})
Ghost:CreateToggle({Name = "Auto Shoot", CurrentValue = true, Callback = function(v) config.autoShoot = v end})
