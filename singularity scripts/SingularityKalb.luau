repeat task.wait() until game:IsLoaded()

--   SINGULARITY Kick a Lucky Block
--   credits: @fcoauss motherfuckers

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local VirtualUser      = game:GetService("VirtualUser")

local lp         = Players.LocalPlayer
local mouse      = lp:GetMouse()
local PlayerGui  = lp:WaitForChild("PlayerGui")

--   STATE
local State = {
	autoFarm      = false,
	autoKick      = false,
	autoPickup    = false,
	autoSteal     = false,
	autoRebirth   = false,
	autoUpgrade   = false,
	espEnabled    = false,
	noClip        = false,
	flyEnabled    = false,
	speedEnabled  = false,
	speedValue    = 32,
	hitboxEnabled = false,
	hitboxSize    = 1,
	antiAFK       = false,
	infiniteJump  = false,
	blockEsp      = {},
	brainrotEsp   = {},
	playerEsp     = {},
}

--   HELPERS
local function getHRP()
	local c = lp.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
	local c = lp.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getNearestBlock()
	local hrp = getHRP(); if not hrp then return nil end
	local best, bd = nil, math.huge
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and (v.Name:lower():find("lucky") or v.Name:lower():find("block")) then
			local d = (hrp.Position - v.Position).Magnitude
			if d < bd then bd = d; best = v end
		end
	end
	return best
end

local function playClick()
	pcall(function()
		local s = Instance.new("Sound", game:GetService("SoundService"))
		s.SoundId = "rbxassetid://6895079813"
		s.Volume = 0.3; s.PlaybackSpeed = 1.1; s:Play()
		game:GetService("Debris"):AddItem(s, 1)
	end)
end

--   FEATURE LOOPS
RunService.Heartbeat:Connect(function()
	-- Auto Farm
	if State.autoFarm then
		pcall(function()
			local block = getNearestBlock()
			if block then
				local hum = getHum()
				if hum then hum:MoveTo(block.Position + Vector3.new(0, 3, 0)) end
			end
		end)
	end

	-- Auto Pickup
	if State.autoPickup then
		pcall(function()
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("Model") and (v.Name:lower():find("brainrot") or v.Name:lower():find("cash")) then
					local tp = v:FindFirstChild("TouchInterest") or v.PrimaryPart
					local hrp = getHRP()
					if tp and hrp then
						firetouchinterest(hrp, tp, 0)
						firetouchinterest(hrp, tp, 1)
					end
				end
			end
		end)
	end

	-- Auto Steal
	if State.autoSteal then
		pcall(function()
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") and v.Name:lower():find("lucky")
					and v.Parent and v.Parent:FindFirstChild("Owner")
					and v.Parent.Owner.Value ~= lp.Name then
					local hum = getHum()
					if hum then
						hum:MoveTo(v.Position + Vector3.new(0, 3, 0))
						local kr = ReplicatedStorage:FindFirstChild("KickRemote")
						if kr then kr:FireServer(v) end
					end
				end
			end
		end)
	end

	-- NoClip
	if State.noClip then
		pcall(function()
			local c = lp.Character; if not c then return end
			for _, v in ipairs(c:GetDescendants()) do
				if v:IsA("BasePart") then v.CanCollide = false end
			end
		end)
	end
end)

-- Fly
local lctrl, lshift = false, false
local flySpeed = 50

UIS.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.KeyCode == Enum.KeyCode.LeftControl then lctrl = true end
	if inp.KeyCode == Enum.KeyCode.LeftShift   then lshift = true end
end)
UIS.InputEnded:Connect(function(inp)
	if inp.KeyCode == Enum.KeyCode.LeftControl then lctrl = false end
	if inp.KeyCode == Enum.KeyCode.LeftShift   then lshift = false end
end)

