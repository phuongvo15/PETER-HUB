-- PETER HUB PRO - TOÀN BỘ TÍNH NĂNG HOÀN CHỈNH VÀ ĐẦY ĐỦ KHÔNG THIẾU MỘT GÌ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Cấu hình Đảo & Nhiệm Vụ
local IslandList = {
    ["Đảo Khởi Đầu"] = Vector3.new(0, 5, 0),
    ["Đảo Cướp Biển"] = Vector3.new(1000, 5, 1000),
    ["Đảo Cát"] = Vector3.new(2500, 5, -1500),
    ["Đảo Trời"] = Vector3.new(-4500, 500, 3500)
}
local QuestNPCName = "QuestGiver" -- Tên NPC nhận nhiệm vụ trong game

-- Xóa UI cũ nếu tồn tại
if PlayerGui:FindFirstChild("PeterHubUI") then
    PlayerGui.PeterHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PeterHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Mảng lưu trữ kết nối để dọn dẹp khi tắt Hub
local activeConnections = {}

-- Nút nổi mở/đóng menu
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 52, 0, 52)
ToggleBtn.Position = UDim2.new(0, 20, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Text = "PETER"
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

-- Khung giao diện chính
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 620, 0, 420)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local isOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
end)

-- Biến cờ trạng thái tính năng
local autoFarmActive = false
local autoQuestActive = false
local aimbotActive = false
local noclipActive = false
local espPlayerActive = false
local espMobActive = false
local speedActive = false
local jumpActive = false
local boostActive = false
local connectionBoost = nil

-- Nút Tắt / Hủy Hub Hoàn Toàn ([X])
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0, 12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Text = "X"
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    -- Tắt toàn bộ trạng thái
    autoFarmActive = false
    autoQuestActive = false
    aimbotActive = false
    noclipActive = false
    espPlayerActive = false
    espMobActive = false
    speedActive = false
    jumpActive = false
    boostActive = false

    -- Ngắt kết nối Boost nếu có
    if connectionBoost then
        connectionBoost:Disconnect()
        connectionBoost = nil
    end

    -- Ngắt toàn bộ các kết nối trong mảng activeConnections
    for _, conn in ipairs(activeConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end

    -- Khôi phục trạng thái nhân vật về mặc định
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = 16
        char.Humanoid.JumpPower = 50
        char.Humanoid.UseJumpPower = true
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    -- Hủy hoàn toàn GUI
    ScreenGui:Destroy()
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(6, 9, 15)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local HubTitle = Instance.new("TextLabel")
HubTitle.Size = UDim2.new(1, 0, 0, 55)
HubTitle.BackgroundTransparency = 1
HubTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
HubTitle.TextSize = 16
HubTitle.Font = Enum.Font.SourceSansBold
HubTitle.Text = "⚡ PETER HUB PRO"
HubTitle.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 6)
SidebarList.Parent = Sidebar

