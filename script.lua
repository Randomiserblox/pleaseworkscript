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

local state = { taskLock = false, lockTime = 0, lastTP = 0, popupsFired = false, lastGalleryClick = 0, equipChecked = false }

local config = {
ghostHunt = true, aimbot = true, autoShoot = true,
ghostAccept = true, taskLoop = true, antiAfk = true,
disablePopups = true, blockPetMe = false,
babyTasks = true, petTasks = true, autoEquip = true
}

local townZones = {
BabyApple = Vector3.new(-2966.631, 9990.543, 3028.973),
BabyWater = Vector3.new(-3023.935, 4013.070, 5634.844)
}

local minigameCenter = Vector3.new(-5982.613, 10011.106, 9000.880)
local minigameRadius = 800

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

local function isPetPopup()
local petNames = {}
local pets = workspace:FindFirstChild("Pets")
if pets then
for _, p in pairs(pets:GetChildren()) do
if p:IsA("Model") then table.insert(petNames, p.Name:lower()) end
end
end
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
local gui = LocalPlayer.PlayerGui:FindFirstChild("AilmentsMonitorApp")
if not gui then return nil end
local pointer = gui:FindFirstChild("PointerBox")
if not pointer then return nil end
local box = pointer:FindFirstChild("BoxBorder")
if not box then return nil end
local area = box:FindFirstChild("TextArea")
if not area then return nil end
local title = area:FindFirstChild("Title")
if not title then return nil end
local name = title:FindFirstChild("AilmentName")
if not name then return nil end
return name.Text, isPetPopup()
end

local function checkTaskDone()
return getActiveTaskInfo() == nil
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
task.wait(1)
waited = waited + 1
end
return false
end

local function pressKey(key)
pcall(function() keypress(key) end)
task.wait(0.1)
pcall(function() keyrelease(key) end)
end

local function feedLoop()
local waited = 0
while waited < 30 do
if isPetPopup() then pressKey(Enum.KeyCode.Two)
else pressKey(Enum.KeyCode.One) end
if checkTaskDone() then break end
task.wait(0.5)
waited = waited + 1
end
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
feedLoop()
waitForTaskEnd()
end

local function handlePetAilment(flags)
local pet = getPet()
if not pet then return end
local args = { pet, flags }
local waited = 0
while waited < 30 do
pcall(function() API:WaitForChild("PetAPI/ReplicateActivePerformances"):FireServer(unpack(args)) end)
if checkTaskDone() then break end
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
pcall(function() API:WaitForChild("AilmentsAPI/ProgressPetMeAilment"):FireServer(unpack(args)) end)
if checkTaskDone() then break end
task.wait(0.5)
waited = waited + 1
end
end

local function handleDirty()
local pet = getPet()
if not pet then return end
local args = { pet }
local waited = 0
while waited < 30 do
pcall(function() API:WaitForChild("AilmentsAPI/ProgressDirtyAilment"):FireServer(unpack(args)) end)
if checkTaskDone() then break end
task.wait(0.5)
waited = waited + 1
end
end

local function handleTask(title, isPet)
if not title then return end
local t = title:lower()
if isPet and not config.petTasks then return end
if not isPet and not config.babyTasks then return end
if t:find("pet me") then
if not config.blockPetMe then handlePetMe() end
return
end
if t:find("dirty") then handleDirty(); return end
if isPet then
if t:find("sleepy") then handlePetAilment({ FallAsleep = true, FocusPet = true }); return end
if t:find("sick") then handlePetAilment({ Sick = true, FocusPet = true }); return end
if t:find("hungry") then handlePetAilment({ Hungry = true, FocusPet = true }); return end
if t:find("thirsty") then handlePetAilment({ Thirsty = true, FocusPet = true }); return end
else
if t:find("hungry") then handleBabyFeed("BabyApple"); return end
if t:find("thirsty") then handleBabyFeed("BabyWater"); return end
end
end

local function clickGhostGallery()
if os.clock() - state.lastGalleryClick < 3 then return false end
local hasGallery = false
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextLabel") and (g.Text or ""):lower():find("ghost gallery") then
hasGallery = true; break
end
end
if not hasGallery then return false end
for _, b in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if b:IsA("TextButton") and (b.Text or ""):lower():find("yes") then
pcall(function() b:Activate() end)
state.lastGalleryClick = os.clock()
return true
end
end
return false
end

local function disablePopups()
pcall(function() API:WaitForChild("PayAPI/DisablePopups"):FireServer() end)
end

local function autoEquipPet()
if state.equipChecked then return end
for _, g in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
if g:IsA("TextButton") and (g.Text or ""):lower() == "equip" then
pcall(function() g:Activate() end)
state.equipChecked = true
return
end
end
end

