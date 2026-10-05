local Rayfield
pcall(function()
Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not Rayfield then
Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local API = ReplicatedStorage:WaitForChild("API")

local state = { taskLock = false, lockTime = 0, lastTP = 0, popupsFired = false, lastGalleryClick = 0 }

local config = {
ghostHunt = true, aimbot = true, autoShoot = true,
ghostAccept = true, taskLoop = true, antiAfk = true,
disablePopups = true, blockPetMe = false
}

local townZones = {
BabyApple = Vector3.new(-2966.631, 9990.543, 3028.973),
BabyWater = Vector3.new(-3023.935, 4013.070, 5634.844)
}

local minigameCenter = Vector3.new(-5982.613, 10011.106, 9000.880)
local minigameRadius = 800

local knownTasks = {
"hungry", "thirsty", "sleepy", "dirty", "sick",
"pet me", "bored", "lonely", "walk", "ride", "potty"
}

local function getHRP()
local c = LocalPlayer.Character
return c and c:FindFirstChild("HumanoidRootPart")
end

local function inMinigame()
if workspace:FindFirstChild("GhostClustersVisuals") then return true end
local h = getHRP(); if not h then return false end
return (h.Position - minigameCenter).Magnitude < minigameRadius
end

local function safeTP(pos)
if os.clock() - state.lastTP < 1.5 then return end
state.lastTP = os.clock()
local h = getHRP(); if not h then return end
h.CFrame = CFrame.new(pos + Vector3.new(0,4,0))
end

local function getPet()
local pets = workspace:FindFirstChild("Pets")
if not pets then return nil end
for _, p in pairs(pets:GetChildren()) do
if p:IsA("Model") and p:FindFirstChild("HumanoidRootPart") then return p end
end
return nil
end

local function getPetNames()
local names = {}
local pets = workspace:FindFirstChild("Pets")
if not pets then return names end
for _, p in pairs(pets:GetChildren()) do
if p:IsA("Model") then
table.insert(names, p.Name:lower())
end
end
return names
end

local function isPetPopup()
local petNames = getPetNames()
if #petNames == 0 then return false end
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextLabel") then
local s = (g.Text or ""):lower()
for _, pn in pairs(petNames) do
if s:find(pn .. " %(") then return true end
end
end
end
return false
end

local function getActiveTaskInfo()
local blacklist = { "ghost", "gallery", "welcome", "reward", "complete", "well done", "next", "bucks", "xp" }
local bestTitle, bestLen = nil, 999
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextLabel") then
local s = g.Text or ""
if s:find("!") and #s < 25 then
local ls = s:lower()
local skip = false
for _, b in pairs(blacklist) do
if ls:find(b) then skip = true; break end
end
if not skip then
local matched = false
for _, k in pairs(knownTasks) do
if ls:find(k) then matched = true; break end
end
if matched and #s < bestLen then
bestTitle = s
bestLen = #s
end
end
end
end
end
return bestTitle, isPetPopup()
end

local function checkTaskDone()
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextLabel") then
local s = (g.Text or ""):lower()
if s == "complete" or s == "well done!" then return true end
end
end
return false
end

local function firePromptsNearby()
local h = getHRP(); if not h then return end
for _, o in pairs(workspace:GetDescendants()) do
if o:IsA("ProximityPrompt") and o.Parent then
local pos = o.Parent:IsA("BasePart") and o.Parent.Position or (o.Parent:IsA("Model") and o.Parent:GetPivot().Position)
if pos and (pos - h.Position).Magnitude < 12 then
pcall(function() fireproximityprompt(o) end)
end
end
end
end

local function waitForTaskEnd()
local waited = 0
while waited < 30 do
if checkTaskDone() then return true end
local title = getActiveTaskInfo()
if not title then return true end
task.wait(1)
waited = waited + 1
end
return false
end

local function getToolId(tool)
if not tool then return nil end
local id = tool:GetAttribute("Id") or tool:GetAttribute("ToolId")
if id then return tostring(id) end
for _, c in pairs(tool:GetChildren()) do
if c:IsA("StringValue") and c.Name:lower():find("id") then
return tostring(c.Value)
end
end
return tostring(tool.Name)
end

local function handleBabyFeed(zoneName)
local zone = townZones[zoneName]
if not zone then return end
safeTP(zone)
task.wait(2)
firePromptsNearby()
task.wait(1.5)
firePromptsNearby()
task.wait(1)

local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
if not tool then waitForTaskEnd(); return end
local id = getToolId(tool)
if not id then waitForTaskEnd(); return end

pcall(function() API:WaitForChild("ToolAPI/ServerUseTool"):InvokeServer(id, "START") end)
task.wait(0.3)
pcall(function() API:WaitForChild("JournalAPI/CommitCollection"):FireServer() end)
pcall(function() API:WaitForChild("PlayerProfileAPI/RefreshProfile"):InvokeServer(LocalPlayer) end)
task.wait(0.3)
pcall(function() API:WaitForChild("ToolAPI/ServerUseTool"):InvokeServer(id, "END") end)
pcall(function() API:WaitForChild("JournalAPI/CommitCollection"):FireServer() end)

waitForTaskEnd()
end

local function handlePetAilment(flags)
local pet = getPet()
if not pet then return end
local args = { pet, flags }
local waited = 0
while waited < 30 do
pcall(function()
API:WaitForChild("PetAPI/ReplicateActivePerformances"):FireServer(unpack(args))
end)
if checkTaskDone() then break end
local title = getActiveTaskInfo()
if not title then break end
task.wait(0.5)
waited = waited + 1
end
end

local function handlePetMe()
local pet = getPet()
if not pet then return end
local args = { pet }
local waited = 0
while waited < 30 do
pcall(function()
API:WaitForChild("AilmentsAPI/ProgressPetMeAilment"):FireServer(unpack(args))
end)
if checkTaskDone() then break end
local title = getActiveTaskInfo()
if not title then break end
task.wait(0.5)
waited = waited + 1
end
end

local function handleTask(title, isPet)
if not title then return end
local t = title:lower()

if t:find("pet me") then
if not config.blockPetMe then handlePetMe() end
return
end
if t:find("walk") then
local h = getHRP()
local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if h and humanoid then
for i = 1, 6 do
humanoid:MoveTo(h.Position + Vector3.new(math.random(-30,30), 0, math.random(-30,30)))
task.wait(1.5)
end
humanoid:MoveTo(h.Position)
end
waitForTaskEnd()
return
end
if t:find("ride") then
waitForTaskEnd()
return
end

if isPet then
if t:find("sleepy") then handlePetAilment({ FallAsleep = true, FocusPet = true }); return end
if t:find("dirty") then handlePetAilment({ Dirty = true, FocusPet = true }); return end
if t:find("sick") then handlePetAilment({ Sick = true, FocusPet = true }); return end
if t:find("hungry") then handlePetAilment({ FocusPet = true }); return end
if t:find("thirsty") then handlePetAilment({ FocusPet = true }); return end
if t:find("bored") then handlePetAilment({ FocusPet = true }); return end
if t:find("lonely") then handlePetAilment({ FocusPet = true }); return end
else
if t:find("hungry") then handleBabyFeed("BabyApple"); return end
if t:find("thirsty") then handleBabyFeed("BabyWater"); return end
end
end

local function clickGhostGallery()
if os.clock() - state.lastGalleryClick < 3 then return false end
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextLabel") and (g.Text or ""):lower():find("ghost gallery") then
for _, b in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if (b:IsA("TextButton") or b:IsA("ImageButton")) and (b.Text or ""):lower():find("yes") then
pcall(function() b:Activate() end)
state.lastGalleryClick = os.clock()
return true
end
end
end
end
return false
end

local function disablePopups()
pcall(function() API:WaitForChild("PayAPI/DisablePopups"):FireServer() end)
end

local cachedTarget = nil
local lastTargetCheck = 0

local function getSmartTarget()
if os.clock() - lastTargetCheck < 0.5 and cachedTarget then
if cachedTarget.model and cachedTarget.model.Parent then
local prog = cachedTarget.model:GetAttribute("GhostClustersProgress") or 0
local req = cachedTarget.model:GetAttribute("GhostClustersProgressRequired") or 100
if prog < req then return cachedTarget end
end
end
lastTargetCheck = os.clock()
cachedTarget = nil
local h = getHRP()
if not h then return nil end
local candidates = {}
local visuals = workspace:FindFirstChild("GhostClustersVisuals")
if visuals then
for _, v in pairs(visuals:GetChildren()) do
if v:IsA("Model") then
local id = v:GetAttribute("GhostClustersId")
local prog = v:GetAttribute("GhostClustersProgress") or 0
local required = v:GetAttribute("GhostClustersProgressRequired") or 100
local size = v:GetAttribute("GhostClustersSize") or "Small"
local isBoss = size == "Large" or size == "Huge" or size == "Boss" or size == "Giant"
local hrp = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart", true)
if hrp and id and prog < required then
table.insert(candidates, {
model = v, id = id,
required = required, size = size, isBoss = isBoss,
dist = (hrp.Position - h.Position).Magnitude
})
end
end
end
end
if #candidates == 0 then return nil end
table.sort(candidates, function(a, b)
if a.isBoss ~= b.isBoss then return a.isBoss end
if a.required ~= b.required then return a.required < b.required end
return a.dist < b.dist
end)
cachedTarget = candidates[1]
return cachedTarget
end

local function aim(t)
local h = getHRP(); if not h then return end
local p = t:IsA("Model") and (t.HumanoidRootPart and t.HumanoidRootPart.Position or t:GetPivot().Position) or t.Position
workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, p), 0.25)
end

