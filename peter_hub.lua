-- ╔══════════════════════════════════════════════════════════╗
-- ║           PETER HUB PRO v3 - FULL & FIXED              ║
-- ╚══════════════════════════════════════════════════════════╝

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting       = game:GetService("Lighting")
local VirtualUser    = game:GetService("VirtualUser")
local TweenService   = game:GetService("TweenService")

local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════
-- CẤU HÌNH
-- ══════════════════════════════════════════════════════════
local IslandList = {
    ["Đảo Khởi Đầu"]  = Vector3.new(0,    5,    0),
    ["Đảo Cướp Biển"] = Vector3.new(1000,  5, 1000),
    ["Đảo Cát"]       = Vector3.new(2500,  5, -1500),
    ["Đảo Trời"]      = Vector3.new(-4500,500,  3500),
}
local QuestNPCName   = "QuestGiver"
local FARM_HEIGHT    = 8    -- Độ cao bay trên đầu quái (studs)
local FARM_COOLDOWN  = 0.08 -- Tần suất đánh (giây)

-- ══════════════════════════════════════════════════════════
-- QUẢN LÝ VÒNG ĐỜI
-- ══════════════════════════════════════════════════════════
local HubAlive       = true
local Connections    = {}
local Threads        = {}
local connectionBoost = nil

local function AddConn(c)   table.insert(Connections, c) end
local function AddThread(fn) table.insert(Threads, task.spawn(fn)) end

-- Dọn UI cũ
if PlayerGui:FindFirstChild("PeterHubUI") then
    PlayerGui.PeterHubUI:Destroy()
end

-- ══════════════════════════════════════════════════════════
-- TRẠNG THÁI TÍNH NĂNG
-- ══════════════════════════════════════════════════════════
local S = {
    AutoFarm  = false,
    AutoQuest = false,
    Aimbot    = false,
    Noclip    = false,
    EspPlayer = false,
    EspMob    = false,
    Speed     = false,
    Jump      = false,
    Boost     = false,
}
local speedVal = 50
local jumpVal  = 50

-- ══════════════════════════════════════════════════════════
-- HELPER: Lấy character an toàn
-- ══════════════════════════════════════════════════════════
local function GetChar()
    local c = LocalPlayer.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return c, hrp, hum
end

-- ══════════════════════════════════════════════════════════
-- UI KHUNG CHÍNH
-- ══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "PeterHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent       = PlayerGui

-- Nút nổi Toggle
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size              = UDim2.new(0,54,0,54)
ToggleBtn.Position          = UDim2.new(0,20,0.4,0)
ToggleBtn.BackgroundColor3  = Color3.fromRGB(0,120,255)
ToggleBtn.TextColor3        = Color3.fromRGB(255,255,255)
ToggleBtn.TextSize          = 12
ToggleBtn.Font              = Enum.Font.SourceSansBold
ToggleBtn.Text              = "⚡\nPETER"
ToggleBtn.Draggable         = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1,0)

-- Khung chính
local Main = Instance.new("Frame", ScreenGui)
Main.Size              = UDim2.new(0,640,0,440)
Main.Position          = UDim2.new(0.5,-320,0.5,-220)
Main.BackgroundColor3  = Color3.fromRGB(10,14,22)
Main.BorderSizePixel   = 0
Main.Active            = true
Main.Draggable         = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)

-- Viền gradient
local stroke = Instance.new("UIStroke", Main)
stroke.Color     = Color3.fromRGB(0,100,220)
stroke.Thickness = 1.5

local isOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    Main.Visible = isOpen
end)

-- ══════════════════════════════════════════════════════════
-- NÚT ĐÓNG [X]
-- ══════════════════════════════════════════════════════════
local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size             = UDim2.new(0,32,0,32)
CloseBtn.Position         = UDim2.new(1,-44,0,12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220,50,50)
CloseBtn.TextColor3       = Color3.fromRGB(255,255,255)
CloseBtn.TextSize         = 15
CloseBtn.Font             = Enum.Font.SourceSansBold
CloseBtn.Text             = "✕"
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,8)