local function antiFling()
local c = LocalPlayer.Character
if not c then return end
for _, part in pairs(c:GetDescendants()) do
if part:IsA("LinearVelocity") or part:IsA("BodyVelocity") or part:IsA("BodyPosition") or part:IsA("AlignPosition") or part:IsA("BodyForce") or part:IsA("BodyThrust") then
pcall(function() part:Destroy() end)
end
end
local h = c:FindFirstChild("HumanoidRootPart")
if h then
h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
h.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end
end

local function aim(t)
local h = getHRP(); if not h then return end
local p = t:IsA("Model") and (t.HumanoidRootPart and t.HumanoidRootPart.Position or t:GetPivot().Position) or t.Position
workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, p), 0.25)
end

local function shoot(t)
local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
if not tool then
for _, x in pairs(LocalPlayer.Backpack:GetChildren()) do
if x:IsA("Tool") then x.Parent = LocalPlayer.Character; tool = x; break end
end
end
if not tool then return end
local id = tool:GetAttribute("Id") or tool:GetAttribute("ToolId") or tool.Name
aim(t)
pcall(function() API:WaitForChild("ToolAPI/ServerUseTool"):InvokeServer(tostring(id), "START") end)
task.wait(0.1)
pcall(function() API:WaitForChild("ToolAPI/ServerUseTool"):InvokeServer(tostring(id), "END") end)
end

local function getSmartTarget()
local h = getHRP(); if not h then return nil end
local candidates = {}
local visuals = workspace:FindFirstChild("GhostClustersVisuals")
if visuals then
for _, v in pairs(visuals:GetChildren()) do
if v:IsA("Model") then
local id = v:GetAttribute("GhostClustersId")
local prog = v:GetAttribute("GhostClustersProgress") or 0
local req = v:GetAttribute("GhostClustersProgressRequired") or 100
local size = v:GetAttribute("GhostClustersSize") or "Small"
local isBoss = size == "Large" or size == "Huge" or size == "Boss" or size == "Giant"
local hrp = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart", true)
if hrp and id and prog < req then
table.insert(candidates, { model = v, required = req, isBoss = isBoss, dist = (hrp.Position - h.Position).Magnitude })
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
return candidates[1]
end

LocalPlayer.Idled:Connect(function()
VirtualUser:Button2Down(Vector2.new(0, 0))
task.wait(1)
VirtualUser:Button2Up(Vector2.new(0, 0))
end)

RunService.RenderStepped:Connect(antiFling)

task.spawn(function() while task.wait(1) do if config.disablePopups and not state.popupsFired then disablePopups(); state.popupsFired = true end end end)
task.spawn(function() while task.wait(1) do if config.ghostAccept then clickGhostGallery() end end end)
task.spawn(function() task.wait(5); if config.autoEquip then autoEquipPet() end end)

task.spawn(function()
while task.wait(2) do
if state.taskLock and os.clock() - state.lockTime > 60 then state.taskLock = false end
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
else enterTime = 0 end
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
local Tasks = Window:CreateTab("Tasks", 4483362458)
local Ghost = Window:CreateTab("Ghost", 4483362458)

Main:CreateToggle({Name = "Anti AFK", CurrentValue = true, Callback = function(v) config.antiAfk = v end})
Main:CreateToggle({Name = "Auto Accept Ghost Gallery", CurrentValue = true, Callback = function(v) config.ghostAccept = v end})
Main:CreateToggle({Name = "Task Loop", CurrentValue = true, Callback = function(v) config.taskLoop = v end})
Main:CreateToggle({Name = "Disable Popup (Once)", CurrentValue = true, Callback = function(v) config.disablePopups = v; if v then disablePopups(); state.popupsFired = true end end})
Main:CreateToggle({Name = "Auto Equip Pet", CurrentValue = true, Callback = function(v) config.autoEquip = v; if v then state.equipChecked = false; autoEquipPet() end end})

Tasks:CreateToggle({Name = "Baby Tasks", CurrentValue = true, Callback = function(v) config.babyTasks = v end})
Tasks:CreateToggle({Name = "Pet Tasks", CurrentValue = true, Callback = function(v) config.petTasks = v end})
Tasks:CreateToggle({Name = "Block 'Pet Me' Task", CurrentValue = false, Callback = function(v) config.blockPetMe = v end})

Ghost:CreateToggle({Name = "Ghost Hunt", CurrentValue = true, Callback = function(v) config.ghostHunt = v end})
Ghost:CreateToggle({Name = "Aimbot", CurrentValue = true, Callback = function(v) config.aimbot = v end})
Ghost:CreateToggle({Name = "Auto Shoot", CurrentValue = true, Callback = function(v) config.autoShoot = v end})