local function shoot(t)
if math.random() < 0.15 then return end
local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
if not tool then
for _, x in pairs(LocalPlayer.Backpack:GetChildren()) do
if x:IsA("Tool") then x.Parent = LocalPlayer.Character; tool = x; break end
end
end
if tool then
aim(t)
pcall(function() tool:Activate() end)
end
end

local function antiFling()
local h = getHRP(); if not h then return end
if h.AssemblyLinearVelocity.Magnitude > 80 then
h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
end
if h.AssemblyAngularVelocity.Magnitude > 20 then
h.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end
end

LocalPlayer.Idled:Connect(function()
VirtualUser:Button2Down(Vector2.new(0, 0))
task.wait(1)
VirtualUser:Button2Up(Vector2.new(0, 0))
end)

RunService.Heartbeat:Connect(antiFling)

task.spawn(function()
while task.wait(1) do
if config.disablePopups and not state.popupsFired then
disablePopups()
state.popupsFired = true
end
end
end)

task.spawn(function()
while task.wait(1) do
if config.ghostAccept then clickGhostGallery() end
end
end)

task.spawn(function()
while task.wait(2) do
if state.taskLock and os.clock() - state.lockTime > 60 then
state.taskLock = false
end
if not config.taskLoop or state.taskLock then continue end
local title, isPet = getActiveTaskInfo()
if title then
state.taskLock = true
state.lockTime = os.clock()
pcall(function() handleTask(title, isPet) end)
task.wait(2)
state.taskLock = false
end
end
end)

