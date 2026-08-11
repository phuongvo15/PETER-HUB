-- PETER HUB PRO - TỐI ƯU HÓA & HIỆU NĂNG CAO CẤP (FULL TÍNH NĂNG)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [Cấu hình]
local IslandList = {
    ["Đảo Khởi Đầu"] = Vector3.new(0, 5, 0),
    ["Đảo Cướp Biển"] = Vector3.new(1000, 5, 1000),
    ["Đảo Cát"] = Vector3.new(2500, 5, -1500),
    ["Đảo Trời"] = Vector3.new(-4500, 500, 3500)
}
local QuestNPCName = "QuestGiver"

-- [Quản lý vòng đời - Lifecycle Management]
local HubAlive = true
local activeConnections = {}
local activeThreads = {}

local function SafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        warn("[PeterHub] Lỗi thực thi:", err)
    end
end

local function RegisterConnection(conn)
    table.insert(activeConnections, conn)
    return conn
end

local function RegisterThread(func)
    local thread = task.spawn(func)
    table.insert(activeThreads, thread)
    return thread
end

-- Dọn dẹp bản cũ
if PlayerGui:FindFirstChild("PeterHubUI") then
    PlayerGui.PeterHubUI:Destroy()
end

-- [Tạo UI Khung Chính]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PeterHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 52, 0, 52)
ToggleBtn.Position = UDim2.new(0, 20, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Text = "PETER"
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 620, 0, 420)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local isOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
end)

-- [Biến Trạng Thái Tính Năng]
local States = {
    AutoFarm = false,
    AutoQuest = false,
    Aimbot = false,
    Noclip = false,
    EspPlayer = false,
    EspMob = false,
    Fullbright = false,
    Speed = false,
    Jump = false,
    Boost = false
}

-- [Hàm Hủy Hub Toàn Diện]
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0, 12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Text = "X"
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local function removeESP(target)
    if target:FindFirstChild("PeterESP_UI") then target.PeterESP_UI:Destroy() end
    if target:FindFirstChild("PeterESP_HL") then target.PeterESP_HL:Destroy() end
end

CloseBtn.MouseButton1Click:Connect(function()
    HubAlive = false
    
    -- Xóa toàn bộ ESP
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "PeterESP_UI" or obj.Name == "PeterESP_HL" then
            obj:Destroy()
        end
    end

    -- Ngắt toàn bộ Threads và Connections
    for _, conn in ipairs(activeConnections) do
        if conn.Connected then conn:Disconnect() end
    end
    for _, thread in ipairs(activeThreads) do
        task.cancel(thread)
    end
    table.clear(activeConnections)
    table.clear(activeThreads)

    -- Khôi phục trạng thái người chơi
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = 16
        char.Humanoid.JumpPower = 50
        char.Humanoid.UseJumpPower = true
    end

    ScreenGui:Destroy()
end)

-- [Sidebar & Các Trang UI]
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(6, 9, 15)
Sidebar.BorderSizePixel = 0

local HubTitle = Instance.new("TextLabel", Sidebar)
HubTitle.Size = UDim2.new(1, 0, 0, 55)
HubTitle.BackgroundTransparency = 1
HubTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
HubTitle.TextSize = 16
HubTitle.Font = Enum.Font.SourceSansBold
HubTitle.Text = "⚡ PETER HUB PRO"

local SidebarList = Instance.new("UIListLayout", Sidebar)
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 6)

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size = UDim2.new(1, -160, 1, 0)
ContentArea.Position = UDim2.new(0, 160, 0, 0)
ContentArea.BackgroundTransparency = 1

local Pages = {}
local function CreatePage(name)
    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.CanvasSize = UDim2.new(0, 0, 0, 650)
    page.ScrollBarThickness = 3
    page.Visible = false

    local layout = Instance.new("UIListLayout", page)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)

    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -12, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(15, 22, 35)
    btn.TextColor3 = Color3.fromRGB(200, 210, 230)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansSemibold
    btn.Text = name
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        page.Visible = true
    end)

    table.insert(Pages, page)
    return page
end

