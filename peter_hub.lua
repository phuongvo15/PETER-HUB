-- PETER HUB PRO - FULL TÍNH NĂNG - ĐÃ SỬA LỖI HOÀN TOÀN
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
    ["Đảo Khởi Đầu"]  = Vector3.new(0, 5, 0),
    ["Đảo Cướp Biển"] = Vector3.new(1000, 5, 1000),
    ["Đảo Cát"]       = Vector3.new(2500, 5, -1500),
    ["Đảo Trời"]      = Vector3.new(-4500, 500, 3500),
}
local QuestNPCName = "QuestGiver"

-- ============================================================
--  QUẢN LÝ VÒNG ĐỜI (Lifecycle Management)
-- ============================================================
local HubAlive = true
local activeConnections = {}
local activeThreads    = {}

local function SafeCall(func, ...)
    local ok, err = pcall(func, ...)
    if not ok then warn("[PeterHub] Lỗi:", err) end
end

local function RegConn(conn)
    table.insert(activeConnections, conn)
    return conn
end

local function RegThread(fn)
    local t = task.spawn(fn)
    table.insert(activeThreads, t)
    return t
end

-- ============================================================
--  DỌN SẠCH BẢN CŨ
-- ============================================================
if PlayerGui:FindFirstChild("PeterHubUI") then
    PlayerGui.PeterHubUI:Destroy()
end

-- ============================================================
--  SCREENGU & KHUNG CHÍNH
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name          = "PeterHubUI"
ScreenGui.ResetOnSpawn  = false
ScreenGui.Parent        = PlayerGui

-- Nút Toggle nổi
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size            = UDim2.new(0, 52, 0, 52)
ToggleBtn.Position        = UDim2.new(0, 20, 0.4, 0)
ToggleBtn.BackgroundColor3= Color3.fromRGB(0, 120, 255)
ToggleBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize        = 13
ToggleBtn.Font            = Enum.Font.SourceSansBold
ToggleBtn.Text            = "PETER"
ToggleBtn.Draggable       = true
ToggleBtn.Parent          = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

-- Khung chính
local MainFrame = Instance.new("Frame")
MainFrame.Size             = UDim2.new(0, 620, 0, 420)
MainFrame.Position         = UDim2.new(0.5, -310, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Draggable        = true
MainFrame.Parent           = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local isOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
end)

-- ============================================================
--  TRẠNG THÁI TÍNH NĂNG
-- ============================================================
local autoFarmActive  = false
local autoQuestActive = false
local aimbotActive    = false
local noclipActive    = false
local espPlayerActive = false
local espMobActive    = false
local speedActive     = false
local jumpActive      = false
local boostActive     = false

-- ============================================================
--  NÚT ĐÓNG HUB [X]  — dọn dẹp toàn diện
-- ============================================================
local function removeESP(target)
    if not target then return end
    local ui = target:FindFirstChild("PeterESP_UI")
    local hl = target:FindFirstChild("PeterESP_HL")
    if ui then ui:Destroy() end
    if hl then hl:Destroy() end
end

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 32, 0, 32)
CloseBtn.Position         = UDim2.new(1, -42, 0, 12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize         = 14
CloseBtn.Font             = Enum.Font.SourceSansBold
CloseBtn.Text             = "X"
CloseBtn.Parent           = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    HubAlive = false

    -- Tắt tất cả flag
    autoFarmActive  = false
    autoQuestActive = false
    aimbotActive    = false
    noclipActive    = false
    espPlayerActive = false
    espMobActive    = false
    speedActive     = false
    jumpActive      = false
    boostActive     = false

    -- Ngắt connections
    for _, c in ipairs(activeConnections) do
        if c and c.Connected then c:Disconnect() end
    end
    -- Hủy threads
    for _, t in ipairs(activeThreads) do
        task.cancel(t)
    end
    table.clear(activeConnections)
    table.clear(activeThreads)

    -- Xóa toàn bộ ESP còn sót
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "PeterESP_UI" or obj.Name == "PeterESP_HL" then
            SafeCall(function() obj:Destroy() end)
        end
    end

    -- Khôi phục nhân vật
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed    = 16
            hum.JumpPower    = 50
            hum.UseJumpPower = true
        end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end

    ScreenGui:Destroy()
end)