-- Nội dung (Content Area)
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -160, 1, 0)
ContentArea.Position = UDim2.new(0, 160, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Pages = {}
local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.CanvasSize = UDim2.new(0, 0, 0, 650)
    page.ScrollBarThickness = 3
    page.Visible = false
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = page

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(15, 22, 35)
    btn.TextColor3 = Color3.fromRGB(200, 210, 230)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansSemibold
    btn.Text = name
    btn.Parent = Sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

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

-- Hàm Toggle UI Helper
local function AddToggle(page, labelText, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    row.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(230, 235, 245)
    label.TextSize = 13
    label.Font = Enum.Font.SourceSansSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Parent = row

    local switchBg = Instance.new("TextButton")
    switchBg.Size = UDim2.new(0, 52, 0, 28)
    switchBg.Position = UDim2.new(1, -64, 0.5, -14)
    switchBg.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    switchBg.Text = ""
    switchBg.Parent = row

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    local switchKnob = Instance.new("Frame")
    switchKnob.Size = UDim2.new(0, 22, 0, 22)
    switchKnob.Position = UDim2.new(0, 3, 0.5, -11)
    switchKnob.BackgroundColor3 = Color3.fromRGB(200, 205, 215)
    switchKnob.Parent = switchBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = switchKnob

    local state = false
    switchBg.MouseButton1Click:Connect(function()
        state = not state
        if state then
            switchBg.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
            switchKnob.Position = UDim2.new(1, -25, 0.5, -11)
            switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        else
            switchBg.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
            switchKnob.Position = UDim2.new(0, 3, 0.5, -11)
            switchKnob.BackgroundColor3 = Color3.fromRGB(200, 205, 215)
        end
        callback(state)
    end)
end

-- Hàm Slider UI Helper
local function AddSlider(page, labelText, minVal, maxVal, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 62)
    row.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    row.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(230, 235, 245)
    label.TextSize = 13
    label.Font = Enum.Font.SourceSansSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText .. ": " .. defaultVal
    label.Parent = row

    local sliderBar = Instance.new("TextButton")
    sliderBar.Size = UDim2.new(1, -28, 0, 10)
    sliderBar.Position = UDim2.new(0, 14, 0, 38)
    sliderBar.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    sliderBar.Text = ""
    sliderBar.Parent = row

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = sliderBar

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((defaultVal - minVal)/(maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill

    local dragging = false
    sliderBar.MouseButton1Down:Connect(function()
        dragging = true
    end)

    local inputEndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    table.insert(activeConnections, inputEndConn)

    local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            sliderFill.Size = UDim2.new(pos, 0, 1, 0)
            local val = math.floor(minVal + (maxVal - minVal) * pos)
            label.Text = labelText .. ": " .. val
            callback(val)
        end
    end)
    table.insert(activeConnections, inputChangedConn)
end

-- Hàm Nút bấm Thường (Teleport)
local function AddButton(page, labelText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    btn.TextColor3 = Color3.fromRGB(230, 235, 245)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansSemibold
    btn.Text = labelText
    btn.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
end

-- 1. Auto Farm Quái (Bay trên đầu quái, tự động đánh)
local farmConn = RunService.Heartbeat:Connect(function()
    if autoFarmActive then
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local target = nil
                local minDist = math.huge
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                        local isPlayer = Players:GetPlayerFromCharacter(obj)
                        if not isPlayer and obj ~= char and obj.Humanoid.Health > 0 then
                            local dist = (obj.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                target = obj
                            end
                        end
                    end
                end
                
                if target and target:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame + Vector3.new(0, 6, 0)
                    char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    
                    local tool = char:FindFirstChildOfClass("Tool")
                    if not tool then
                        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                        if backpack then
                            local t = backpack:FindFirstChildOfClass("Tool")
                            if t then 
                                char.Humanoid:EquipTool(t) 
                                task.wait(0.05)
                                tool = char:FindFirstChildOfClass("Tool")
                            end
                        end
                    end
                    
                    if tool then
                        tool:Activate()
                    else
                        VirtualUser:Button1Down(Vector2.new(0,0), Camera.CFrame)
                        task.wait(0.05)
                        VirtualUser:Button1Up(Vector2.new(0,0), Camera.CFrame)
                    end
                end
            end
        end)
    end
end)
table.insert(activeConnections, farmConn)
AddToggle(Page1, "🤖 Auto Farm (Bay Trên Đầu & Tự Động Đánh)", function(val) autoFarmActive = val end)

-- 2. Auto Quest
local questTask = task.spawn(function()
    while true do
        task.wait(1.5)
        if autoQuestActive then
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    for _, npc in ipairs(workspace:GetChildren()) do
                        if npc.Name == QuestNPCName and npc:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame + Vector3.new(0, 3, 3)
                            local cd = npc:FindFirstChildWhichIsA("ClickDetector", true)
                            if cd then
                                fireclickdetector(cd)
                            end
                        end
                    end
                end
            end)
        end
    end
end)
AddToggle(Page1, "📜 Auto Nhận Nhiệm Vụ (Auto Quest)", function(val) autoQuestActive = val end)

-- 3. Aimbot
local aimbotConn = RunService.RenderStepped:Connect(function()
    if aimbotActive then
        pcall(function()
            local closestTarget = nil
            local shortestDist = math.huge
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                    if obj ~= char and obj.Humanoid.Health > 0 then
                        local dist = (obj.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            closestTarget = obj.HumanoidRootPart
                        end
                    end
                end
            end
            
            if closestTarget then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestTarget.Position)
            end
        end)
    end
end)
table.insert(activeConnections, aimbotConn)
AddToggle(Page1, "🎯 Aimbot Tự Động Ngắm", function(val) aimbotActive = val end)

-- 4. NoClip
local noclipConn = RunService.Stepped:Connect(function()
    if noclipActive then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)
table.insert(activeConnections, noclipConn)
AddToggle(Page1, "👻 NoClip (Đi Xuyên Tường)", function(val) noclipActive = val end)

-- Hàm ESP Chung
local function updateESP(target, nameText, color)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    
    local bg = target:FindFirstChild("PeterESP_UI")
    if not bg then
        bg = Instance.new("BillboardGui")
        bg.Name = "PeterESP_UI"
        bg.Adornee = target:FindFirstChild("Head") or target.HumanoidRootPart
        bg.Size = UDim2.new(0, 140, 0, 50)
        bg.StudsOffset = Vector3.new(0, 2.8, 0)
        bg.AlwaysOnTop = true
        bg.Parent = target

        local txt = Instance.new("TextLabel")
        txt.Name = "NameLabel"
        txt.Size = UDim2.new(1, 0, 0, 22)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = color
        txt.TextSize = 13
        txt.Font = Enum.Font.SourceSansBold
        txt.TextStrokeTransparency = 0.4
        txt.Parent = bg

        local barBg = Instance.new("Frame")
        barBg.Name = "HPBarBg"
        barBg.Size = UDim2.new(0, 90, 0, 6)
        barBg.Position = UDim2.new(0.5, -45, 0, 24)
        barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        barBg.BorderSizePixel = 0
        barBg.Parent = bg

        local barBgCorner = Instance.new("UICorner")
        barBgCorner.CornerRadius = UDim.new(1, 0)
        barBgCorner.Parent = barBg

        local barFill = Instance.new("Frame")
        barFill.Name = "HPBarFill"
        barFill.Size = UDim2.new(1, 0, 1, 0)
        barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        barFill.BorderSizePixel = 0
        barFill.Parent = barBg

        local barFillCorner = Instance.new("UICorner")
        barFillCorner.CornerRadius = UDim.new(1, 0)
        barFillCorner.Parent = barFill
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

    local hum = target:FindFirstChildOfClass("Humanoid")
    if hum and bg then
        local nameLbl = bg:FindFirstChild("NameLabel")
        local fill = bg:FindFirstChild("HPBarBg") and bg.HPBarBg:FindFirstChild("HPBarFill")
        if nameLbl then
            nameLbl.Text = nameText .. " [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]"
        end
        if fill and hum.MaxHealth > 0 then
            fill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
        end
    end
end

local function removeESP(target)
    if target:FindFirstChild("PeterESP_UI") then target.PeterESP_UI:Destroy() end
    if target:FindFirstChild("PeterESP_HL") then target.PeterESP_HL:Destroy() end
end

-- 5. ESP Người Chơi
local espPlayerTask = task.spawn(function()
    while true do
        task.wait(0.8)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if espPlayerActive then
                    updateESP(p.Character, "👤 " .. p.Name, Color3.fromRGB(0, 170, 255))
                else
                    removeESP(p.Character)
                end
            end
        end
    end
end)
AddToggle(Page2, "👁️ ESP Người Chơi & Thanh Máu", function(val) espPlayerActive = val end)

-- 6. ESP Quái
local espMobTask = task.spawn(function()
    while true do
        task.wait(1)
        if espMobActive then
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                    local isPlayer = Players:GetPlayerFromCharacter(obj)
                    if not isPlayer then
                        updateESP(obj, "👾 " .. obj.Name, Color3.fromRGB(255, 50, 50))
                    end
                end
            end
        else
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                    local isPlayer = Players:GetPlayerFromCharacter(obj)
                    if not isPlayer then
                        removeESP(obj)
                    end
                end
            end
        end
    end
end)
AddToggle(Page2, "🎯 ESP Quái & Thanh Máu", function(val) espMobActive = val end)

-- 7. Nhìn Trong Đêm
AddToggle(Page2, "🔦 Nhìn Trong Đêm (Fullbright)", function(val)
    Lighting.Brightness = val and 2 or 1
    Lighting.ClockTime = val and 14 or 12
    Lighting.FogEnd = val and 100000 or 10000
    Lighting.GlobalShadows = not val
end)

-- 8. Chạy Nhanh
local currentSpeedValue = 50
local speedConn = RunService.RenderStepped:Connect(function()
    if speedActive then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = currentSpeedValue
        end
    end
end)
table.insert(activeConnections, speedConn)

AddToggle(Page3, "⚡ Bật/Tắt Chạy Nhanh", function(val)
    speedActive = val
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = val and currentSpeedValue or 16
    end
end)
AddSlider(Page3, "Tốc Độ Chạy (WalkSpeed)", 50, 200, 50, function(val)
    currentSpeedValue = val
    if speedActive then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end
end)

-- 9. Nhảy Cao
local currentJumpValue = 50
local jumpConn = RunService.RenderStepped:Connect(function()
    if jumpActive then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.UseJumpPower = true
            char.Humanoid.JumpPower = currentJumpValue
        end
    end
end)
table.insert(activeConnections, jumpConn)

AddToggle(Page3, "🦘 Bật/Tắt Nhảy Cao", function(val)
    jumpActive = val
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.UseJumpPower = true
        char.Humanoid.JumpPower = val and currentJumpValue or 50
    end
end)
AddSlider(Page3, "Sức Nhảy Cao (JumpPower)", 50, 300, 50, function(val)
    currentJumpValue = val
    if jumpActive then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.UseJumpPower = true
            char.Humanoid.JumpPower = val
        end
    end
end)

-- 10. Fix Lag Cực Mạnh
AddToggle(Page3, "🔥 Fix Lag Cực Mạnh (Tối Ưu Hóa Tối Đa)", function(val)
    boostActive = val
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
        if workspace:FindFirstChildOfClass("Terrain") then
            local terrain = workspace.Terrain
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

    for _, v in ipairs(workspace:GetDescendants()) do
        cleanPart(v)
    end

    if val then
        if not connectionBoost then
            connectionBoost = workspace.DescendantAdded:Connect(function(v)
                if boostActive then
                    task.spawn(function()
                        cleanPart(v)
                    end)
                end
            end)
        end
    else
        if connectionBoost then
            connectionBoost:Disconnect()
            connectionBoost = nil
        end
    end
end)

-- 11. Dịch Chuyển Đảo (Teleport)
local function TeleportTo(pos)
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    end)
end

for islandName, pos in pairs(IslandList) do
    AddButton(Page4, "🚀 Di chuyển tới: " .. islandName, function()
        TeleportTo(pos)
    end)
end