CloseBtn.MouseButton1Click:Connect(function()
    HubAlive = false
    S.AutoFarm=false S.AutoQuest=false S.Aimbot=false S.Noclip=false
    S.EspPlayer=false S.EspMob=false S.Speed=false S.Jump=false S.Boost=false

    -- Ngắt tất cả
    for _,c in ipairs(Connections) do if c and c.Connected then c:Disconnect() end end
    for _,t in ipairs(Threads)     do task.cancel(t) end
    if connectionBoost then connectionBoost:Disconnect() connectionBoost=nil end

    -- Xóa ESP
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj.Name=="PESP_UI" or obj.Name=="PESP_HL" then pcall(obj.Destroy,obj) end
    end

    -- Khôi phục nhân vật
    local c,hrp,hum = GetChar()
    if hum then hum.WalkSpeed=16 hum.JumpPower=50 hum.UseJumpPower=true end
    if c then
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end
    ScreenGui:Destroy()
end)

-- ══════════════════════════════════════════════════════════
-- SIDEBAR
-- ══════════════════════════════════════════════════════════
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size             = UDim2.new(0,165,1,0)
Sidebar.BackgroundColor3 = Color3.fromRGB(6,9,15)
Sidebar.BorderSizePixel  = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,14)

local Title = Instance.new("TextLabel", Sidebar)
Title.Size               = UDim2.new(1,0,0,58)
Title.BackgroundTransparency = 1
Title.TextColor3         = Color3.fromRGB(0,160,255)
Title.TextSize           = 15
Title.Font               = Enum.Font.SourceSansBold
Title.Text               = "⚡ PETER HUB PRO"

local SbLayout = Instance.new("UIListLayout", Sidebar)
SbLayout.SortOrder = Enum.SortOrder.LayoutOrder
SbLayout.Padding   = UDim.new(0,4)

local SbPad = Instance.new("UIPadding", Sidebar)
SbPad.PaddingLeft  = UDim.new(0,6)
SbPad.PaddingRight = UDim.new(0,6)

-- Content Area
local Content = Instance.new("Frame", Main)
Content.Size                 = UDim2.new(1,-165,1,0)
Content.Position             = UDim2.new(0,165,0,0)
Content.BackgroundTransparency = 1

-- ══════════════════════════════════════════════════════════
-- TẠO TRANG
-- ══════════════════════════════════════════════════════════
local Pages = {}
local activeBtn = nil

local function CreatePage(icon, name)
    local scroll = Instance.new("ScrollingFrame", Content)
    scroll.Size               = UDim2.new(1,-14,1,-12)
    scroll.Position           = UDim2.new(0,7,0,6)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize         = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0,120,255)
    scroll.Visible            = false
    local lay = Instance.new("UIListLayout", scroll)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding   = UDim.new(0,7)

    local navBtn = Instance.new("TextButton", Sidebar)
    navBtn.Size             = UDim2.new(1,0,0,40)
    navBtn.BackgroundColor3 = Color3.fromRGB(14,20,34)
    navBtn.TextColor3       = Color3.fromRGB(180,195,220)
    navBtn.TextSize         = 12
    navBtn.Font             = Enum.Font.SourceSansSemibold
    navBtn.Text             = icon.." "..name
    navBtn.TextXAlignment   = Enum.TextXAlignment.Left
    local np = Instance.new("UIPadding", navBtn)
    np.PaddingLeft = UDim.new(0,10)
    Instance.new("UICorner", navBtn).CornerRadius = UDim.new(0,8)

    navBtn.MouseButton1Click:Connect(function()
        for _,p in pairs(Pages) do p.Visible=false end
        scroll.Visible = true
        if activeBtn then
            activeBtn.BackgroundColor3 = Color3.fromRGB(14,20,34)
            activeBtn.TextColor3       = Color3.fromRGB(180,195,220)
        end
        navBtn.BackgroundColor3 = Color3.fromRGB(0,90,200)
        navBtn.TextColor3       = Color3.fromRGB(255,255,255)
        activeBtn = navBtn
    end)
    table.insert(Pages, scroll)
    return scroll, navBtn
end

local P1,B1 = CreatePage("⚔️","Auto & Chiến Đấu")
local P2,B2 = CreatePage("👁️","ESP & Tầm Nhìn")
local P3,B3 = CreatePage("🛠️","Tốc Độ & Đồ Họa")
local P4,B4 = CreatePage("🗺️","Dịch Chuyển Đảo")

-- Mở trang đầu
P1.Visible = true
B1.BackgroundColor3 = Color3.fromRGB(0,90,200)
B1.TextColor3       = Color3.fromRGB(255,255,255)
activeBtn = B1