-- ============================================================
--  SIDEBAR & CONTENT AREA
-- ============================================================
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size             = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(6, 9, 15)
Sidebar.BorderSizePixel  = 0

local HubTitle = Instance.new("TextLabel", Sidebar)
HubTitle.Size               = UDim2.new(1, 0, 0, 55)
HubTitle.BackgroundTransparency = 1
HubTitle.TextColor3         = Color3.fromRGB(0, 150, 255)
HubTitle.TextSize           = 16
HubTitle.Font               = Enum.Font.SourceSansBold
HubTitle.Text               = "⚡ PETER HUB PRO"

local SidebarList = Instance.new("UIListLayout", Sidebar)
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding   = UDim.new(0, 6)

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size             = UDim2.new(1, -160, 1, 0)
ContentArea.Position         = UDim2.new(0, 160, 0, 0)
ContentArea.BackgroundTransparency = 1

local Pages = {}
local function CreatePage(name)
    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Size               = UDim2.new(1, -20, 1, -20)
    page.Position           = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.CanvasSize         = UDim2.new(0, 0, 0, 750)
    page.ScrollBarThickness = 3
    page.Visible            = false

    local layout = Instance.new("UIListLayout", page)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 8)

    local btn = Instance.new("TextButton", Sidebar)
    btn.Size             = UDim2.new(1, -12, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(15, 22, 35)
    btn.TextColor3       = Color3.fromRGB(200, 210, 230)
    btn.TextSize         = 13
    btn.Font             = Enum.Font.SourceSansSemibold
    btn.Text             = name
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

-- ============================================================
--  UI HELPERS: AddToggle / AddSlider / AddButton
-- ============================================================
local function AddToggle(page, labelText, callback)
    local row = Instance.new("Frame", page)
    row.Size             = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", row)
    label.Size               = UDim2.new(0.65, 0, 1, 0)
    label.Position           = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3         = Color3.fromRGB(230, 235, 245)
    label.TextSize           = 13
    label.Font               = Enum.Font.SourceSansSemibold
    label.TextXAlignment     = Enum.TextXAlignment.Left
    label.Text               = labelText

    local switchBg = Instance.new("TextButton", row)
    switchBg.Size             = UDim2.new(0, 52, 0, 28)
    switchBg.Position         = UDim2.new(1, -64, 0.5, -14)
    switchBg.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    switchBg.Text             = ""
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)

    local switchKnob = Instance.new("Frame", switchBg)
    switchKnob.Size             = UDim2.new(0, 22, 0, 22)
    switchKnob.Position         = UDim2.new(0, 3, 0.5, -11)
    switchKnob.BackgroundColor3 = Color3.fromRGB(200, 205, 215)
    Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(1, 0)

    local state = false
    switchBg.MouseButton1Click:Connect(function()
        state = not state
        if state then
            switchBg.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
            switchKnob.Position        = UDim2.new(1, -25, 0.5, -11)
            switchKnob.BackgroundColor3= Color3.fromRGB(255, 255, 255)
        else
            switchBg.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
            switchKnob.Position        = UDim2.new(0, 3, 0.5, -11)
            switchKnob.BackgroundColor3= Color3.fromRGB(200, 205, 215)
        end
        SafeCall(callback, state)
    end)
end