RunService.RenderStepped:Connect(function()
	local hrp = getHRP(); local hum = getHum()
	if not hrp or not hum then return end
	if State.flyEnabled then
		local vec = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then vec += hrp.CFrame.LookVector  end
		if UIS:IsKeyDown(Enum.KeyCode.S) then vec -= hrp.CFrame.LookVector  end
		if UIS:IsKeyDown(Enum.KeyCode.D) then vec += hrp.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then vec -= hrp.CFrame.RightVector end
		if lctrl  then vec += Vector3.new(0,-1,0) end
		if lshift or UIS:IsKeyDown(Enum.KeyCode.Space) then vec += Vector3.new(0,1,0) end
		hrp.Velocity = vec * flySpeed
		hum.PlatformStand = true
	else
		hum.PlatformStand = false
	end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
	if State.infiniteJump then
		local hum = getHum()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- Anti-AFK
task.spawn(function()
	while true do
		task.wait(60)
		if State.antiAFK then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton1(Vector2.new(mouse.X, mouse.Y))
			end)
		end
	end
end)

-- Auto Kick meter
task.spawn(function()
	while true do
		task.wait(0.05)
		if State.autoKick then
			pcall(function()
				local km = PlayerGui:FindFirstChild("KickMeter")
				if km and km.Visible then
					VirtualUser:CaptureController()
					VirtualUser:ClickButton1(Vector2.new(mouse.X, mouse.Y))
				end
			end)
		end
	end
end)

-- ESP
local function createESP(part, color)
	local h = Instance.new("Highlight")
	h.Adornee = part
	h.FillColor = color
	h.OutlineColor = Color3.new(1,1,1)
	h.FillTransparency = 0.4
	h.Parent = part
	return h
end

task.spawn(function()
	while true do
		task.wait(0.4)
		if State.espEnabled then
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("Model") and v.Name:lower():find("brainrot") and not State.brainrotEsp[v] and v.PrimaryPart then
					State.brainrotEsp[v] = createESP(v.PrimaryPart, Color3.fromRGB(200,200,200))
				elseif v:IsA("BasePart") and v.Name:lower():find("lucky") and not State.blockEsp[v] then
					State.blockEsp[v] = createESP(v, Color3.fromRGB(255,255,255))
				end
			end
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and not State.playerEsp[p] then
					State.playerEsp[p] = createESP(p.Character.HumanoidRootPart, Color3.fromRGB(150,150,150))
				end
			end
		else
			for _,v in pairs(State.brainrotEsp) do pcall(function() v:Destroy() end) end
			for _,v in pairs(State.blockEsp)    do pcall(function() v:Destroy() end) end
			for _,v in pairs(State.playerEsp)   do pcall(function() v:Destroy() end) end
			table.clear(State.brainrotEsp)
			table.clear(State.blockEsp)
			table.clear(State.playerEsp)
		end
	end
end)

--   PALETTE
local isMob = UIS.TouchEnabled and not UIS.KeyboardEnabled
local GS    = isMob and 0.42 or 1

local C = {
	bg        = Color3.fromRGB(8,   8,   8),
	surface   = Color3.fromRGB(14,  14,  14),
	card      = Color3.fromRGB(20,  20,  20),
	border    = Color3.fromRGB(45,  45,  45),
	borderDim = Color3.fromRGB(28,  28,  28),
	white     = Color3.fromRGB(255, 255, 255),
	offWhite  = Color3.fromRGB(210, 210, 210),
	dimWhite  = Color3.fromRGB(140, 140, 140),
	muted     = Color3.fromRGB(65,  65,  65),
	danger    = Color3.fromRGB(255, 80,  80),
	success   = Color3.fromRGB(100, 220, 130),
	accentDim = Color3.fromRGB(90,  90,  90),
}

--   SCREEN GUI
local sg = Instance.new("ScreenGui")
sg.Name = "SingularityHub"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = PlayerGui

--   MAIN WINDOW
local main = Instance.new("Frame", sg)
main.Name = "Main"
main.Size = UDim2.new(0, 540*GS, 0, 560*GS)
main.Position = isMob and UDim2.new(0.5,-270*GS,0.5,-280*GS) or UDim2.new(0,22,0.5,-280)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.ZIndex = 5
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16*GS)
Instance.new("UIStroke", main).Color = C.border

-- Top gradient strip
local topStrip = Instance.new("Frame", main)
topStrip.Size = UDim2.new(1,0,0,3)
topStrip.BackgroundColor3 = C.white
topStrip.BorderSizePixel = 0
topStrip.ZIndex = 6
local stripGrad = Instance.new("UIGradient", topStrip)
stripGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60,60,60)),
	ColorSequenceKeypoint.new(0.5, C.white),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(60,60,60)),
})