task.spawn(function()
local enterTime = 0
while task.wait(0.1) do
if inMinigame() then
if enterTime == 0 then enterTime = os.clock() end
if os.clock() - enterTime > 8 and config.ghostHunt and config.aimbot then
local target = getSmartTarget()
if target then
aim(target.model)
if config.autoShoot then shoot(target.model) end
end
end
else
enterTime = 0
end
end
end)

local Window = Rayfield:CreateWindow({
Name = "Adopt Me API",
LoadingTitle = "Loading",
LoadingSubtitle = "by Colin",
ConfigurationSaving = {Enabled = false},
KeySystem = false
})

local Main = Window:CreateTab("Main", 4483362458)
local Ghost = Window:CreateTab("Ghost", 4483362458)

Main:CreateToggle({Name = "Anti AFK", CurrentValue = true, Callback = function(v) config.antiAfk = v end})
Main:CreateToggle({Name = "Auto Accept Ghost Gallery", CurrentValue = true, Callback = function(v) config.ghostAccept = v end})
Main:CreateToggle({Name = "Task Loop", CurrentValue = true, Callback = function(v) config.taskLoop = v end})
Main:CreateToggle({Name = "Disable Popup (Once)", CurrentValue = true, Callback = function(v) config.disablePopups = v; if v then disablePopups(); state.popupsFired = true end end})
Main:CreateToggle({Name = "Block 'Pet Me' Task", CurrentValue = false, Callback = function(v) config.blockPetMe = v end})

Ghost:CreateToggle({Name = "Ghost Hunt", CurrentValue = true, Callback = function(v) config.ghostHunt = v end})
Ghost:CreateToggle({Name = "Aimbot", CurrentValue = true, Callback = function(v) config.aimbot = v end})
Ghost:CreateToggle({Name = "Auto Shoot", CurrentValue = true, Callback = function(v) config.autoShoot = v end})