local function AddSlider(page, labelText, minVal, maxVal, defaultVal, callback)
    local row = Instance.new("Frame", page)
    row.Size             = UDim2.new(1, 0, 0, 62)
    row.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", row)
    label.Size               = UDim2.new(1, -20, 0, 25)
    label.Position           = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.TextColor3         = Color3.fromRGB(230, 235, 245)
    label.TextSize           = 13
    label.Font               = Enum.Font.SourceSansSemibold
    label.TextXAlignment     = Enum.TextXAlignment.Left
    label.Text               = labelText .. ": " .. defaultVal

    local sliderBar = Instance.new("TextButton", row)
    sliderBar.Size             = UDim2.new(1, -28, 0, 10)
    sliderBar.Position         = UDim2.new(0, 14, 0, 38)
    sliderBar.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    sliderBar.Text             = ""
    Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame", sliderBar)
    sliderFill.Size             = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    sliderFill.BorderSizePixel  = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    sliderBar.MouseButton1Down:Connect(function() dragging = true end)

    RegConn(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    RegConn(UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local pct = math.clamp(
                (inp.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X,
                0, 1
            )
            sliderFill.Size = UDim2.new(pct, 0, 1, 0)
            local val = math.floor(minVal + (maxVal - minVal) * pct)
            label.Text = labelText .. ": " .. val
            SafeCall(callback, val)
        end
    end))
end

local function AddButton(page, labelText, callback)
    local btn = Instance.new("TextButton", page)
    btn.Size             = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(16, 23, 36)
    btn.TextColor3       = Color3.fromRGB(230, 235, 245)
    btn.TextSize         = 13
    btn.Font             = Enum.Font.SourceSansSemibold
    btn.Text             = labelText
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(function() SafeCall(callback) end)
end

-- ============================================================
--  CACHE MOB (cập nhật 1s/lần - không quét trong frame)
-- ============================================================
local cachedMobs = {}
RegThread(function()
    while HubAlive do
        local newList = {}
        SafeCall(function()
            local char = LocalPlayer.Character
            for _, obj in ipairs(Workspace:GetChildren()) do
                if  obj:IsA("Model")
                and obj ~= char
                and obj:FindFirstChild("Humanoid")
                and obj:FindFirstChild("HumanoidRootPart")
                and not Players:GetPlayerFromCharacter(obj)
                and obj.Humanoid.Health > 0
                then
                    table.insert(newList, obj)
                end
            end
        end)
        cachedMobs = newList
        task.wait(1)
    end
end)

-- ============================================================
--  1. AUTO FARM  (Heartbeat — không có task.wait bên trong)
-- ============================================================
local farmCooldown = 0
RegConn(RunService.Heartbeat:Connect(function(dt)
    if not autoFarmActive then return end
    farmCooldown = farmCooldown - dt
    if farmCooldown > 0 then return end
    farmCooldown = 0.1  -- 10 lần/giây thay vì 60 lần/giây

    SafeCall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        -- Tìm mục tiêu gần nhất trong cache
        local target, minDist = nil, math.huge
        for _, obj in ipairs(cachedMobs) do
            if obj.Parent and obj.Humanoid.Health > 0 then
                local d = (obj.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < minDist then minDist = d ; target = obj end
            end
        end

        if not target then return end

        -- Bay lên đầu mục tiêu
        hrp.CFrame    = target.HumanoidRootPart.CFrame + Vector3.new(0, 6, 0)
        hrp.Velocity  = Vector3.zero

        -- Lấy tool từ tay hoặc túi
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            if bp then tool = bp:FindFirstChildOfClass("Tool") end
        end
        if tool and tool.Parent ~= char then
            hum:EquipTool(tool)
        end

        if tool then
            tool:Activate()
        else
            VirtualUser:Button1Down(Vector2.new(0, 0), Camera.CFrame)
            VirtualUser:Button1Up(Vector2.new(0, 0), Camera.CFrame)
        end
    end)
end))
AddToggle(Page1, "🤖 Auto Farm (Bay Trên Đầu & Tự Đánh)", function(val) autoFarmActive = val end)

-- ============================================================
--  2. AUTO QUEST
-- ============================================================
RegThread(function()
    while HubAlive do
        task.wait(1.5)
        if not autoQuestActive then continue end
        SafeCall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            for _, npc in ipairs(Workspace:GetChildren()) do
                if npc.Name == QuestNPCName and npc:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame + Vector3.new(0, 3, 3)
                    local cd = npc:FindFirstChildWhichIsA("ClickDetector", true)
                    if cd then fireclickdetector(cd) end
                end
            end
        end)
    end
end)
AddToggle(Page1, "📜 Auto Nhận Nhiệm Vụ (Auto Quest)", function(val) autoQuestActive = val end)

-- ============================================================
--  3. AIMBOT (nhắm cả NPC + Player)
-- ============================================================
RegConn(RunService.RenderStepped:Connect(function()
    if not aimbotActive then return end
    SafeCall(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrpPos = char.HumanoidRootPart.Position

        local closest, shortDist = nil, math.huge

        -- Nhắm Player
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hum = p.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local d = (p.Character.HumanoidRootPart.Position - hrpPos).Magnitude
                    if d < shortDist then shortDist = d ; closest = p.Character.HumanoidRootPart end
                end
            end
        end

        -- Nhắm Mob (dùng cache)
        for _, obj in ipairs(cachedMobs) do
            if obj.Parent and obj.Humanoid.Health > 0 then
                local d = (obj.HumanoidRootPart.Position - hrpPos).Magnitude
                if d < shortDist then shortDist = d ; closest = obj.HumanoidRootPart end
            end
        end

        if closest then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position)
        end
    end)
end))
AddToggle(Page1, "🎯 Aimbot Tự Động Ngắm (Player + Mob)", function(val) aimbotActive = val end)