-- ── HEADER ──────────────────────────────────────────────────────
local hdr = Instance.new("Frame", main)
hdr.Size = UDim2.new(1,0,0,58*GS)
hdr.BackgroundTransparency = 1
hdr.ZIndex = 7

-- Dot logo
local dot = Instance.new("Frame", hdr)
dot.Size = UDim2.new(0,8*GS,0,8*GS)
dot.Position = UDim2.new(0,16*GS,0.5,-4*GS)
dot.BackgroundColor3 = C.white
dot.BorderSizePixel = 0
dot.ZIndex = 8
Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

local title = Instance.new("TextLabel", hdr)
title.Size = UDim2.new(1,-80*GS,0,26*GS)
title.Position = UDim2.new(0,30*GS,0,10*GS)
title.BackgroundTransparency = 1
title.Text = "SINGULARITY  ·  KALB"
title.TextColor3 = C.white
title.Font = Enum.Font.GothamBlack
title.TextSize = 18*GS
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 8

local subtitle = Instance.new("TextLabel", hdr)
subtitle.Size = UDim2.new(1,-80*GS,0,12*GS)
subtitle.Position = UDim2.new(0,30*GS,0,38*GS)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Press [Insert] to hide  ·  Drag to move"
subtitle.TextColor3 = C.muted
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 9*GS
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 8

-- Close
local xBtn = Instance.new("TextButton", hdr)
xBtn.Size = UDim2.new(0,28*GS,0,28*GS)
xBtn.Position = UDim2.new(1,-38*GS,0.5,-14*GS)
xBtn.BackgroundColor3 = C.card
xBtn.Text = "✕"
xBtn.TextColor3 = C.dimWhite
xBtn.Font = Enum.Font.GothamBold
xBtn.TextSize = 14*GS
xBtn.BorderSizePixel = 0
xBtn.ZIndex = 9
Instance.new("UICorner", xBtn).CornerRadius = UDim.new(0,8*GS)
xBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
xBtn.MouseEnter:Connect(function() TweenService:Create(xBtn,TweenInfo.new(0.15),{BackgroundColor3=C.danger,TextColor3=C.white}):Play() end)
xBtn.MouseLeave:Connect(function() TweenService:Create(xBtn,TweenInfo.new(0.15),{BackgroundColor3=C.card,TextColor3=C.dimWhite}):Play() end)

-- Divider
local div = Instance.new("Frame", main)
div.Size = UDim2.new(0.96,0,0,1)
div.Position = UDim2.new(0.02,0,0,59*GS)
div.BackgroundColor3 = C.border
div.BorderSizePixel = 0
div.ZIndex = 7

-- ── TAB BAR ─────────────────────────────────────────────────────
local tabCont = Instance.new("Frame", main)
tabCont.Size = UDim2.new(0.96,0,0,34*GS)
tabCont.Position = UDim2.new(0.02,0,0,64*GS)
tabCont.BackgroundColor3 = C.surface
tabCont.BorderSizePixel = 0
tabCont.ZIndex = 7
Instance.new("UICorner", tabCont).CornerRadius = UDim.new(0,10*GS)
Instance.new("UIStroke", tabCont).Color = C.borderDim

local tabNames = {"FARM","COMBAT","MOVEMENT","ESP","SETTINGS"}
local tabBtns  = {}
local tabPanels = {}
local currentTab = 1

