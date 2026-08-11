-- PETER HUB - Phiên bản Tối Ưu & Giao Diện Đỉnh Cao
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Xóa bảng cũ nếu đã tồn tại để tránh trùng lặp
if PlayerGui:FindFirstChild("PeterHubUI") then
    PlayerGui.PeterHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PeterHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- ==================== 1. NÚT NỔI MỞ/ĐÓNG MENU ====================
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

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(100, 180, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

-- ==================== 2. KHUNG GIAO DIỆN CHÍNH ====================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 580, 0, 400)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(30, 45, 75)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local isOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
end)

-- ==================== 3. THANH ĐIỀU HƯỚNG BÊN TRÁI (SIDEBAR) ====================
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(6, 9, 15)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 12)
SidebarCorner.Parent = Sidebar

local HubTitle = Instance.new("TextLabel")
HubTitle.Size = UDim2.new(1, 0, 0, 55)
HubTitle.BackgroundTransparency = 1
HubTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
HubTitle.TextSize = 17
HubTitle.Font = Enum.Font.SourceSansBold
HubTitle.Text = "⚡ PETER HUB PRO"
HubTitle.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 6)
SidebarList.Parent = Sidebar

-- ==================== 4. KHUNG NỘI DUNG (CONTENT AREA) ====================
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
    page.CanvasSize = UDim2.new(0, 0, 0, 500)
    page.ScrollBarThickness = 3
    page.Visible = false
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = page

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 42)
    btn.Position = UDim2.new(0, 6, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(15, 22, 35)
    btn.TextColor3 = Color3.fromRGB(200, 210, 230)
    btn.TextSize = 14
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

Page1.Visible = true

-- Hàm tạo nút gạt (Toggle Switch)
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
    label.TextSize = 14
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

-- Hàm tạo thanh trượt (Slider)
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
    label.TextSize = 14
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

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            sliderFill.Size = UDim2.new(pos, 0, 1, 0)
            local val = math.floor(minVal + (maxVal - minVal) * pos)
            label.Text = labelText .. ": " .. val
            callback(val)
        end
    end)
end

-- ==================== 5. CÁC TÍNH NĂNG CHÍNH ====================

-- 1. Auto Farm Quái
local autoFarmActive = false
task.spawn(function()
    while true do
        task.wait(0.3)
        if autoFarmActive then
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                            local isPlayer = Players:GetPlayerFromCharacter(obj)
                            if not isPlayer and obj ~= char and obj.Humanoid.Health > 0 then
                                char.HumanoidRootPart.CFrame = obj.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
end)

AddToggle(Page1, "🤖 Auto Farm Quái", function(val)
    autoFarmActive = val
end)

-- 2. Aimbot (Tự động ngắm)
local aimbotActive = false
RunService.RenderStepped:Connect(function()
    if aimbotActive then
        pcall(function()
            local closestTarget = nil
            local shortestDist = math.huge
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            for _, obj in ipairs(workspace:GetDescendants()) do
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

AddToggle(Page1, "🎯 Aimbot Tự Động Ngắm", function(val)
    aimbotActive = val
end)

-- 3. NoClip (Đi xuyên tường)
local noclipActive = false
RunService.Stepped:Connect(function()
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

AddToggle(Page1, "👻 NoClip (Đi Xuyên Tường)", function(val)
    noclipActive = val
end)

-- 4. ESP Người Chơi
local espPlayerActive = false
task.spawn(function()
    while true do
        task.wait(1)
        if espPlayerActive then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    if not p.Character:FindFirstChild("PeterPlayerHighlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "PeterPlayerHighlight"
                        hl.Adornee = p.Character
                        hl.FillColor = Color3.fromRGB(0, 150, 255)
                        hl.Parent = p.Character
                    end
                end
            end
        else
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("PeterPlayerHighlight") then
                    p.Character.PeterPlayerHighlight:Destroy()
                end
            end
        end
    end
end)

AddToggle(Page2, "👁️ ESP Người Chơi (Xanh)", function(val)
    espPlayerActive = val
end)

-- 5. ESP Quái
local espMobActive = false
task.spawn(function()
    while true do
        task.wait(1)
        if espMobActive then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                    local isPlayer = Players:GetPlayerFromCharacter(obj)
                    if not isPlayer and not obj:FindFirstChild("PeterMobHighlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "PeterMobHighlight"
                        hl.Adornee = obj
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.Parent = obj
                    end
                end
            end
        else
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("PeterMobHighlight") then
                    obj.PeterMobHighlight:Destroy()
                end
            end
        end
    end
end)

AddToggle(Page2, "🎯 ESP Quái / Mục Tiêu (Đỏ)", function(val)
    espMobActive = val
end)

-- 6. Nhìn Trong Đêm (Fullbright)
local fullbrightActive = false
Lighting.Changed:Connect(function()
    if fullbrightActive then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    end
end)

AddToggle(Page2, "🔦 Nhìn Trong Đêm (Fullbright)", function(val)
    fullbrightActive = val
    if val then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = true
    end
end)

-- 7. Chạy Nhanh (WalkSpeed kèm Bật/Tắt)
local speedActive = false
local currentSpeedValue = 50
RunService.RenderStepped:Connect(function()
    if speedActive then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = currentSpeedValue
        end
    end
end)

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

-- 8. Nhảy Cao (JumpPower kèm Bật/Tắt)
local jumpActive = false
local currentJumpValue = 50
RunService.RenderStepped:Connect(function()
    if jumpActive then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.UseJumpPower = true
            char.Humanoid.JumpPower = currentJumpValue
        end
    end
end)

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

-- 9. Tối Ưu / Fix Lag Cực Mạnh (Ultra Boost)
AddToggle(Page3, "🔥 Fix Lag Tối Đa (Ultra Boost)", function(val)
    Lighting.GlobalShadows = not val
    Lighting.FogEnd = val and 9e9 or 100000
    Lighting.Brightness = val and 2 or 1
    
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = val and Enum.Material.SmoothPlastic or Enum.Material.Plastic
            v.Reflectance = val and 0 or v.Reflectance
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = val and 1 or 0
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = not val
        end
    end
end)