-- ============================================================
--  4. NOCLIP — FIX: cache parts ngay khi script chạy
-- ============================================================
local noclipParts = {}

local function RebuildNoclipCache(char)
    table.clear(noclipParts)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(noclipParts, p) end
    end
    -- Lắng nghe thêm part mới (vd: tool được trang bị)
    RegConn(char.DescendantAdded:Connect(function(p)
        if p:IsA("BasePart") then table.insert(noclipParts, p) end
    end))
end

-- Cache ngay lập tức cho character hiện tại (FIX BUG 1)
if LocalPlayer.Character then
    RebuildNoclipCache(LocalPlayer.Character)
end
RegConn(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait() -- Đợi 1 frame để descendants load
    RebuildNoclipCache(char)
end))

RegConn(RunService.Stepped:Connect(function()
    if not noclipActive then return end
    for _, part in ipairs(noclipParts) do
        if part and part.Parent then
            part.CanCollide = false
        end
    end
end))
AddToggle(Page1, "👻 NoClip (Đi Xuyên Tường)", function(val) noclipActive = val end)

-- ============================================================
--  ESP HELPERS
-- ============================================================
local function updateESP(target, nameText, color)
    if not target or not target.Parent then return end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local hum = target:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- BillboardGui
    local bg = target:FindFirstChild("PeterESP_UI")
    if not bg then
        bg = Instance.new("BillboardGui")
        bg.Name        = "PeterESP_UI"
        bg.Adornee     = target:FindFirstChild("Head") or hrp
        bg.Size        = UDim2.new(0, 140, 0, 50)
        bg.StudsOffset = Vector3.new(0, 2.8, 0)
        bg.AlwaysOnTop = true
        bg.Parent      = target

        local txt = Instance.new("TextLabel", bg)
        txt.Name                  = "NameLabel"
        txt.Size                  = UDim2.new(1, 0, 0, 22)
        txt.BackgroundTransparency= 1
        txt.TextColor3            = color
        txt.TextSize              = 13
        txt.Font                  = Enum.Font.SourceSansBold
        txt.TextStrokeTransparency= 0.4

        local barBg = Instance.new("Frame", bg)
        barBg.Name             = "HPBarBg"
        barBg.Size             = UDim2.new(0, 90, 0, 6)
        barBg.Position         = UDim2.new(0.5, -45, 0, 24)
        barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        barBg.BorderSizePixel  = 0
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local barFill = Instance.new("Frame", barBg)
        barFill.Name             = "HPBarFill"
        barFill.Size             = UDim2.new(1, 0, 1, 0)
        barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        barFill.BorderSizePixel  = 0
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
    end

    -- Highlight
    if not target:FindFirstChild("PeterESP_HL") then
        local hl = Instance.new("Highlight")
        hl.Name         = "PeterESP_HL"
        hl.Adornee      = target
        hl.FillColor    = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.Parent       = target
    end

    -- Cập nhật nội dung
    local nameLbl = bg:FindFirstChild("NameLabel")
    local fill    = bg:FindFirstChild("HPBarBg") and bg.HPBarBg:FindFirstChild("HPBarFill")
    if nameLbl then
        nameLbl.Text = string.format("%s [%d/%d]", nameText, math.floor(hum.Health), math.floor(hum.MaxHealth))
    end
    if fill and hum.MaxHealth > 0 then
        fill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
    end
end

-- ============================================================
--  5. ESP NGƯỜI CHƠI
-- ============================================================
RegThread(function()
    while HubAlive do
        task.wait(0.8)
        SafeCall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    if espPlayerActive then
                        updateESP(p.Character, "👤 " .. p.Name, Color3.fromRGB(0, 170, 255))
                    else
                        removeESP(p.Character)
                    end
                end
            end
        end)
    end
end)
AddToggle(Page2, "👁️ ESP Người Chơi & Thanh Máu", function(val) espPlayerActive = val end)