-- ══════════════════════════════════════════════════════════
-- UI HELPERS
-- ══════════════════════════════════════════════════════════
local function MakeRow(parent, h)
    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(1,0,0,h or 48)
    f.BackgroundColor3 = Color3.fromRGB(15,22,36)
    f.BorderSizePixel  = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,9)
    return f
end

local function AddToggle(page, text, onToggle)
    local row = MakeRow(page, 48)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size               = UDim2.new(0.68,0,1,0)
    lbl.Position           = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3         = Color3.fromRGB(225,232,248)
    lbl.TextSize           = 13
    lbl.Font               = Enum.Font.SourceSansSemibold
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = text
    lbl.TextWrapped        = true

    local track = Instance.new("Frame", row)
    track.Size             = UDim2.new(0,52,0,28)
    track.Position         = UDim2.new(1,-66,0.5,-14)
    track.BackgroundColor3 = Color3.fromRGB(35,45,65)
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0,22,0,22)
    knob.Position         = UDim2.new(0,3,0.5,-11)
    knob.BackgroundColor3 = Color3.fromRGB(190,200,215)
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local btn = Instance.new("TextButton", track)
    btn.Size               = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text               = ""

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            track.BackgroundColor3 = Color3.fromRGB(0,140,255)
            knob.Position          = UDim2.new(1,-25,0.5,-11)
            knob.BackgroundColor3  = Color3.fromRGB(255,255,255)
        else
            track.BackgroundColor3 = Color3.fromRGB(35,45,65)
            knob.Position          = UDim2.new(0,3,0.5,-11)
            knob.BackgroundColor3  = Color3.fromRGB(190,200,215)
        end
        pcall(onToggle, state)
    end)
end

local function AddSlider(page, text, mn, mx, def, onChange)
    local row = MakeRow(page, 66)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size               = UDim2.new(1,-20,0,26)
    lbl.Position           = UDim2.new(0,12,0,5)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3         = Color3.fromRGB(225,232,248)
    lbl.TextSize           = 13
    lbl.Font               = Enum.Font.SourceSansSemibold
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = text..": "..def

    local barBg = Instance.new("Frame", row)
    barBg.Size             = UDim2.new(1,-24,0,10)
    barBg.Position         = UDim2.new(0,12,0,40)
    barBg.BackgroundColor3 = Color3.fromRGB(30,40,60)
    barBg.BorderSizePixel  = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", barBg)
    fill.Size             = UDim2.new((def-mn)/(mx-mn),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(0,140,255)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local hitbox = Instance.new("TextButton", barBg)
    hitbox.Size               = UDim2.new(1,0,1,0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text               = ""

    local dragging = false
    hitbox.MouseButton1Down:Connect(function() dragging=true end)
    AddConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end))
    AddConn(UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local pct = math.clamp((i.Position.X - barBg.AbsolutePosition.X)/barBg.AbsoluteSize.X,0,1)
            fill.Size = UDim2.new(pct,0,1,0)
            local val = math.floor(mn+(mx-mn)*pct)
            lbl.Text  = text..": "..val
            pcall(onChange,val)
        end
    end))
end

local function AddButton(page, text, onClick)
    local btn = Instance.new("TextButton", page)
    btn.Size             = UDim2.new(1,0,0,44)
    btn.BackgroundColor3 = Color3.fromRGB(0,85,185)
    btn.TextColor3       = Color3.fromRGB(255,255,255)
    btn.TextSize         = 13
    btn.Font             = Enum.Font.SourceSansSemibold
    btn.Text             = text
    btn.BorderSizePixel  = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,9)
    btn.MouseButton1Click:Connect(function() pcall(onClick) end)

    btn.MouseEnter:Connect(function() btn.BackgroundColor3=Color3.fromRGB(0,110,230) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3=Color3.fromRGB(0,85,185) end)
end

local function AddLabel(page, text)
    local lbl = Instance.new("TextLabel", page)
    lbl.Size               = UDim2.new(1,0,0,28)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3         = Color3.fromRGB(100,140,200)
    lbl.TextSize           = 12
    lbl.Font               = Enum.Font.SourceSansSemibold
    lbl.Text               = "  "..text
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
end