local Page1 = CreatePage("⚡ Auto & Chiến Đấu")
local Page2 = CreatePage("👁️ ESP & Tầm Nhìn")
local Page3 = CreatePage("🛠️ Tốc Độ & Đồ Họa")
local Page4 = CreatePage("🗺️ Dịch Chuyển Đảo")
Page1.Visible = true

-- [UI Helpers: AddToggle, AddButton, AddSlider]
local function AddToggle(page, labelText, stateKey, callback)
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(230, 235, 245)
    label.TextSize = 13
    label.Font = Enum.Font.SourceSansSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText

    local switchBg = Instance.new("TextButton", row)
    switchBg.Size = UDim2.new(0, 52, 0, 28)
    switchBg.Position = UDim2.new(1, -64, 0.5, -14)
    switchBg.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    switchBg.Text = ""
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)

    local switchKnob = Instance.new("Frame", switchBg)
    switchKnob.Size = UDim2.new(0, 22, 0, 22)
    switchKnob.Position = UDim2.new(0, 3, 0.5, -11)
    switchKnob.BackgroundColor3 = Color3.fromRGB(200, 205, 215)
    Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(1, 0)

    switchBg.MouseButton1Click:Connect(function()
        States[stateKey] = not States[stateKey]
        local active = States[stateKey]
        
        switchBg.BackgroundColor3 = active and Color3.fromRGB(0, 140, 255) or Color3.fromRGB(35, 45, 65)
        switchKnob.Position = active and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        switchKnob.BackgroundColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 205, 215)
        
        if callback then SafeCall(callback, active) end
    end)
end

local function AddButton(page, labelText, callback)
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    btn.TextColor3 = Color3.fromRGB(230, 235, 245)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansSemibold
    btn.Text = labelText
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
end

local function AddSlider(page, labelText, minVal, maxVal, defaultVal, callback)
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1, 0, 0, 62)
    row.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(230, 235, 245)
    label.TextSize = 13
    label.Font = Enum.Font.SourceSansSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText .. ": " .. defaultVal

    local sliderBar = Instance.new("TextButton", row)
    sliderBar.Size = UDim2.new(1, -28, 0, 10)
    sliderBar.Position = UDim2.new(0, 14, 0, 38)
    sliderBar.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    sliderBar.Text = ""
    Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame", sliderBar)
    sliderFill.Size = UDim2.new((defaultVal - minVal)/(maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    sliderBar.MouseButton1Down:Connect(function() dragging = true end)

    RegisterConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))

    RegisterConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            sliderFill.Size = UDim2.new(pos, 0, 1, 0)
            local val = math.floor(minVal + (maxVal - minVal) * pos)
            label.Text = labelText .. ": " .. val
            if callback then SafeCall(callback, val) end
        end
    end))
end

-- ================= CÁC TÍNH NĂNG CHÍNH ================= --

-- [Cache Mobs/Targets để tối ưu khung hình]
local cachedTargets = {}
RegisterThread(function()
    while HubAlive do
        local newCache = {}
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                if not Players:GetPlayerFromCharacter(obj) and obj.Humanoid.Health > 0 then
                    table.insert(newCache, obj)
                end
            end
        end
        cachedTargets = newCache
        task.wait(1) -- Cập nhật 1s/lần
    end
end)