-- ============================================================
--  6. ESP QUÁI VẬT
-- ============================================================
RegThread(function()
    while HubAlive do
        task.wait(1)
        SafeCall(function()
            for _, obj in ipairs(cachedMobs) do
                if obj.Parent then
                    if espMobActive then
                        updateESP(obj, "👾 " .. obj.Name, Color3.fromRGB(255, 50, 50))
                    else
                        removeESP(obj)
                    end
                end
            end
        end)
    end
end)
AddToggle(Page2, "🎯 ESP Quái & Thanh Máu", function(val) espMobActive = val end)

-- ============================================================
--  7. NHÌN TRONG ĐÊM (FULLBRIGHT)
-- ============================================================
AddToggle(Page2, "🔦 Nhìn Trong Đêm (Fullbright)", function(val)
    Lighting.Brightness    = val and 2 or 1
    Lighting.ClockTime     = val and 14 or 12
    Lighting.FogEnd        = val and 100000 or 10000
    Lighting.GlobalShadows = not val
end)

-- ============================================================
--  8. CHẠY NHANH
-- ============================================================
local currentSpeedValue = 50

RegConn(RunService.RenderStepped:Connect(function()
    if not speedActive then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = currentSpeedValue
    end
end))

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

-- ============================================================
--  9. NHẢY CAO
-- ============================================================
local currentJumpValue = 50

RegConn(RunService.RenderStepped:Connect(function()
    if not jumpActive then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.UseJumpPower = true
        char.Humanoid.JumpPower    = currentJumpValue
    end
end))

AddToggle(Page3, "🦘 Bật/Tắt Nhảy Cao", function(val)
    jumpActive = val
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.UseJumpPower = true
        char.Humanoid.JumpPower    = val and currentJumpValue or 50
    end
end)
AddSlider(Page3, "Sức Nhảy Cao (JumpPower)", 50, 300, 50, function(val)
    currentJumpValue = val
    if jumpActive then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = val
        end
    end
end)

-- ============================================================
--  10. FIX LAG CỰC MẠNH
-- ============================================================
local connectionBoost = nil  -- Quản lý thủ công, KHÔNG dùng RegConn

local function cleanPart(v, isOn)
    if not v or not v.Parent then return end
    if v:IsA("BasePart") then
        v.Material    = isOn and Enum.Material.SmoothPlastic or Enum.Material.Plastic
        v.Reflectance = 0
        v.CastShadow  = false
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v.Transparency = isOn and 1 or 0
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire")
        or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Beam") or v:IsA("Explosion")
    then
        v.Enabled = not isOn
    end
end

AddToggle(Page3, "🔥 Fix Lag Cực Mạnh (Tối Ưu Đồ Họa)", function(val)
    boostActive = val

    Lighting.GlobalShadows  = not val
    Lighting.FogEnd         = val and 9e9 or 100000
    Lighting.Brightness     = val and 2 or 1
    Lighting.OutdoorAmbient = val
        and Color3.fromRGB(220, 220, 220)
        or  Color3.fromRGB(128, 128, 128)

    for _, light in ipairs(Lighting:GetChildren()) do
        if  light:IsA("PostEffect") or light:IsA("Atmosphere") or light:IsA("Sky")
        or  light:IsA("BlurEffect") or light:IsA("SunRaysEffect") or light:IsA("ColorCorrectionEffect")
        then
            light.Enabled = not val
        end
    end

    SafeCall(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize    = val and 0   or 1
            terrain.WaterWaveSpeed   = val and 0   or 8
            terrain.WaterTransparency= val and 1   or 0.3
            terrain.WaterReflectance = val and 0   or 1
        end
    end)

    for _, v in ipairs(Workspace:GetDescendants()) do
        cleanPart(v, val)
    end

    if val then
        if not connectionBoost then
            connectionBoost = Workspace.DescendantAdded:Connect(function(v)
                if boostActive then task.spawn(cleanPart, v, true) end
            end)
        end
    else
        if connectionBoost then
            connectionBoost:Disconnect()
            connectionBoost = nil
        end
    end
end)

-- ============================================================
--  11. DỊCH CHUYỂN ĐẢO (TELEPORT)
-- ============================================================
for islandName, pos in pairs(IslandList) do
    AddButton(Page4, "🚀 Di chuyển tới: " .. islandName, function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    end)
end