-- ══════════════════════════════════════════════════════════
-- CACHE QUÁI VẬT (quét workspace sâu hơn - GetDescendants)
-- ══════════════════════════════════════════════════════════
local cachedMobs = {}
AddThread(function()
    while HubAlive do
        local list = {}
        local char = LocalPlayer.Character
        -- Quét cả GetDescendants để tìm Model trong folder lồng nhau
        for _, obj in ipairs(workspace:GetDescendants()) do
            if  obj:IsA("Model")
            and obj ~= char
            and obj:FindFirstChild("Humanoid")
            and obj:FindFirstChild("HumanoidRootPart")
            and not Players:GetPlayerFromCharacter(obj)
            then
                if obj.Humanoid.Health > 0 then
                    table.insert(list, obj)
                end
            end
        end
        cachedMobs = list
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════════════════════
-- 1. AUTO FARM - Bay vuông quanh đầu quái + Tự động đánh + Tay Dài
-- ══════════════════════════════════════════════════════════
AddLabel(P1, "── AUTO FARM ──────────────────")

local farmAngle   = 0
local farmTimer   = 0
local FARM_RADIUS = 6     -- Bán kính bay
local FARM_HEIGHT = 9     -- Độ cao
local FARM_ORBIT  = 1.8   -- Tốc độ quay
local FARM_ATK_CD = 0.1   -- Tốc độ đánh

local VirtualInputManager = game:GetService("VirtualInputManager")

local SQUARE = {
    Vector3.new( 1,  0,  1),
    Vector3.new(-1,  0,  1),
    Vector3.new(-1,  0, -1),
    Vector3.new( 1,  0, -1),
}

-- Hàm tự động trang bị vũ khí (nếu đang cất trong túi)
local function EquipWeapon()
    local char = game.Players.LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end -- Đang cầm sẵn
    
    local bp = game.Players.LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local newTool = bp:FindFirstChildOfClass("Tool")
        if newTool and char:FindFirstChild("Humanoid") then
            char.Humanoid:EquipTool(newTool)
            return newTool
        end
    end
    return nil
end

AddConn(RunService.Heartbeat:Connect(function(dt)
    -- ── HACK TAY DÀI (REACH) ──────────────────────────
    if S.TayDai then
        local tool = EquipWeapon()
        if tool then
            for _, v in pairs(tool:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("MeshPart") then
                    v.Size = Vector3.new(40, 40, 40) -- Kéo dài tầm đánh 40 studs
                    v.Massless = true
                    v.CanCollide = false
                    if v.Name == "Handle" then
                        v.Transparency = 0.8 -- Làm mờ vũ khí khổng lồ cho đỡ lag mắt
                    end
                end
            end
        end
    end

    if not S.AutoFarm then return end

    local char, hrp, hum = GetChar()
    if not char then return end

    -- ── Tìm quái gần nhất từ cache ─────────────────────
    local target, minD = nil, math.huge
    for _, obj in ipairs(cachedMobs) do
        if obj and obj.Parent then
            local ok, dist = pcall(function()
                return (obj.HumanoidRootPart.Position - hrp.Position).Magnitude
            end)
            if ok and dist < minD and obj.Humanoid.Health > 0 then
                minD = dist
                target = obj
            end
        end
    end
    if not target then return end

    local tHRP = target.HumanoidRootPart

    -- ── Tính vị trí trên quỹ đạo hình VUÔNG ────────────
    farmAngle = farmAngle + dt * FARM_ORBIT
    if farmAngle >= math.pi * 2 then
        farmAngle = farmAngle - math.pi * 2
    end

    local t01     = farmAngle / (math.pi * 2)
    local sideIdx = math.floor(t01 * 4)
    local sideT   = (t01 * 4) - sideIdx

    local s1 = SQUARE[sideIdx + 1]
    local s2 = SQUARE[(sideIdx % 4) + 1 + 1] or SQUARE[1]

    local offset = Vector3.new(
        s1.X + (s2.X - s1.X) * sideT,
        0,
        s1.Z + (s2.Z - s1.Z) * sideT
    ) * FARM_RADIUS

    local flyPos = tHRP.Position + offset + Vector3.new(0, FARM_HEIGHT, 0)

    -- ── Đặt vị trí nhân vật, mặt luôn nhìn vào quái ─────
    hrp.CFrame = CFrame.new(flyPos, tHRP.Position + Vector3.new(0, 2, 0))
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- ── TỰ ĐỘNG ĐÁNH SIÊU CHUẨN ─────────────────────────
    farmTimer = farmTimer - dt
    if farmTimer <= 0 then
        farmTimer = FARM_ATK_CD
        
        -- Gọi vũ khí ra tay nếu chưa cầm
        local tool = EquipWeapon()
        
        pcall(function()
            -- 1. VirtualInputManager: Giả lập click chuột cứng (chắc chắn ăn)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.delay(0.02, function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
            
            -- 2. Kích hoạt trực tiếp Tool (Dự phòng)
            if tool then
                tool:Activate()
            end
        end)
    end
end))

AddToggle(P1, "🤖 Auto Farm (Bay Vuông + Tự Đánh)", function(v)
    S.AutoFarm = v
    farmAngle  = 0
    farmTimer  = 0
    local _,_,hum = GetChar()
    if hum then hum.AutoRotate = true end
end)

AddToggle(P1, "⚔️ Hack Tay Dài (Mở rộng tầm đánh)", function(v)
    S.TayDai = v
end)

-- Slider điều chỉnh bán kính vòng bay
AddSlider(P1, "Bán Kính Bay Quanh Quái", 3, 15, 6, function(v)
    FARM_RADIUS = v
end)

-- Slider điều chỉnh tốc độ bay vòng
AddSlider(P1, "Tốc Độ Xoay Quanh Quái", 1, 5, 2, function(v)
    FARM_ORBIT = v
end)
-- ══════════════════════════════════════════════════════════
-- 2. AUTO QUEST
-- ══════════════════════════════════════════════════════════
AddLabel(P1, "── AUTO QUEST ──────────────────")

AddThread(function()
    while HubAlive do
        task.wait(1.5)
        if not S.AutoQuest then continue end
        pcall(function()
            local char,hrp = GetChar()
            if not char then return end
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == QuestNPCName and obj:FindFirstChild("HumanoidRootPart") then
                    hrp.CFrame = obj.HumanoidRootPart.CFrame + Vector3.new(0,3,4)
                    local cd = obj:FindFirstChildWhichIsA("ClickDetector", true)
                    if cd then pcall(fireclickdetector, cd) end
                end
            end
        end)
    end
end)
AddToggle(P1, "📜 Auto Nhận Nhiệm Vụ (Auto Quest)", function(v) S.AutoQuest=v end)

-- ══════════════════════════════════════════════════════════
-- 3. AIMBOT - Nhắm cả Player lẫn Mob
-- ══════════════════════════════════════════════════════════
AddLabel(P1, "── AIMBOT ────────────────────")

AddConn(RunService.RenderStepped:Connect(function()
    if not S.Aimbot then return end
    local char,hrp = GetChar()
    if not char then return end

    local closest, minD = nil, math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChild("HumanoidRootPart")
            local hm = p.Character:FindFirstChild("Humanoid")
            if h and hm and hm.Health > 0 then
                local d = (h.Position - hrp.Position).Magnitude
                if d < minD then minD=d closest=h end
            end
        end
    end

    for _, obj in ipairs(cachedMobs) do
        if obj.Parent then
            local d = (obj.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < minD then minD=d closest=obj.HumanoidRootPart end
        end
    end

    if closest then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position)
    end
end))
AddToggle(P1, "🎯 Aimbot Tự Động Ngắm (Player + Mob)", function(v) S.Aimbot=v end)

-- ══════════════════════════════════════════════════════════
-- 4. NOCLIP - Cache đúng từ đầu
-- ══════════════════════════════════════════════════════════
AddLabel(P1, "── NOCLIP ────────────────────")

local noclipParts = {}

local function BuildNoclipCache(char)
    table.clear(noclipParts)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(noclipParts, p) end
    end
end

-- Chạy ngay với character hiện tại
if LocalPlayer.Character then BuildNoclipCache(LocalPlayer.Character) end
AddConn(LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait()
    BuildNoclipCache(c)
end))

AddConn(RunService.Stepped:Connect(function()
    if not S.Noclip then return end
    for _, p in ipairs(noclipParts) do
        if p and p.Parent then p.CanCollide=false end
    end
end))
AddToggle(P1, "👻 NoClip (Đi Xuyên Tường)", function(v) S.Noclip=v end)

-- ══════════════════════════════════════════════════════════
-- PAGE 2: ESP
-- ══════════════════════════════════════════════════════════
local function CreateESP(target, label, color)
    if not target or not target.Parent then return end
    if target:FindFirstChild("PESP_UI") then return end

    local hum = target:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- BillboardGui
    local bb = Instance.new("BillboardGui", target)
    bb.Name        = "PESP_UI"
    bb.Adornee     = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
    bb.Size        = UDim2.new(0,150,0,54)
    bb.StudsOffset = Vector3.new(0,3,0)
    bb.AlwaysOnTop = true

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Name               = "NL"
    nameLbl.Size               = UDim2.new(1,0,0,24)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3         = color
    nameLbl.TextSize           = 13
    nameLbl.Font               = Enum.Font.SourceSansBold
    nameLbl.TextStrokeTransparency = 0.3
    nameLbl.Text               = label

    local barBg = Instance.new("Frame", bb)
    barBg.Name             = "BBG"
    barBg.Size             = UDim2.new(0,100,0,7)
    barBg.Position         = UDim2.new(0.5,-50,0,26)
    barBg.BackgroundColor3 = Color3.fromRGB(30,30,30)
    barBg.BorderSizePixel  = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

    local barFill = Instance.new("Frame", barBg)
    barFill.Name             = "BF"
    barFill.BackgroundColor3 = Color3.fromRGB(50,220,80)
    barFill.BorderSizePixel  = 0
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1,0)

    -- Highlight
    local hl = Instance.new("Highlight", target)
    hl.Name         = "PESP_HL"
    hl.Adornee      = target
    hl.FillColor    = color
    hl.FillTransparency = 0.6
    hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.OutlineTransparency = 0
end

local function UpdateESP(target, label, color)
    CreateESP(target, label, color)
    local bb  = target:FindFirstChild("PESP_UI")
    local hum = target:FindFirstChildOfClass("Humanoid")
    if not bb or not hum then return end

    local nl = bb:FindFirstChild("NL")
    local bf = bb:FindFirstChild("BBG") and bb.BBG:FindFirstChild("BF")
    if nl then nl.Text = string.format("%s [%d/%d]", label, math.floor(hum.Health), math.floor(hum.MaxHealth)) end
    if bf and hum.MaxHealth > 0 then
        bf.Size = UDim2.new(math.clamp(hum.Health/hum.MaxHealth,0,1),0,1,0)
    end
end

local function RemoveESP(target)
    if not target then return end
    local u = target:FindFirstChild("PESP_UI")
    local h = target:FindFirstChild("PESP_HL")
    if u then u:Destroy() end
    if h then h:Destroy() end
end

-- 5. ESP NGƯỜI CHƠI (riêng biệt)
AddLabel(P2, "── ESP NGƯỜI CHƠI ──────────────")
AddThread(function()
    while HubAlive do
        task.wait(0.6)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if S.EspPlayer then
                    UpdateESP(p.Character, "👤 "..p.Name, Color3.fromRGB(0,180,255))
                else
                    RemoveESP(p.Character)
                end
            end
        end
    end
end)
AddToggle(P2, "👥 ESP Người Chơi (Tên + Máu + Highlight)", function(v) S.EspPlayer=v end)

-- 6. ESP QUÁI VẬT (riêng biệt)
AddLabel(P2, "── ESP QUÁI VẬT ─────────────────")
AddThread(function()
    while HubAlive do
        task.wait(0.8)
        for _, obj in ipairs(cachedMobs) do
            if obj and obj.Parent then
                if S.EspMob then
                    UpdateESP(obj, "👾 "..obj.Name, Color3.fromRGB(255,60,60))
                else
                    RemoveESP(obj)
                end
            end
        end
    end
end)
AddToggle(P2, "👾 ESP Quái Vật (Tên + Máu + Highlight)", function(v) S.EspMob=v end)

-- 7. FULLBRIGHT
AddLabel(P2, "── TẦM NHÌN ─────────────────────")
local origBright, origClock, origFog, origShadow
    = Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows

AddToggle(P2, "🔦 Nhìn Trong Đêm (Fullbright)", function(v)
    if v then
        Lighting.Brightness    = 3
        Lighting.ClockTime     = 14
        Lighting.FogEnd        = 999999
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness    = origBright
        Lighting.ClockTime     = origClock
        Lighting.FogEnd        = origFog
        Lighting.GlobalShadows = origShadow
    end
end)

-- ══════════════════════════════════════════════════════════
-- PAGE 3: TỐC ĐỘ & ĐỒ HỌA
-- ══════════════════════════════════════════════════════════

-- 8. TỐC ĐỘ
AddLabel(P3, "── TỐC ĐỘ ────────────────────")
AddConn(RunService.Heartbeat:Connect(function()
    if not S.Speed then return end
    local _,_,hum = GetChar()
    if hum then hum.WalkSpeed = speedVal end
end))
AddToggle(P3, "⚡ Chạy Nhanh", function(v)
    S.Speed = v
    local _,_,hum = GetChar()
    if hum then hum.WalkSpeed = v and speedVal or 16 end
end)
AddSlider(P3, "WalkSpeed", 50, 250, 50, function(v)
    speedVal = v
    if S.Speed then
        local _,_,hum = GetChar()
        if hum then hum.WalkSpeed=v end
    end
end)

-- 9. NHẢY CAO
AddLabel(P3, "── NHẢY ──────────────────────")
AddConn(RunService.Heartbeat:Connect(function()
    if not S.Jump then return end
    local _,_,hum = GetChar()
    if hum then hum.UseJumpPower=true hum.JumpPower=jumpVal end
end))
AddToggle(P3, "🦘 Nhảy Cao", function(v)
    S.Jump = v
    local _,_,hum = GetChar()
    if hum then hum.UseJumpPower=true hum.JumpPower = v and jumpVal or 50 end
end)
AddSlider(P3, "JumpPower", 50, 400, 50, function(v)
    jumpVal = v
    if S.Jump then
        local _,_,hum = GetChar()
        if hum then hum.JumpPower=v end
    end
end)

-- 10. FIX LAG CỰC MẠNH
AddLabel(P3, "── FIX LAG ───────────────────")

local function DestroyEffect(obj)
    if  obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
    or  obj:IsA("Fire") or obj:IsA("Sparkles")
    or  obj:IsA("Trail") or obj:IsA("Beam")
    or  obj:IsA("SelectionBox") or obj:IsA("BoxHandleAdornment")
    or  obj:IsA("BillboardGui") and obj.Name ~= "PESP_UI"
    then
        pcall(function() obj.Enabled = false end)
        pcall(function() obj:Destroy() end)
    end
end

local function ApplyBoost(v, isOn)
    if not v or not v.Parent then return end
    if v:IsA("BasePart") then
        if isOn then
            v.Material    = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow  = false
        end
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v.Transparency = isOn and 1 or 0
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail")
        or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles")
        or v:IsA("Beam")
    then
        v.Enabled = not isOn
    end
end

AddToggle(P3, "🔥 Fix Lag Cực Mạnh (Tối Ưu Đồ Họa Tối Đa)", function(val)
    S.Boost = val

    -- Lighting
    Lighting.GlobalShadows  = false
    Lighting.FogEnd         = val and 9e9    or 100000
    Lighting.Brightness     = val and 2      or 1
    Lighting.ShadowSoftness = 0
    Lighting.OutdoorAmbient = val
        and Color3.fromRGB(230,230,230)
        or  Color3.fromRGB(128,128,128)

    -- Tắt tất cả PostEffects, Atmosphere, Sky, Fog
    for _, obj in ipairs(Lighting:GetDescendants()) do
        if  obj:IsA("PostEffect") or obj:IsA("Atmosphere")
        or  obj:IsA("Sky") or obj:IsA("BlurEffect")
        or  obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect")
        or  obj:IsA("DepthOfFieldEffect") or obj:IsA("BloomEffect")
        then
            pcall(function() obj.Enabled = not val end)
        end
    end

    -- Terrain nước
    pcall(function()
        local t = workspace:FindFirstChildOfClass("Terrain")
        if t and val then
            t.WaterWaveSize    = 0
            t.WaterWaveSpeed   = 0
            t.WaterTransparency= 1
            t.WaterReflectance = 0
        end
    end)

    -- Workspace quality settings
    pcall(function()
        if val then
            workspace.StreamingEnabled = false
        end
    end)

    -- Quét toàn bộ workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        ApplyBoost(obj, val)
    end

    -- Lắng nghe thêm object mới
    if val then
        if not connectionBoost then
            connectionBoost = workspace.DescendantAdded:Connect(function(obj)
                if S.Boost then
                    task.defer(function() ApplyBoost(obj, true) end)
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

-- ══════════════════════════════════════════════════════════
-- PAGE 4: TELEPORT
-- ══════════════════════════════════════════════════════════
AddLabel(P4, "── DỊCH CHUYỂN ĐẢO ─────────────")
for name, pos in pairs(IslandList) do
    AddButton(P4, "🚀 "..name, function()
        local _,hrp = GetChar()
        if hrp then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
        end
    end)
end