-- Sliding pill
local pill = Instance.new("Frame", tabCont)
pill.Size = UDim2.new(1/#tabNames,-4,1,-6)
pill.Position = UDim2.new(0,3,0,3)
pill.BackgroundColor3 = C.white
pill.BorderSizePixel = 0
pill.ZIndex = 8
Instance.new("UICorner", pill).CornerRadius = UDim.new(0,7*GS)

local function switchTab(idx)
	currentTab = idx
	local sw = 1/#tabNames
	TweenService:Create(pill,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{
		Position = UDim2.new(sw*(idx-1),3,0,3)
	}):Play()
	for i,b in ipairs(tabBtns) do
		TweenService:Create(b,TweenInfo.new(0.15),{
			TextColor3 = (i==idx) and C.bg or C.muted
		}):Play()
	end
	for i,p in ipairs(tabPanels) do p.Visible=(i==idx) end
end

local sw = 1/#tabNames
for i,name in ipairs(tabNames) do
	local b = Instance.new("TextButton", tabCont)
	b.Size = UDim2.new(sw,0,1,0)
	b.Position = UDim2.new(sw*(i-1),0,0,0)
	b.BackgroundTransparency = 1
	b.Text = name
	b.TextColor3 = (i==1) and C.bg or C.muted
	b.Font = Enum.Font.GothamBold
	b.TextSize = 9*GS
	b.ZIndex = 9
	b.MouseButton1Click:Connect(function() switchTab(i); playClick() end)
	tabBtns[i] = b

	local panel = Instance.new("ScrollingFrame", main)
	panel.Size = UDim2.new(0.96,0,0,422*GS)
	panel.Position = UDim2.new(0.02,0,0,103*GS)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.ScrollBarThickness = 3
	panel.ScrollBarImageColor3 = C.accentDim
	panel.CanvasSize = UDim2.new(0,0,0,0)
	panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	panel.Visible = (i==1)
	panel.ZIndex = 7
	local layout = Instance.new("UIListLayout", panel)
	layout.Padding = UDim.new(0,5*GS)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	local pad = Instance.new("UIPadding", panel)
	pad.PaddingLeft = UDim.new(0,4*GS); pad.PaddingRight = UDim.new(0,4*GS)
	pad.PaddingTop = UDim.new(0,4*GS);  pad.PaddingBottom = UDim.new(0,8*GS)
	tabPanels[i] = panel
end

--   COMPONENT BUILDERS

local function mkSection(parent, text)
	local f = Instance.new("Frame", parent)
	f.Size = UDim2.new(1,0,0,20*GS)
	f.BackgroundTransparency = 1
	f.ZIndex = 10
	local tick = Instance.new("Frame", f)
	tick.Size = UDim2.new(0,3,0,10*GS)
	tick.Position = UDim2.new(0,0,0.5,-5*GS)
	tick.BackgroundColor3 = C.white
	tick.BorderSizePixel = 0
	tick.ZIndex = 11
	Instance.new("UICorner", tick).CornerRadius = UDim.new(1,0)
	local l = Instance.new("TextLabel", f)
	l.Size = UDim2.new(1,-10*GS,1,0)
	l.Position = UDim2.new(0,10*GS,0,0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = C.dimWhite
	l.Font = Enum.Font.GothamBold
	l.TextSize = 9*GS
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 11
	return f
end

local VSetters = {}

local function mkToggle(parent, label, stateKey, cb)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,0,0,46*GS)
	row.BackgroundColor3 = C.card
	row.BorderSizePixel = 0
	row.ZIndex = 10
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,10*GS)
	Instance.new("UIStroke", row).Color = C.borderDim

	local bar = Instance.new("Frame", row)
	bar.Size = UDim2.new(0,3,0.6,0)
	bar.Position = UDim2.new(0,0,0.2,0)
	bar.BackgroundColor3 = C.muted
	bar.BorderSizePixel = 0
	bar.ZIndex = 11
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

	local lbl = Instance.new("TextLabel", row)
	lbl.Size = UDim2.new(0.72,0,1,0)
	lbl.Position = UDim2.new(0,14*GS,0,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = C.offWhite
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = 11*GS
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 11

	local isOn = State[stateKey] or false

	local tBg = Instance.new("Frame", row)
	tBg.Size = UDim2.new(0,44*GS,0,22*GS)
	tBg.Position = UDim2.new(1,-54*GS,0.5,-11*GS)
	tBg.BackgroundColor3 = isOn and C.white or C.card
	tBg.ZIndex = 11
	Instance.new("UICorner", tBg).CornerRadius = UDim.new(1,0)
	Instance.new("UIStroke", tBg).Color = C.accentDim

	local knob = Instance.new("Frame", tBg)
	knob.Size = UDim2.new(0,16*GS,0,16*GS)
	knob.Position = isOn and UDim2.new(1,-19*GS,0.5,-8*GS) or UDim2.new(0,3*GS,0.5,-8*GS)
	knob.BackgroundColor3 = isOn and C.bg or C.accentDim
	knob.ZIndex = 12
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

	local hit = Instance.new("TextButton", row)
	hit.Size = UDim2.new(1,0,1,0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 13

	local function setV(state_)
		isOn = state_
		State[stateKey] = state_
		TweenService:Create(tBg,TweenInfo.new(0.2),{BackgroundColor3=isOn and C.white or C.card}):Play()
		TweenService:Create(knob,TweenInfo.new(0.2,Enum.EasingStyle.Back),{
			BackgroundColor3 = isOn and C.bg or C.accentDim,
			Position = isOn and UDim2.new(1,-19*GS,0.5,-8*GS) or UDim2.new(0,3*GS,0.5,-8*GS)
		}):Play()
		TweenService:Create(bar,TweenInfo.new(0.18),{BackgroundColor3=isOn and C.white or C.muted}):Play()
		if cb then cb(isOn) end
	end
	VSetters[stateKey] = setV
	hit.MouseButton1Click:Connect(function() setV(not isOn); playClick() end)
	return row
end

local function mkButton(parent, label, accent, cb)
	local col = accent or C.white
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(1,0,0,42*GS)
	btn.BackgroundColor3 = col
	btn.Text = label
	btn.TextColor3 = (col == C.danger) and C.white or C.bg
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12*GS
	btn.BorderSizePixel = 0
	btn.ZIndex = 10
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10*GS)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.offWhite}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=col}):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		playClick()
		if cb then cb(btn) end
	end)
	return btn