-- 1. Auto Farm
RegisterConnection(RunService.Heartbeat:Connect(function()
    if not States.AutoFarm then return end
    SafeCall(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
        
        local target = nil
        local minDist = math.huge
        local hrpPos = char.HumanoidRootPart.Position

        for _, obj in ipairs(cachedTargets) do
            if obj.Parent and obj.Humanoid.Health > 0 then
                local dist = (obj.HumanoidRootPart.Position - hrpPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    target = obj
                end
            end
        end
        
        if target then
            char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame + Vector3.new(0, 6, 0)
            char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            
            local tool = char:FindFirstChildOfClass("Tool") or (LocalPlayer:FindFirstChildOfClass("Backpack") and LocalPlayer.Backpack:FindFirstChildOfClass("Tool"))
            if tool and tool.Parent ~= char then char.Humanoid:EquipTool(tool) end
            
            if tool then tool:Activate() else
                VirtualUser:Button1Down(Vector2.new(0,0), Camera.CFrame)
                task.wait(0.05)
                VirtualUser:Button1Up(Vector2.new(0,0), Camera.CFrame)
            end
        end
    end)
end))
AddToggle(Page1, "🤖 Auto Farm (Bay Trên Đầu & Đánh)", "AutoFarm")

-- 2. Auto Quest
RegisterThread(function()
    while HubAlive do
        if States.AutoQuest then
            SafeCall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    for _, npc in ipairs(Workspace:GetChildren()) do
                        if npc.Name == QuestNPCName and npc:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame + Vector3.new(0, 3, 3)
                            local cd = npc:FindFirstChildWhichIsA("ClickDetector", true)
                            if cd then fireclickdetector(cd) end
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)
AddToggle(Page1, "📜 Auto Nhận Nhiệm Vụ (Auto Quest)", "AutoQuest")

-- 3. Aimbot
RegisterConnection(RunService.RenderStepped:Connect(function()
    if not States.Aimbot then return end
    SafeCall(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local closestTarget = nil
        local shortestDist = math.huge
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local dist = (p.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestTarget = p.Character.HumanoidRootPart
                end
            end
        end
        
        if closestTarget then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestTarget.Position)
        end
    end)
end))
AddToggle(Page1, "🎯 Aimbot Tự Động Ngắm", "Aimbot")

-- 4. NoClip Tối ưu
local noclipParts = {}
LocalPlayer.CharacterAdded:Connect(function(char)
    table.clear(noclipParts)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(noclipParts, part) end
    end
end)

RegisterConnection(RunService.Stepped:Connect(function()
    if States.Noclip then
        for _, part in ipairs(noclipParts) do
            if part.Parent then part.CanCollide = false end
        end
    end
end))
AddToggle(Page1, "👻 NoClip (Đi Xuyên Tường)", "Noclip")

-- [Hệ Thống ESP Tối Ưu]
local function updateESP(target, nameText, color)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    local hum = target:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local bg = target:FindFirstChild("PeterESP_UI")
    if not bg then
        bg = Instance.new("BillboardGui")
        bg.Name = "PeterESP_UI"
        bg.Adornee = target:FindFirstChild("Head") or target.HumanoidRootPart
        bg.Size = UDim2.new(0, 140, 0, 50)
        bg.StudsOffset = Vector3.new(0, 2.8, 0)
        bg.AlwaysOnTop = true
        bg.Parent = target

        local txt = Instance.new("TextLabel", bg)
        txt.Name = "NameLabel"
        txt.Size = UDim2.new(1, 0, 0, 22)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = color
        txt.TextSize = 13
        txt.Font = Enum.Font.SourceSansBold
        txt.TextStrokeTransparency = 0.4

        local barBg = Instance.new("Frame", bg)
        barBg.Name = "HPBarBg"
        barBg.Size = UDim2.new(0, 90, 0, 6)
        barBg.Position = UDim2.new(0.5, -45, 0, 24)
        barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        
        local barFill = Instance.new("Frame", barBg)
        barFill.Name = "HPBarFill"
        barFill.Size = UDim2.new(1, 0, 1, 0)
        barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    end

    local hl = target:FindFirstChild("PeterESP_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "PeterESP_HL"
        hl.Adornee = target
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.Parent = target
    end

    bg.NameLabel.Text = string.format("%s [%d/%d]", nameText, math.floor(hum.Health), math.floor(hum.MaxHealth))
    if hum.MaxHealth > 0 then
        bg.HPBarBg.HPBarFill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
    end
end

-- 5. ESP Player
RegisterThread(function()
    while HubAlive do
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if States.EspPlayer then
                    updateESP(p.Character, "👤 " .. p.Name, Color3.fromRGB(0, 170, 255))
                else
                    removeESP(p.Character)
                end
            end
        end
        task.wait(0.5)
    end
end)
AddToggle(Page2, "👁️ ESP Người Chơi", "EspPlayer")

-- 6. ESP Mob
RegisterThread(function()
    while HubAlive do
        if States.EspMob then
            for _, obj in ipairs(cachedTargets) do
                if obj.Parent then updateESP(obj, "👾 " .. obj.Name, Color3.fromRGB(255, 50, 50)) end
            end
        else
            for _, obj in ipairs(cachedTargets) do
                if obj.Parent then removeESP(obj) end
            end
        end
        task.wait(1)
    end
end)
AddToggle(Page2, "🎯 ESP Quái Vật", "EspMob")

-- 7. Nhìn Trong Đêm (Fullbright)
AddToggle(Page2, "🔦 Nhìn Trong Đêm (Fullbright)", "Fullbright", function(val)
    Lighting.Brightness = val and 2 or 1
    Lighting.ClockTime = val and 14 or 12
    Lighting.FogEnd = val and 100000 or 10000
    Lighting.GlobalShadows = not val
end)

-- 8. Chạy Nhanh (Speed)
local currentSpeedValue = 50
RegisterConnection(RunService.RenderStepped:Connect(function()
    if States.Speed then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = currentSpeedValue
        end
    end
end))
AddToggle(Page3, "⚡ Bật/Tắt Chạy Nhanh", "Speed", function(val)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = val and currentSpeedValue or 16
    end
end)
AddSlider(Page3, "Tốc Độ Chạy (WalkSpeed)", 50, 200, 50, function(val)
    currentSpeedValue = val
    if States.Speed then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = val end
    end
end)

-- 9. Nhảy Cao (Jump)
local currentJumpValue = 50
RegisterConnection(RunService.RenderStepped:Connect(function()
    if States.Jump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.UseJumpPower = true
            char.Humanoid.JumpPower = currentJumpValue
        end
    end
end))
AddToggle(Page3, "🦘 Bật/Tắt Nhảy Cao", "Jump", function(val)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.UseJumpPower = true
        char.Humanoid.JumpPower = val and currentJumpValue or 50
    end
end)
AddSlider(Page3, "Sức Nhảy Cao (JumpPower)", 50, 300, 50, function(val)
    currentJumpValue = val
    if States.Jump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.JumpPower = val end
    end
end)

-- 10. Fix Lag Cực Mạnh
local connectionBoost = nil
AddToggle(Page3, "🔥 Fix Lag Cực Mạnh (Tối Ưu Đồ Họa)", "Boost", function(val)
    Lighting.GlobalShadows = not val
    Lighting.FogEnd = val and 9e9 or 100000
    Lighting.Brightness = val and 2 or 1
    Lighting.OutdoorAmbient = val and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(128, 128, 128)
    
    for _, light in ipairs(Lighting:GetChildren()) do
        if light:IsA("PostEffect") or light:IsA("Atmosphere") or light:IsA("Sky") or light:IsA("BlurEffect") or light:IsA("SunRaysEffect") or light:IsA("ColorCorrectionEffect") then
            light.Enabled = not val
        end
    end

    pcall(function()
        if Workspace:FindFirstChildOfClass("Terrain") then
            local terrain = Workspace.Terrain
            terrain.WaterWaveSize = val and 0 or 1
            terrain.WaterWaveSpeed = val and 0 or 8
            terrain.WaterTransparency = val and 1 or 0.3
            terrain.WaterReflectance = val and 0 or 1
        end
    end)

    local function cleanPart(v)
        if v:IsA("BasePart") then
            v.Material = val and Enum.Material.SmoothPlastic or Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = val and 1 or 0
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Beam") or v:IsA("Explosion") then
            v.Enabled = not val
        end
    end

    for _, v in ipairs(Workspace:GetDescendants()) do
        cleanPart(v)
    end

    if val then
        if not connectionBoost then
            connectionBoost = RegisterConnection(Workspace.DescendantAdded:Connect(function(v)
                if States.Boost then task.spawn(function() cleanPart(v) end) end
            end))
        end
    else
        if connectionBoost then
            connectionBoost:Disconnect()
            connectionBoost = nil
        end
    end
end)

-- 11. Dịch Chuyển (Teleport)
for islandName, pos in pairs(IslandList) do
    AddButton(Page4, "🚀 Di chuyển tới: " .. islandName, function()
        SafeCall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(pos)
            end
        end)
    end)
end