end

local SSetters = {}

local function mkSlider(parent, label, vKey, mn, mx, default)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1,0,0,54*GS)
	container.BackgroundColor3 = C.card
	container.BorderSizePixel = 0
	container.ZIndex = 10
	Instance.new("UICorner", container).CornerRadius = UDim.new(0,10*GS)
	Instance.new("UIStroke", container).Color = C.borderDim

	local lbl = Instance.new("TextLabel", container)
	lbl.Size = UDim2.new(0.65,0,0,18*GS)
	lbl.Position = UDim2.new(0,12*GS,0,7*GS)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = C.dimWhite
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 10*GS
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 11

	local def = default or mn
	local vBox = Instance.new("TextBox", container)
	vBox.Size = UDim2.new(0,48*GS,0,22*GS)
	vBox.Position = UDim2.new(1,-56*GS,0,5*GS)
	vBox.BackgroundColor3 = C.surface
	vBox.Text = tostring(def)
	vBox.TextColor3 = C.white
	vBox.Font = Enum.Font.GothamBold
	vBox.TextSize = 11*GS
	vBox.ClearTextOnFocus = false
	vBox.ZIndex = 11
	Instance.new("UICorner", vBox).CornerRadius = UDim.new(0,7*GS)
	Instance.new("UIStroke", vBox).Color = C.border

	local track = Instance.new("Frame", container)
	track.Size = UDim2.new(0.88,0,0,6*GS)
	track.Position = UDim2.new(0.06,0,0,35*GS)
	track.BackgroundColor3 = C.surface
	track.ZIndex = 11
	Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

	local pct = (def-mn)/(mx-mn)
	local fill = Instance.new("Frame", track)
	fill.Size = UDim2.new(pct,0,1,0)
	fill.BackgroundColor3 = C.white
	fill.ZIndex = 12
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

	local thumb = Instance.new("Frame", track)
	thumb.Size = UDim2.new(0,12*GS,0,12*GS)
	thumb.Position = UDim2.new(pct,-6*GS,0.5,-6*GS)
	thumb.BackgroundColor3 = C.white
	thumb.ZIndex = 13
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(1,0)

	local hitBtn = Instance.new("TextButton", track)
	hitBtn.Size = UDim2.new(1,0,5,0)
	hitBtn.Position = UDim2.new(0,0,-2,0)
	hitBtn.BackgroundTransparency = 1
	hitBtn.Text = ""
	hitBtn.ZIndex = 14

	local dragging = false
	local function update(rel)
		rel = math.clamp(rel,0,1)
		fill.Size = UDim2.new(rel,0,1,0)
		thumb.Position = UDim2.new(rel,-6*GS,0.5,-6*GS)
		local v = math.floor(mn+(mx-mn)*rel)
		vBox.Text = tostring(v)
		if vKey then State[vKey] = v end
	end
	SSetters[vKey or label] = function(v)
		local r = (math.clamp(v,mn,mx)-mn)/(mx-mn)
		fill.Size = UDim2.new(r,0,1,0)
		thumb.Position = UDim2.new(r,-6*GS,0.5,-6*GS)
		vBox.Text = tostring(math.floor(v))
		if vKey then State[vKey] = math.floor(v) end
	end

	hitBtn.MouseButton1Down:Connect(function() dragging = true end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
			update((i.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X)
		end
	end)
	vBox.FocusLost:Connect(function()
		local n = tonumber(vBox.Text)
		if n then
			n = math.clamp(math.floor(n),mn,mx)
			vBox.Text = tostring(n)
			if vKey then State[vKey] = n end
			local r = (n-mn)/(mx-mn)
			fill.Size = UDim2.new(r,0,1,0)
			thumb.Position = UDim2.new(r,-6*GS,0.5,-6*GS)
		end
	end)

	return container
end

--   POPULATE TABS

-- ── TAB 1: FARM ─────────────────────────────────────────────────
local t1 = tabPanels[1]
mkSection(t1, "AUTOMATION")
mkToggle(t1,"Auto Farm (Kick + Collect)","autoFarm",function(s)
	State.autoFarm=s; State.autoPickup=s
end)
mkToggle(t1,"Auto Perfect Kick","autoKick",nil)
mkToggle(t1,"Auto Steal Blocks","autoSteal",nil)
mkSection(t1,"PROGRESSION")
mkToggle(t1,"Auto Rebirth","autoRebirth",function(s)
	if s then
		task.spawn(function()
			while State.autoRebirth do
				pcall(function()
					local rb = PlayerGui:FindFirstChild("RebirthButton")
					if rb and rb.Visible then
						local cd = rb:FindFirstChild("ClickDetector")
						if cd then cd:Click() end
					end
				end)
				task.wait(1)
			end
		end)
	end
end)
mkToggle(t1,"Auto Upgrade","autoUpgrade",function(s)
	if s then
		task.spawn(function()
			while State.autoUpgrade do
				pcall(function()
					for _, btn in ipairs(PlayerGui:GetDescendants()) do
						if btn.Name:lower():find("upgrade") and btn:IsA("TextButton") and btn.Visible then
							local cd = btn:FindFirstChild("ClickDetector")
							if cd then cd:Click() end
						end
					end
				end)
				task.wait(0.5)
			end
		end)
	end
end)
mkSection(t1,"ACTIONS")
mkButton(t1,"⚡  Teleport to Nearest Block",C.white,function()
	local block = getNearestBlock()
	if block then
		local hrp = getHRP()
		if hrp then hrp.CFrame = block.CFrame + Vector3.new(0,5,0) end
	end
end)
mkButton(t1,"◈  Fire Kick Remote",C.white,function()
	pcall(function()
		local block = getNearestBlock()
		if block then
			local kr = ReplicatedStorage:FindFirstChild("KickRemote") or ReplicatedStorage:FindFirstChild("KickBlock")
			if kr then kr:FireServer(block) end
		end
	end)
end)

-- ── TAB 2: COMBAT ───────────────────────────────────────────────
local t2 = tabPanels[2]
mkSection(t2, "HITBOX")
mkSlider(t2,"Hitbox Multiplier","hitboxSize",1,15,1)
mkToggle(t2,"Enable Hitbox Expansion","hitboxEnabled",function(s)
	if s then
		pcall(function()
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") and (v.Name:lower():find("lucky") or v.Name:lower():find("block")) then
					v.Size = v.Size * (State.hitboxSize or 1)
				end
			end
		end)
	end
end)

-- ── TAB 3: MOVEMENT ─────────────────────────────────────────────
local t3 = tabPanels[3]
mkSection(t3,"FLY")
mkToggle(t3,"Fly Mode","flyEnabled",function(s)
	State.flyEnabled = s
	local hum = getHum()
	if hum and not s then hum.PlatformStand = false end
end)
mkSlider(t3,"Fly Speed","flySpeed",10,200,50)
mkSection(t3,"SPEED")
mkSlider(t3,"Walk Speed","speedValue",16,250,32)
mkToggle(t3,"Enable Speed Hack","speedEnabled",function(s)
	local hum = getHum()
	if hum then hum.WalkSpeed = s and State.speedValue or 16 end
end)
mkSection(t3,"MISC")
mkToggle(t3,"Infinite Jump","infiniteJump",nil)
mkToggle(t3,"No Clip","noClip",nil)

-- ── TAB 4: ESP ──────────────────────────────────────────────────
local t4 = tabPanels[4]
mkSection(t4,"VISUALS")
mkToggle(t4,"Enable ESP (Blocks, Players, Drops)","espEnabled",nil)
mkSection(t4,"INFO")
local espInfo = Instance.new("Frame", t4)
espInfo.Size = UDim2.new(1,0,0,70*GS)
espInfo.BackgroundColor3 = C.card
espInfo.BorderSizePixel = 0
espInfo.ZIndex = 10
Instance.new("UICorner", espInfo).CornerRadius = UDim.new(0,10*GS)
Instance.new("UIStroke", espInfo).Color = C.borderDim
local espInfoLbl = Instance.new("TextLabel", espInfo)
espInfoLbl.Size = UDim2.new(1,-16*GS,1,0)
espInfoLbl.Position = UDim2.new(0,8*GS,0,0)
espInfoLbl.BackgroundTransparency = 1
espInfoLbl.ZIndex = 11
espInfoLbl.Text = "White  =  Lucky Blocks\nLight grey  =  Brainrots / Drops\nDark grey  =  Other Players"
espInfoLbl.TextColor3 = C.muted
espInfoLbl.Font = Enum.Font.GothamMedium
espInfoLbl.TextSize = 10*GS
espInfoLbl.TextWrapped = true
espInfoLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ── TAB 5: SETTINGS ─────────────────────────────────────────────
local t5 = tabPanels[5]
mkSection(t5,"UTILITY")
mkToggle(t5,"Anti-AFK","antiAFK",nil)
mkSection(t5,"GUI")
mkButton(t5,"◈  Hide GUI  [Insert]",C.white,function()
	main.Visible = not main.Visible
end)
mkButton(t5,"✕  Destroy GUI",C.danger,function()
	sg:Destroy()
end)
mkSection(t5,"INFO")
local infoCard = Instance.new("Frame", t5)
infoCard.Size = UDim2.new(1,0,0,80*GS)
infoCard.BackgroundColor3 = C.card
infoCard.BorderSizePixel = 0
infoCard.ZIndex = 10
Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0,10*GS)
Instance.new("UIStroke", infoCard).Color = C.borderDim
local infoLbl = Instance.new("TextLabel", infoCard)
infoLbl.Size = UDim2.new(1,-16*GS,1,0)
infoLbl.Position = UDim2.new(0,8*GS,0,0)
infoLbl.BackgroundTransparency = 1
infoLbl.ZIndex = 11
infoLbl.Text = "Singularity Hub  ·  Kick a Lucky Block\nDrag title bar to move  ·  [Insert] to hide\nAll features run while GUI is hidden"
infoLbl.TextColor3 = C.muted
infoLbl.Font = Enum.Font.GothamMedium
infoLbl.TextSize = 10*GS
infoLbl.TextWrapped = true
infoLbl.TextXAlignment = Enum.TextXAlignment.Left

--   SPEED HACK HEARTBEAT SYNC
RunService.Heartbeat:Connect(function()
	if State.speedEnabled then
		local hum = getHum()
		if hum then hum.WalkSpeed = State.speedValue end
	end
	-- fly speed sync
	flySpeed = State.flySpeed or flySpeed
end)

--   INSERT KEY TOGGLE
UIS.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.KeyCode == Enum.KeyCode.Insert then
		main.Visible = not main.Visible
	end
end)

--   CHARACTER RESPAWN RESTORE
lp.CharacterAdded:Connect(function()
	task.wait(1)
	if State.speedEnabled then
		local hum = getHum()
		if hum then hum.WalkSpeed = State.speedValue end
	end
end)

print("[Singularity] loaded")
