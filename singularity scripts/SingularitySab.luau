repeat task.wait() until game:IsLoaded()

--   SINGULARITY DUELS
--   credits: @fcaouss

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UIS            = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local SoundService   = game:GetService("SoundService")
local Lighting       = game:GetService("Lighting")
local RS             = game:GetService("ReplicatedStorage")
local HttpService    = game:GetService("HttpService")
local Stats          = game:GetService("Stats")
local lp             = Players.LocalPlayer
local PlayerGui      = lp:WaitForChild("PlayerGui")

if not getgenv then getgenv = function() return _G end end


--   CONFIG
local CFG_FILE = "singularity_duels.json"

local Enabled = {
	Speed        = false,
	Spin         = false,
	Galaxy       = false,
	Aimbot       = false,
	SpamBat      = false,
	AntiRagdoll  = false,
	Steal        = false,
	StealSpeed   = false,
	Unwalk       = false,
	Optimizer    = false,
	SkyBright    = false,
	AutoLeft     = false,
	AutoRight    = false,
	AutoKick     = false,
	ESP          = false,
}

local Val = {
	SpeedAmt     = 30,
	SpinAmt      = 30,
	StealSpd     = 29,
	StealRad     = 20,
	StealDur     = 1.3,
	Gravity      = 196.2,
	GravPct      = 70,
	HopPow       = 35,
	HopCD        = 0.08,
}

local KB = {
	SPEED   = Enum.KeyCode.V,
	SPIN    = Enum.KeyCode.N,
	GALAXY  = Enum.KeyCode.M,
	AIMBOT  = Enum.KeyCode.X,
	NUKE    = Enum.KeyCode.Q,
	LEFT    = Enum.KeyCode.Z,
	RIGHT   = Enum.KeyCode.C,
}

pcall(function()
	if readfile and isfile and isfile(CFG_FILE) then
		local d = HttpService:JSONDecode(readfile(CFG_FILE))
		if d then
			for k,v in pairs(d) do
				if Enabled[k] ~= nil then Enabled[k] = v end
				if Val[k]     ~= nil then Val[k]     = v end
			end
			local kmap = {KEY_SPEED="SPEED",KEY_SPIN="SPIN",KEY_GALAXY="GALAXY",KEY_AIMBOT="AIMBOT",KEY_LEFT="LEFT",KEY_RIGHT="RIGHT"}
			for dk,vk in pairs(kmap) do
				if d[dk] then KB[vk] = Enum.KeyCode[d[dk]] end
			end
		end
	end
end)

local function SaveConfig()
	if not writefile then return false end
	local d = {}
	for k,v in pairs(Enabled) do d[k]=v end
	for k,v in pairs(Val)     do d[k]=v end
	d.KEY_SPEED=KB.SPEED.Name; d.KEY_SPIN=KB.SPIN.Name; d.KEY_GALAXY=KB.GALAXY.Name
	d.KEY_AIMBOT=KB.AIMBOT.Name; d.KEY_LEFT=KB.LEFT.Name; d.KEY_RIGHT=KB.RIGHT.Name
	local ok = pcall(function() writefile(CFG_FILE, HttpService:JSONEncode(d)) end)
	return ok
end

--   SHARED UTILS
local Conns = {}

local SlapList = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap",
	"Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}

local ADMIN_KEY  = "78a772b6-9e1c-4827-ab8b-04a07838f298"
local REM_ID     = "352aad58-c786-4998-886b-3e4fa390721e"
local BALLOON    = RS:FindFirstChild(REM_ID, true)

local POS1  = Vector3.new(-476.48,-6.28,92.73)
local POS2  = Vector3.new(-483.12,-4.95,94.80)
local POSR1 = Vector3.new(-476.16,-6.52,25.62)
local POSR2 = Vector3.new(-483.04,-5.09,23.14)

local function getHRP()
	local c = lp.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
	local c = lp.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getMD()
	local h = getHum()
	return h and h.MoveDirection or Vector3.zero
end

local function findBat()
	local c = lp.Character
	if not c then return nil end
	local bp = lp:FindFirstChildOfClass("Backpack")
	for _,ch in ipairs(c:GetChildren()) do
		if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
	end
	if bp then
		for _,ch in ipairs(bp:GetChildren()) do
			if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
		end
	end
	for _,n in ipairs(SlapList) do
		local t = c:FindFirstChild(n) or (bp and bp:FindFirstChild(n))
		if t then return t end
	end
end

local function nearestPlayer()
	local h = getHRP()
	if not h then return nil end
	local best,bd = nil,math.huge
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=lp and p.Character then
			local ph = p.Character:FindFirstChild("HumanoidRootPart")
			if ph then
				local d=(h.Position-ph.Position).Magnitude
				if d<bd then bd=d; best=p end
			end
		end
	end
	return best
end

local function nearestEnemy(myHRP)
	local best,bd,bestT = nil,math.huge,nil
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=lp and p.Character then
			local eh = p.Character:FindFirstChild("HumanoidRootPart")
			local tor = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if eh and hum and hum.Health>0 then
				local d=(eh.Position-myHRP.Position).Magnitude
				if d<bd then bd=d; best=eh; bestT=tor or eh end
			end
		end
	end
	return best,bd,bestT
end

local function playClick()
	pcall(function()
		local s=Instance.new("Sound",SoundService)
		s.SoundId="rbxassetid://6895079813"
		s.Volume=0.35; s.PlaybackSpeed=1.1
		s:Play()
		game:GetService("Debris"):AddItem(s,1)
	end)
end

--   FEATURES

local function startSpeed()
	if Conns.speed then return end
	Conns.speed = RunService.Heartbeat:Connect(function()
		if not Enabled.Speed then return end
		pcall(function()
			local h=getHRP(); if not h then return end
			local md=getMD()
			if md.Magnitude>0.1 then
				h.AssemblyLinearVelocity=Vector3.new(md.X*Val.SpeedAmt,h.AssemblyLinearVelocity.Y,md.Z*Val.SpeedAmt)
			end
		end)
	end)
end
local function stopSpeed()
	if Conns.speed then Conns.speed:Disconnect(); Conns.speed=nil end
end

local spinBAV=nil
local function startSpin()
	local c=lp.Character; if not c then return end
	local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	if spinBAV then spinBAV:Destroy(); spinBAV=nil end
	for _,v in pairs(hrp:GetChildren()) do if v.Name=="SDX_SpinBAV" then v:Destroy() end end
	spinBAV=Instance.new("BodyAngularVelocity")
	spinBAV.Name="SDX_SpinBAV"
	spinBAV.MaxTorque=Vector3.new(0,math.huge,0)
	spinBAV.AngularVelocity=Vector3.new(0,Val.SpinAmt,0)
	spinBAV.Parent=hrp
end
local function stopSpin()
	if spinBAV then spinBAV:Destroy(); spinBAV=nil end
	local c=lp.Character
	if c then
		local hrp=c:FindFirstChild("HumanoidRootPart")
		if hrp then for _,v in pairs(hrp:GetChildren()) do if v.Name=="SDX_SpinBAV" then v:Destroy() end end end
	end
end

RunService.Heartbeat:Connect(function()
	if Enabled.Spin and spinBAV then
		spinBAV.AngularVelocity = lp:GetAttribute("Stealing")
			and Vector3.new(0,0,0)
			or  Vector3.new(0,Val.SpinAmt,0)
	end
end)

local gVF,gAtt,gEnabled,hopsOn=nil,nil,false,false
local lastHop,spaceDown,origJump=0,false,50

local function captureJumpPower()
	local h=getHum()
	if h and h.JumpPower>0 then origJump=h.JumpPower end
end
task.spawn(function() task.wait(1); captureJumpPower() end)
lp.CharacterAdded:Connect(function() task.wait(1); captureJumpPower() end)

local function setupGVF()
	pcall(function()
		local h=getHRP(); if not h then return end
		if gVF then gVF:Destroy() end; if gAtt then gAtt:Destroy() end
		gAtt=Instance.new("Attachment"); gAtt.Parent=h
		gVF=Instance.new("VectorForce")
		gVF.Attachment0=gAtt; gVF.ApplyAtCenterOfMass=true
		gVF.RelativeTo=Enum.ActuatorRelativeTo.World
		gVF.Force=Vector3.new(0,0,0); gVF.Parent=h
	end)
end
local function updateGVF()
	if not gEnabled or not gVF then return end
	local c=lp.Character; if not c then return end
	local mass=0
	for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass+=p:GetMass() end end
	local tg=Val.Gravity*(Val.GravPct/100)
	gVF.Force=Vector3.new(0,mass*(Val.Gravity-tg)*0.95,0)
end
local function adjustJump()
	pcall(function()
		local hum=getHum(); if not hum then return end
		if not gEnabled then hum.JumpPower=origJump; return end
		local ratio=math.sqrt((Val.Gravity*(Val.GravPct/100))/Val.Gravity)
		hum.JumpPower=origJump*ratio
	end)
end
local function startGalaxy() gEnabled=true; hopsOn=true; setupGVF(); adjustJump() end
local function stopGalaxy()
	gEnabled=false; hopsOn=false
	if gVF then gVF:Destroy(); gVF=nil end
	if gAtt then gAtt:Destroy(); gAtt=nil end
	adjustJump()
end
local function doHop()
	if not hopsOn then return end
	pcall(function()
		local h=getHRP(); local hum=getHum(); if not h or not hum then return end
		if tick()-lastHop<Val.HopCD then return end; lastHop=tick()
		if hum.FloorMaterial==Enum.Material.Air then
			h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,Val.HopPow,h.AssemblyLinearVelocity.Z)
		end
	end)
end
RunService.Heartbeat:Connect(function()
	if hopsOn and spaceDown then doHop() end
	if gEnabled then updateGVF() end
end)

local function startAimbot()
	if Conns.aimbot then return end
	Conns.aimbot=RunService.Heartbeat:Connect(function()
		if not Enabled.Aimbot then return end
		local h=getHRP(); local hum=getHum(); if not h or not hum then return end
		local bat=findBat()
		if bat and bat.Parent~=lp.Character then hum:EquipTool(bat) end
		local _,_,tor=nearestEnemy(h)
		if tor then
			local dir=tor.Position-h.Position
			local fd=Vector3.new(dir.X,0,dir.Z)
			if fd.Magnitude>1.5 then
				h.AssemblyLinearVelocity=Vector3.new(fd.Unit.X*55,h.AssemblyLinearVelocity.Y,fd.Unit.Z*55)
			else
				h.AssemblyLinearVelocity=Vector3.new(tor.AssemblyLinearVelocity.X,h.AssemblyLinearVelocity.Y,tor.AssemblyLinearVelocity.Z)
			end
		end
	end)
end
local function stopAimbot()
	if Conns.aimbot then Conns.aimbot:Disconnect(); Conns.aimbot=nil end
end

local lastSwing,SWING_CD=0,0.12
local function startSpam()
	if Conns.spam then return end
	Conns.spam=RunService.Heartbeat:Connect(function()
		if not Enabled.SpamBat then return end
		local c=lp.Character; if not c then return end
		local bat=findBat(); if not bat then return end
		if bat.Parent~=c then bat.Parent=c end
		if tick()-lastSwing<SWING_CD then return end
		lastSwing=tick(); pcall(function() bat:Activate() end)
	end)
end
local function stopSpam()
	if Conns.spam then Conns.spam:Disconnect(); Conns.spam=nil end
end

local function startAntiRag()
	if Conns.antirag then return end
	Conns.antirag=RunService.Heartbeat:Connect(function()
		if not Enabled.AntiRagdoll then return end
		local c=lp.Character; if not c then return end
		local hrp=c:FindFirstChild("HumanoidRootPart")
		local hum=c:FindFirstChildOfClass("Humanoid")
		if hum then
			local st=hum:GetState()
			if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
				hum:ChangeState(Enum.HumanoidStateType.Running)
				workspace.CurrentCamera.CameraSubject=hum
				pcall(function()
					local pm=lp.PlayerScripts:FindFirstChild("PlayerModule")
					if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
				end)
				if hrp then hrp.Velocity=Vector3.zero; hrp.RotVelocity=Vector3.zero end
			end
		end
		for _,o in ipairs(c:GetDescendants()) do
			if o:IsA("Motor6D") and not o.Enabled then o.Enabled=true end
		end
	end)
end
local function stopAntiRag()
	if Conns.antirag then Conns.antirag:Disconnect(); Conns.antirag=nil end
end

local stealing,stealStart=false,0
local stealProg,stealConn=nil,nil
local StealCache={}
local DISC_TEXT="discord.gg/singularityhere"
local VSetters,SSetters,KBtns={},{},{}
local waitKB=nil

local function discReveal(pct)
	local adj=math.min(pct*1.5,100)
	return string.sub(DISC_TEXT,1,math.floor((adj/100)*#DISC_TEXT))
end

local function isMyPlot(n)
	local pl=workspace:FindFirstChild("Plots"); if not pl then return false end
	local p=pl:FindFirstChild(n); if not p then return false end
	local s=p:FindFirstChild("PlotSign")
	if s then
		local y=s:FindFirstChild("YourBase")
		if y and y:IsA("BillboardGui") then return y.Enabled end
	end
	return false
end

local ProgFill,ProgLabel,ProgPct,RadBox

local function resetProg()
	if ProgLabel then ProgLabel.Text="STANDBY" end
	if ProgPct   then ProgPct.Text=""          end
	if ProgFill  then ProgFill.Size=UDim2.new(0,0,1,0) end
end

local function findPrompt()
	local h=getHRP(); if not h then return nil end
	local pl=workspace:FindFirstChild("Plots"); if not pl then return nil end
	local bp,bd,bn=nil,math.huge,nil
	for _,plot in ipairs(pl:GetChildren()) do
		if isMyPlot(plot.Name) then continue end
		local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
		for _,pod in ipairs(pods:GetChildren()) do
			pcall(function()
				local base=pod:FindFirstChild("Base")
				local sp=base and base:FindFirstChild("Spawn")
				if sp then
					local d=(sp.Position-h.Position).Magnitude
					if d<bd and d<=Val.StealRad then
						local att=sp:FindFirstChild("PromptAttachment")
						if att then
							for _,ch in ipairs(att:GetChildren()) do
								if ch:IsA("ProximityPrompt") then bp=ch; bd=d; bn=pod.Name; break end
							end
						end
					end
				end
			end)
		end
	end
	return bp,bd,bn
end

local function doSteal(prompt,name)
	if stealing then return end
	if not StealCache[prompt] then
		StealCache[prompt]={hold={},trig={},ready=true}
		pcall(function()
			if getconnections then
				for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
					if c.Function then table.insert(StealCache[prompt].hold,c.Function) end
				end
				for _,c in ipairs(getconnections(prompt.Triggered)) do
					if c.Function then table.insert(StealCache[prompt].trig,c.Function) end
				end
			end
		end)
	end
	local d=StealCache[prompt]; if not d.ready then return end
	d.ready=false; stealing=true; stealStart=tick()
	if ProgLabel then ProgLabel.Text=name or "STEALING" end
	if stealConn then stealConn:Disconnect() end
	stealConn=RunService.Heartbeat:Connect(function()
		if not stealing then stealConn:Disconnect(); return end
		local pr=math.clamp((tick()-stealStart)/Val.StealDur,0,1)
		if ProgFill then ProgFill.Size=UDim2.new(pr,0,1,0) end
		if ProgPct  then ProgPct.Text=discReveal(math.floor(pr*100)) end
	end)
	task.spawn(function()
		for _,f in ipairs(d.hold) do task.spawn(f) end
		task.wait(Val.StealDur)
		for _,f in ipairs(d.trig) do task.spawn(f) end
		if stealConn then stealConn:Disconnect() end
		resetProg(); d.ready=true; stealing=false
	end)
end

local function startSteal()
	if Conns.steal then return end
	Conns.steal=RunService.Heartbeat:Connect(function()
		if not Enabled.Steal or stealing then return end
		local p,_,n=findPrompt(); if p then doSteal(p,n) end
	end)
end
local function stopSteal()
	if Conns.steal then Conns.steal:Disconnect(); Conns.steal=nil end
	stealing=false; resetProg()
end

local function startStealSpeed()
	if Conns.sspd then return end
	Conns.sspd=RunService.Heartbeat:Connect(function()
		if not Enabled.StealSpeed or not lp:GetAttribute("Stealing") then return end
		local h=getHRP(); if not h then return end
		local md=getMD()
		if md.Magnitude>0.1 then
			h.AssemblyLinearVelocity=Vector3.new(md.X*Val.StealSpd,h.AssemblyLinearVelocity.Y,md.Z*Val.StealSpd)
		end
	end)
end
local function stopStealSpeed()
	if Conns.sspd then Conns.sspd:Disconnect(); Conns.sspd=nil end
end

local savedAnim={}
local function startUnwalk()
	local c=lp.Character; if not c then return end
	local hum=c:FindFirstChildOfClass("Humanoid")
	if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
	local an=c:FindFirstChild("Animate")
	if an then savedAnim.v=an:Clone(); an:Destroy() end
end
local function stopUnwalk()
	local c=lp.Character
	if c and savedAnim.v then savedAnim.v:Clone().Parent=c; savedAnim.v=nil end
end

local origTrans={}
local function startOptimizer()
	if getgenv and getgenv().SDX_OPT then return end
	if getgenv then getgenv().SDX_OPT=true end
	pcall(function()
		settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
		Lighting.GlobalShadows=false; Lighting.Brightness=3; Lighting.FogEnd=9e9
	end)
	pcall(function()
		for _,o in ipairs(workspace:GetDescendants()) do
			pcall(function()
				if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") then o:Destroy()
				elseif o:IsA("BasePart") then o.CastShadow=false; o.Material=Enum.Material.Plastic end
			end)
		end
	end)
	pcall(function()
		for _,o in ipairs(workspace:GetDescendants()) do
			if o:IsA("BasePart") and o.Anchored and
				(o.Name:lower():find("base") or (o.Parent and o.Parent.Name:lower():find("base"))) then
				origTrans[o]=o.LocalTransparencyModifier; o.LocalTransparencyModifier=0.85
			end
		end
	end)
end
local function stopOptimizer()
	if getgenv then getgenv().SDX_OPT=false end
	for p,v in pairs(origTrans) do if p then p.LocalTransparencyModifier=v end end
	origTrans={}
end

local origSky,skyInst,skyConn,planets,bloom,cc=nil,nil,nil,{},nil,nil
local function startSkyBright()
	if skyInst then return end
	origSky=Lighting:FindFirstChildOfClass("Sky"); if origSky then origSky.Parent=nil end
	skyInst=Instance.new("Sky")
	for _,k in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do
		skyInst[k]="rbxassetid://1534951537"
	end
	skyInst.StarCount=10000; skyInst.CelestialBodiesShown=false; skyInst.Parent=Lighting
	bloom=Instance.new("BloomEffect"); bloom.Intensity=1.5; bloom.Size=40; bloom.Threshold=0.8; bloom.Parent=Lighting
	cc=Instance.new("ColorCorrectionEffect"); cc.Saturation=-1; cc.Contrast=0.4
	cc.TintColor=Color3.fromRGB(255,255,255); cc.Parent=Lighting
	Lighting.Ambient=Color3.fromRGB(180,180,180); Lighting.Brightness=3; Lighting.ClockTime=0
	for i=1,2 do
		local p=Instance.new("Part"); p.Shape=Enum.PartType.Ball
		p.Size=Vector3.new(800+i*200,800+i*200,800+i*200); p.Anchored=true; p.CanCollide=false
		p.CastShadow=false; p.Material=Enum.Material.Neon
		p.Color=Color3.fromRGB(200,200,200); p.Transparency=0.3
		p.Position=Vector3.new(math.cos(i*2)*(3000+i*500),1500+i*300,math.sin(i*2)*(3000+i*500))
		p.Parent=workspace; table.insert(planets,p)
	end
	skyConn=RunService.Heartbeat:Connect(function()
		if not Enabled.SkyBright then return end
		local t=tick()*0.5
		local v=180+math.floor(math.sin(t)*60)
		Lighting.Ambient=Color3.fromRGB(v,v,v)
		if bloom then bloom.Intensity=1.2+math.sin(t*2)*0.4 end
	end)
end
local function stopSkyBright()
	if skyConn then skyConn:Disconnect(); skyConn=nil end
	if skyInst then skyInst:Destroy(); skyInst=nil end
	if origSky then origSky.Parent=Lighting end
	if bloom then bloom:Destroy(); bloom=nil end
	if cc then cc:Destroy(); cc=nil end
	for _,p in ipairs(planets) do if p then p:Destroy() end end; planets={}
	Lighting.Ambient=Color3.fromRGB(127,127,127); Lighting.Brightness=2; Lighting.ClockTime=14
end

local function faceSouth()
	local c=lp.Character; if not c then return end
	local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
	h.CFrame=CFrame.new(h.Position)*CFrame.Angles(0,0,0)
	local cam=workspace.CurrentCamera
	if cam then cam.CFrame=CFrame.new(h.Position.X,h.Position.Y+5,h.Position.Z-12)*CFrame.Angles(math.rad(-15),0,0) end
end
local function faceNorth()
	local c=lp.Character; if not c then return end
	local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
	h.CFrame=CFrame.new(h.Position)*CFrame.Angles(0,math.rad(180),0)
	local cam=workspace.CurrentCamera
	if cam then cam.CFrame=CFrame.new(h.Position.X,h.Position.Y+2,h.Position.Z+12)*CFrame.Angles(0,math.rad(180),0) end
end

local autoLWalk,autoRWalk=nil,nil
local autoLPhase,autoRPhase=1,1
local AutoLeft=false; local AutoRight=false

local function startLeft()
	if autoLWalk then autoLWalk:Disconnect() end; autoLPhase=1
	autoLWalk=RunService.Heartbeat:Connect(function()
		if not AutoLeft then return end
		local h=getHRP(); local hum=getHum(); if not h or not hum then return end
		local tgt=(autoLPhase==1) and POS1 or POS2
		local dist=(Vector3.new(tgt.X,h.Position.Y,tgt.Z)-h.Position).Magnitude
		if dist<1 then
			if autoLPhase==1 then autoLPhase=2
			else
				hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.zero
				AutoLeft=false; Enabled.AutoLeft=false
				if VSetters.AutoLeft then VSetters.AutoLeft(false,true) end
				if autoLWalk then autoLWalk:Disconnect(); autoLWalk=nil end
				faceSouth(); return
			end
		end
		local dir=Vector3.new(tgt.X-h.Position.X,0,tgt.Z-h.Position.Z).Unit
		hum:Move(dir,false)
		h.AssemblyLinearVelocity=Vector3.new(dir.X*Val.SpeedAmt,h.AssemblyLinearVelocity.Y,dir.Z*Val.SpeedAmt)
	end)
end
local function stopLeft()
	if autoLWalk then autoLWalk:Disconnect(); autoLWalk=nil end; autoLPhase=1
	local hum=getHum(); if hum then hum:Move(Vector3.zero,false) end
end

local function startRight()
	if autoRWalk then autoRWalk:Disconnect() end; autoRPhase=1
	autoRWalk=RunService.Heartbeat:Connect(function()
		if not AutoRight then return end
		local h=getHRP(); local hum=getHum(); if not h or not hum then return end
		local tgt=(autoRPhase==1) and POSR1 or POSR2
		local dist=(Vector3.new(tgt.X,h.Position.Y,tgt.Z)-h.Position).Magnitude
		if dist<1 then
			if autoRPhase==1 then autoRPhase=2
			else
				hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.zero
				AutoRight=false; Enabled.AutoRight=false
				if VSetters.AutoRight then VSetters.AutoRight(false,true) end
				if autoRWalk then autoRWalk:Disconnect(); autoRWalk=nil end
				faceNorth(); return
			end
		end
		local dir=Vector3.new(tgt.X-h.Position.X,0,tgt.Z-h.Position.Z).Unit
		hum:Move(dir,false)
		h.AssemblyLinearVelocity=Vector3.new(dir.X*Val.SpeedAmt,h.AssemblyLinearVelocity.Y,dir.Z*Val.SpeedAmt)
	end)
end
local function stopRight()
	if autoRWalk then autoRWalk:Disconnect(); autoRWalk=nil end; autoRPhase=1
	local hum=getHum(); if hum then hum:Move(Vector3.zero,false) end
end

local function nuke()
	if not BALLOON then return end
	local t=nearestPlayer(); if not t then return end
	for _,p in ipairs({"balloon","ragdoll","jumpscare","morph","tiny","rocket","inverse","jail"}) do
		BALLOON:FireServer(ADMIN_KEY,t,p)
	end
end

--   AUTO KICK
local kickConns={}
local KICK_KW="you stole"

local function watchText(obj)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
	local function chk()
		if string.find(string.lower(obj.Text or ""),KICK_KW) then
			pcall(function() lp:Kick("Kicked by Singularity AntiSteal") end)
		end
	end
	chk()
	local c=obj:GetPropertyChangedSignal("Text"):Connect(chk)
	table.insert(kickConns,c)
end
local function scanGui(g)
	for _,o in ipairs(g:GetDescendants()) do watchText(o) end
	local c=g.DescendantAdded:Connect(watchText)
	table.insert(kickConns,c)
end
local function enableKick()
	for _,g in ipairs(PlayerGui:GetChildren()) do scanGui(g) end
	local c=PlayerGui.ChildAdded:Connect(scanGui)
	table.insert(kickConns,c)
end
local function disableKick()
	for _,c in ipairs(kickConns) do if c and c.Connected then c:Disconnect() end end
	kickConns={}
end

--   ESP
local espConns={}

local function removeESP(plr)
	if not plr.Character then return end
	for _,n in ipairs({"SDX_ESP_Box","SDX_ESP_Name"}) do
		local o=plr.Character:FindFirstChild(n)
		if o then o:Destroy() end
	end
end

local function buildESP(plr)
	if plr==lp then return end
	if not plr.Character then return end
	if plr.Character:FindFirstChild("SDX_ESP_Box") then return end
	local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
	local head=plr.Character:FindFirstChild("Head")
	if not (hrp and head) then return end

	local box=Instance.new("BoxHandleAdornment")
	box.Name="SDX_ESP_Box"; box.Adornee=hrp
	box.Size=Vector3.new(4,6,2)
	box.Color3=Color3.fromRGB(255,255,255)
	box.Transparency=0.45; box.ZIndex=10; box.AlwaysOnTop=true
	box.Parent=plr.Character

	local bb=Instance.new("BillboardGui")
	bb.Name="SDX_ESP_Name"; bb.Adornee=head
	bb.Size=UDim2.new(0,180,0,44); bb.StudsOffset=Vector3.new(0,3,0)
	bb.AlwaysOnTop=true; bb.Parent=plr.Character

	local lbl=Instance.new("TextLabel",bb)
	lbl.Size=UDim2.new(1,0,0.6,0); lbl.BackgroundTransparency=1
	lbl.Text=plr.DisplayName or plr.Name
	lbl.TextColor3=Color3.fromRGB(255,255,255)
	lbl.Font=Enum.Font.GothamBlack; lbl.TextScaled=true
	lbl.TextStrokeTransparency=0.3; lbl.TextStrokeColor3=Color3.new(0,0,0)

	local hpBg=Instance.new("Frame",bb)
	hpBg.Size=UDim2.new(0.8,0,0.22,0); hpBg.Position=UDim2.new(0.1,0,0.72,0)
	hpBg.BackgroundColor3=Color3.fromRGB(30,30,30); hpBg.BorderSizePixel=0
	Instance.new("UICorner",hpBg).CornerRadius=UDim.new(1,0)

	local hpFill=Instance.new("Frame",hpBg)
	hpFill.Size=UDim2.new(1,0,1,0); hpFill.BackgroundColor3=Color3.fromRGB(220,220,220)
	hpFill.BorderSizePixel=0; Instance.new("UICorner",hpFill).CornerRadius=UDim.new(1,0)

	RunService.Heartbeat:Connect(function()
		if not Enabled.ESP then return end
		local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.MaxHealth>0 then
			hpFill.Size=UDim2.new(hum.Health/hum.MaxHealth,0,1,0)
		end
	end)
end

local function enableESP()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=lp then
			if p.Character then buildESP(p) end
			local c=p.CharacterAdded:Connect(function() task.wait(0.1); if Enabled.ESP then buildESP(p) end end)
			table.insert(espConns,c)
		end
	end
	local c=Players.PlayerAdded:Connect(function(p)
		if p==lp then return end
		local cc=p.CharacterAdded:Connect(function() task.wait(0.1); if Enabled.ESP then buildESP(p) end end)
		table.insert(espConns,cc)
	end)
	table.insert(espConns,c)
end
local function disableESP()
	for _,p in ipairs(Players:GetPlayers()) do removeESP(p) end
	for _,c in ipairs(espConns) do if c and c.Connected then c:Disconnect() end end
	espConns={}
end

local espFolder=Instance.new("Folder",workspace); espFolder.Name="SDX_CoordESP"
local function mkMarker(pos,txt,col)
	local dot=Instance.new("Part",espFolder)
	dot.Anchored=true; dot.CanCollide=false; dot.CastShadow=false
	dot.Material=Enum.Material.Neon; dot.Color=col
	dot.Shape=Enum.PartType.Ball; dot.Size=Vector3.one; dot.Position=pos; dot.Transparency=0.2
	local bb=Instance.new("BillboardGui",dot)
	bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,90,0,18); bb.StudsOffset=Vector3.new(0,2,0); bb.MaxDistance=300
	local tl=Instance.new("TextLabel",bb)
	tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1; tl.Text=txt
	tl.TextColor3=col; tl.TextStrokeTransparency=0; tl.TextStrokeColor3=Color3.new(0,0,0)
	tl.Font=Enum.Font.GothamBold; tl.TextSize=11
end
mkMarker(POS1,  "L1",    Color3.fromRGB(255,255,255))
mkMarker(POS2,  "L END", Color3.fromRGB(200,200,200))
mkMarker(POSR1, "R1",    Color3.fromRGB(255,255,255))
mkMarker(POSR2, "R END", Color3.fromRGB(180,180,180))

--   PALETTE  customize it daddy
local isMob = UIS.TouchEnabled and not UIS.KeyboardEnabled
local GS    = isMob and 0.42 or 1

-- Pure B&W palette
local C = {
	bg        = Color3.fromRGB(8,   8,   8),
	surface   = Color3.fromRGB(14,  14,  14),
	card      = Color3.fromRGB(20,  20,  20),
	cardHov   = Color3.fromRGB(28,  28,  28),
	border    = Color3.fromRGB(45,  45,  45),
	borderDim = Color3.fromRGB(30,  30,  30),
	white     = Color3.fromRGB(255, 255, 255),
	offWhite  = Color3.fromRGB(210, 210, 210),
	dimWhite  = Color3.fromRGB(140, 140, 140),
	mutedWht  = Color3.fromRGB(70,  70,  70),
	accent    = Color3.fromRGB(230, 230, 230),
	accentDim = Color3.fromRGB(100, 100, 100),
	danger    = Color3.fromRGB(255, 80,  80),
	success   = Color3.fromRGB(100, 220, 130),
	tabSel    = Color3.fromRGB(235, 235, 235),
}

--   SCREEN GUI
local sg=Instance.new("ScreenGui")
sg.Name="SingularityDuels"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=PlayerGui

--   PLAYER HUD  (top-right)
local hud=Instance.new("Frame",sg)
hud.Size=UDim2.new(0,220*GS,0,68*GS)
hud.Position=UDim2.new(1,-228*GS,0,10*GS)
hud.BackgroundColor3=C.surface
hud.BorderSizePixel=0; hud.ZIndex=30
Instance.new("UICorner",hud).CornerRadius=UDim.new(0,12*GS)
local hudStroke=Instance.new("UIStroke",hud)
hudStroke.Color=C.border; hudStroke.Thickness=1

-- thin white top-line accent
local hudAccent=Instance.new("Frame",hud)
hudAccent.Size=UDim2.new(0.6,0,0,2); hudAccent.Position=UDim2.new(0.2,0,0,0)
hudAccent.BackgroundColor3=C.white; hudAccent.BorderSizePixel=0; hudAccent.ZIndex=31
Instance.new("UICorner",hudAccent).CornerRadius=UDim.new(1,0)

-- Avatar circle
local avFrame=Instance.new("Frame",hud)
avFrame.Size=UDim2.new(0,46*GS,0,46*GS)
avFrame.Position=UDim2.new(0,11*GS,0.5,-23*GS)
avFrame.BackgroundColor3=C.card; avFrame.BorderSizePixel=0; avFrame.ZIndex=31
Instance.new("UICorner",avFrame).CornerRadius=UDim.new(1,0)
local avImg=Instance.new("ImageLabel",avFrame)
avImg.Size=UDim2.new(1,0,1,0); avImg.BackgroundTransparency=1; avImg.ZIndex=32
Instance.new("UICorner",avImg).CornerRadius=UDim.new(1,0)
pcall(function()
	avImg.Image="https://www.roblox.com/headshot-thumbnail/image?userId="..lp.UserId.."&width=150&height=150&format=png"
end)

-- Name
local hudName=Instance.new("TextLabel",hud)
hudName.Size=UDim2.new(0,148*GS,0,18*GS)
hudName.Position=UDim2.new(0,66*GS,0,9*GS)
hudName.BackgroundTransparency=1; hudName.ZIndex=31
hudName.Text=lp.DisplayName
hudName.TextColor3=C.white; hudName.Font=Enum.Font.GothamBlack
hudName.TextSize=13*GS; hudName.TextXAlignment=Enum.TextXAlignment.Left

-- Ping
local hudPing=Instance.new("TextLabel",hud)
hudPing.Size=UDim2.new(0,148*GS,0,12*GS)
hudPing.Position=UDim2.new(0,66*GS,0,30*GS)
hudPing.BackgroundTransparency=1; hudPing.ZIndex=31
hudPing.Text="● PING  --ms"
hudPing.TextColor3=C.dimWhite; hudPing.Font=Enum.Font.GothamMedium
hudPing.TextSize=9*GS; hudPing.TextXAlignment=Enum.TextXAlignment.Left

-- FPS
local hudFPS=Instance.new("TextLabel",hud)
hudFPS.Size=UDim2.new(0,148*GS,0,12*GS)
hudFPS.Position=UDim2.new(0,66*GS,0,45*GS)
hudFPS.BackgroundTransparency=1; hudFPS.ZIndex=31
hudFPS.Text="● FPS   --"
hudFPS.TextColor3=C.dimWhite; hudFPS.Font=Enum.Font.GothamMedium
hudFPS.TextSize=9*GS; hudFPS.TextXAlignment=Enum.TextXAlignment.Left

local _frameCount,_accum=0,0
RunService.Heartbeat:Connect(function(dt)
	_frameCount+=1; _accum+=dt
	if _accum>=0.5 then
		local fps=math.floor(_frameCount/_accum)
		hudFPS.Text="● FPS   "..fps
		hudFPS.TextColor3=(fps>=55) and C.success or (fps>=30) and C.offWhite or C.danger
		_frameCount=0; _accum=0
		pcall(function()
			local ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			hudPing.Text="● PING  "..ping.."ms"
			hudPing.TextColor3=(ping<100) and C.success or (ping<200) and C.offWhite or C.danger
		end)
	end
end)

--   STEAL PROGRESS BAR  (bottom-center)
local pBar=Instance.new("Frame",sg)
pBar.Size=UDim2.new(0,380*GS,0,54*GS)
pBar.Position=UDim2.new(0.5,-190*GS,1,-140*GS)
pBar.BackgroundColor3=C.surface
pBar.BorderSizePixel=0; pBar.ClipsDescendants=true; pBar.ZIndex=20
Instance.new("UICorner",pBar).CornerRadius=UDim.new(0,12*GS)
Instance.new("UIStroke",pBar).Color=C.border

local pbAccent=Instance.new("Frame",pBar)
pbAccent.Size=UDim2.new(0.5,0,0,2); pbAccent.Position=UDim2.new(0.25,0,0,0)
pbAccent.BackgroundColor3=C.white; pbAccent.BorderSizePixel=0; pbAccent.ZIndex=21
Instance.new("UICorner",pbAccent).CornerRadius=UDim.new(1,0)

ProgLabel=Instance.new("TextLabel",pBar)
ProgLabel.Size=UDim2.new(0.5,0,0,20*GS); ProgLabel.Position=UDim2.new(0,14*GS,0,6*GS)
ProgLabel.BackgroundTransparency=1; ProgLabel.Text="STANDBY"
ProgLabel.TextColor3=C.offWhite; ProgLabel.Font=Enum.Font.GothamBold
ProgLabel.TextSize=12*GS; ProgLabel.TextXAlignment=Enum.TextXAlignment.Left; ProgLabel.ZIndex=22

ProgPct=Instance.new("TextLabel",pBar)
ProgPct.Size=UDim2.new(0.45,0,0,20*GS); ProgPct.Position=UDim2.new(0.55,0,0,6*GS)
ProgPct.BackgroundTransparency=1; ProgPct.Text=""
ProgPct.TextColor3=C.white; ProgPct.Font=Enum.Font.GothamBlack
ProgPct.TextSize=14*GS; ProgPct.TextXAlignment=Enum.TextXAlignment.Right; ProgPct.ZIndex=22

RadBox=Instance.new("TextBox",pBar)
RadBox.Size=UDim2.new(0,44*GS,0,20*GS); RadBox.Position=UDim2.new(1,-52*GS,0,5*GS)
RadBox.BackgroundColor3=C.card; RadBox.Text=tostring(Val.StealRad)
RadBox.TextColor3=C.white; RadBox.Font=Enum.Font.GothamBold; RadBox.TextSize=11*GS; RadBox.ZIndex=22
Instance.new("UICorner",RadBox).CornerRadius=UDim.new(0,6*GS)
Instance.new("UIStroke",RadBox).Color=C.border
RadBox.FocusLost:Connect(function()
	local n=tonumber(RadBox.Text)
	if n then Val.StealRad=math.clamp(math.floor(n),5,100); RadBox.Text=tostring(Val.StealRad) end
end)

local pTrack=Instance.new("Frame",pBar)
pTrack.Size=UDim2.new(0.90,0,0,6*GS); pTrack.Position=UDim2.new(0.05,0,1,-14*GS)
pTrack.BackgroundColor3=C.card; pTrack.ZIndex=21
Instance.new("UICorner",pTrack).CornerRadius=UDim.new(1,0)
ProgFill=Instance.new("Frame",pTrack)
ProgFill.Size=UDim2.new(0,0,1,0); ProgFill.BackgroundColor3=C.white; ProgFill.ZIndex=22
Instance.new("UICorner",ProgFill).CornerRadius=UDim.new(1,0)

--   MAIN WINDOW
local main=Instance.new("Frame",sg)
main.Name="SingularityMain"
main.Size=UDim2.new(0,560*GS,0,540*GS)
main.Position=isMob and UDim2.new(0.5,-280*GS,0.5,-270*GS) or UDim2.new(0,20,0.5,-270)
main.BackgroundColor3=C.bg
main.BorderSizePixel=0; main.Active=true; main.Draggable=true
main.ClipsDescendants=true; main.ZIndex=5
Instance.new("UICorner",main).CornerRadius=UDim.new(0,18*GS)
Instance.new("UIStroke",main).Color=C.border

-- Subtle gradient overlay
local mainGrad=Instance.new("Frame",main)
mainGrad.Size=UDim2.new(1,0,0.35,0); mainGrad.BackgroundColor3=C.surface
mainGrad.BorderSizePixel=0; mainGrad.ZIndex=5
local mg=Instance.new("UIGradient",mainGrad)
mg.Color=ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22,22,22)),
	ColorSequenceKeypoint.new(1, C.bg)
})
mg.Rotation=90

-- HEADER
local hdr=Instance.new("Frame",main)
hdr.Size=UDim2.new(1,0,0,62*GS); hdr.BackgroundTransparency=1; hdr.ZIndex=10

-- Logo dot idfk how to make it the crystal
local logoDot=Instance.new("Frame",hdr)
logoDot.Size=UDim2.new(0,8*GS,0,8*GS); logoDot.Position=UDim2.new(0,16*GS,0.5,-4*GS)
logoDot.BackgroundColor3=C.white; logoDot.BorderSizePixel=0; logoDot.ZIndex=11
Instance.new("UICorner",logoDot).CornerRadius=UDim.new(1,0)

local ttl=Instance.new("TextLabel",hdr)
ttl.Size=UDim2.new(1,-100*GS,0,28*GS); ttl.Position=UDim2.new(0,30*GS,0,10*GS)
ttl.BackgroundTransparency=1; ttl.Text="SINGULARITY DUELS"
ttl.TextColor3=C.white; ttl.Font=Enum.Font.GothamBlack
ttl.TextSize=20*GS; ttl.TextXAlignment=Enum.TextXAlignment.Left; ttl.ZIndex=11

local sub=Instance.new("TextLabel",hdr)
sub.Size=UDim2.new(0,200*GS,0,12*GS); sub.Position=UDim2.new(0,30*GS,0,40*GS)
sub.BackgroundTransparency=1; sub.Text="by @fcaouss  ·  discord.gg/singularityhere"
sub.TextColor3=C.mutedWht; sub.Font=Enum.Font.Gotham
sub.TextSize=9*GS; sub.TextXAlignment=Enum.TextXAlignment.Left; sub.ZIndex=11

-- Close btn
local xBtn=Instance.new("TextButton",hdr)
xBtn.Size=UDim2.new(0,28*GS,0,28*GS); xBtn.Position=UDim2.new(1,-38*GS,0.5,-14*GS)
xBtn.BackgroundColor3=C.card; xBtn.Text="✕"
xBtn.TextColor3=C.dimWhite; xBtn.Font=Enum.Font.GothamBold
xBtn.TextSize=14*GS; xBtn.ZIndex=12; xBtn.BorderSizePixel=0
Instance.new("UICorner",xBtn).CornerRadius=UDim.new(0,8*GS)
xBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
xBtn.MouseEnter:Connect(function()
	TweenService:Create(xBtn,TweenInfo.new(0.15),{BackgroundColor3=C.danger,TextColor3=C.white}):Play()
end)
xBtn.MouseLeave:Connect(function()
	TweenService:Create(xBtn,TweenInfo.new(0.15),{BackgroundColor3=C.card,TextColor3=C.dimWhite}):Play()
end)

-- Divider
local div=Instance.new("Frame",main)
div.Size=UDim2.new(0.96,0,0,1); div.Position=UDim2.new(0.02,0,0,63*GS)
div.BackgroundColor3=C.border; div.BorderSizePixel=0; div.ZIndex=10

-- ── TAB BAR ──────────────────────────────────────────────────
-- Pill-style container
local tabCont=Instance.new("Frame",main)
tabCont.Size=UDim2.new(0.96,0,0,36*GS); tabCont.Position=UDim2.new(0.02,0,0,68*GS)
tabCont.BackgroundColor3=C.surface; tabCont.BorderSizePixel=0; tabCont.ZIndex=10
Instance.new("UICorner",tabCont).CornerRadius=UDim.new(0,10*GS)
Instance.new("UIStroke",tabCont).Color=C.borderDim

local tabNames={"COMBAT","MOVEMENT","UTILITY","MISC"}
local tabBtns={}
local tabPanels={}
local currentTab=1

-- Sliding selector pill
local tabPill=Instance.new("Frame",tabCont)
tabPill.Size=UDim2.new(0.25,-4,1,-6); tabPill.Position=UDim2.new(0,3,0,3)
tabPill.BackgroundColor3=C.white; tabPill.BorderSizePixel=0; tabPill.ZIndex=11
Instance.new("UICorner",tabPill).CornerRadius=UDim.new(0,8*GS)

local function switchTab(idx)
	currentTab=idx
	local segW=1/#tabNames
	TweenService:Create(tabPill,TweenInfo.new(0.22,Enum.EasingStyle.Quint),{
		Position=UDim2.new(segW*(idx-1),3,0,3)
	}):Play()
	for i,btn in ipairs(tabBtns) do
		TweenService:Create(btn,TweenInfo.new(0.18),{
			TextColor3=(i==idx) and C.bg or C.mutedWht
		}):Play()
	end
	for i,p in ipairs(tabPanels) do p.Visible=(i==idx) end
end

local segW=1/#tabNames
for i,name in ipairs(tabNames) do
	local btn=Instance.new("TextButton",tabCont)
	btn.Size=UDim2.new(segW,0,1,0); btn.Position=UDim2.new(segW*(i-1),0,0,0)
	btn.BackgroundTransparency=1; btn.Text=name
	btn.TextColor3=(i==1) and C.bg or C.mutedWht
	btn.Font=Enum.Font.GothamBold; btn.TextSize=10*GS; btn.ZIndex=13
	btn.MouseButton1Click:Connect(function() switchTab(i); playClick() end)
	tabBtns[i]=btn

	local panel=Instance.new("ScrollingFrame",main)
	panel.Size=UDim2.new(0.96,0,0,405*GS); panel.Position=UDim2.new(0.02,0,0,110*GS)
	panel.BackgroundTransparency=1; panel.BorderSizePixel=0
	panel.ScrollBarThickness=3; panel.ScrollBarImageColor3=C.accentDim
	panel.CanvasSize=UDim2.new(0,0,0,0); panel.AutomaticCanvasSize=Enum.AutomaticSize.Y
	panel.Visible=(i==1); panel.ZIndex=10
	local layout=Instance.new("UIListLayout",panel)
	layout.Padding=UDim.new(0,5*GS); layout.SortOrder=Enum.SortOrder.LayoutOrder
	local pad=Instance.new("UIPadding",panel)
	pad.PaddingLeft=UDim.new(0,4*GS); pad.PaddingRight=UDim.new(0,4*GS)
	pad.PaddingTop=UDim.new(0,4*GS); pad.PaddingBottom=UDim.new(0,8*GS)
	tabPanels[i]=panel
end

--   COMPONENT BUILDERS

-- Section label
local function mkSection(parent,text)
	local f=Instance.new("Frame",parent)
	f.Size=UDim2.new(1,0,0,22*GS); f.BackgroundTransparency=1; f.ZIndex=11
	-- left tick mark
	local tick=Instance.new("Frame",f)
	tick.Size=UDim2.new(0,3,0,12*GS); tick.Position=UDim2.new(0,0,0.5,-6*GS)
	tick.BackgroundColor3=C.white; tick.BorderSizePixel=0; tick.ZIndex=12
	Instance.new("UICorner",tick).CornerRadius=UDim.new(1,0)
	local l=Instance.new("TextLabel",f)
	l.Size=UDim2.new(1,-10*GS,1,0); l.Position=UDim2.new(0,10*GS,0,0)
	l.BackgroundTransparency=1; l.Text=text
	l.TextColor3=C.dimWhite; l.Font=Enum.Font.GothamBold
	l.TextSize=9*GS; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=12
	return f
end

-- Toggle (no keybind)
local function mkToggle(parent,label,eKey,onToggle)
	local row=Instance.new("Frame",parent)
	row.Size=UDim2.new(1,0,0,46*GS); row.BackgroundColor3=C.card
	row.BorderSizePixel=0; row.ZIndex=11
	Instance.new("UICorner",row).CornerRadius=UDim.new(0,10*GS)
	Instance.new("UIStroke",row).Color=C.borderDim

	-- left indicator bar
	local bar=Instance.new("Frame",row)
	bar.Size=UDim2.new(0,3,0.6,0); bar.Position=UDim2.new(0,0,0.2,0)
	bar.BackgroundColor3=C.mutedWht; bar.BorderSizePixel=0; bar.ZIndex=12
	Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)

	local lbl=Instance.new("TextLabel",row)
	lbl.Size=UDim2.new(0.65,0,1,0); lbl.Position=UDim2.new(0,14*GS,0,0)
	lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C.offWhite
	lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12*GS
	lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=12

	local isOn=Enabled[eKey] or false

	-- Toggle track
	local tBg=Instance.new("Frame",row)
	tBg.Size=UDim2.new(0,44*GS,0,22*GS); tBg.Position=UDim2.new(1,-54*GS,0.5,-11*GS)
	tBg.BackgroundColor3=isOn and C.white or C.card; tBg.ZIndex=12
	Instance.new("UICorner",tBg).CornerRadius=UDim.new(1,0)
	local tStroke=Instance.new("UIStroke",tBg); tStroke.Color=C.accentDim; tStroke.Thickness=1

	local knob=Instance.new("Frame",tBg)
	knob.Size=UDim2.new(0,16*GS,0,16*GS)
	knob.Position=isOn and UDim2.new(1,-19*GS,0.5,-8*GS) or UDim2.new(0,3*GS,0.5,-8*GS)
	knob.BackgroundColor3=isOn and C.bg or C.accentDim; knob.ZIndex=13
	Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

	local hit=Instance.new("TextButton",row)
	hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=14

	local function setV(state,skip)
		isOn=state; Enabled[eKey]=state
		TweenService:Create(tBg,TweenInfo.new(0.2),{BackgroundColor3=isOn and C.white or C.card}):Play()
		TweenService:Create(knob,TweenInfo.new(0.2,Enum.EasingStyle.Back),{
			BackgroundColor3=isOn and C.bg or C.accentDim,
			Position=isOn and UDim2.new(1,-19*GS,0.5,-8*GS) or UDim2.new(0,3*GS,0.5,-8*GS)
		}):Play()
		TweenService:Create(bar,TweenInfo.new(0.2),{BackgroundColor3=isOn and C.white or C.mutedWht}):Play()
		if not skip then onToggle(isOn) end
	end
	VSetters[eKey]=setV
	hit.MouseButton1Click:Connect(function() setV(not isOn); playClick() end)
	return row
end

-- Toggle with keybind button
local function mkToggleKB(parent,label,eKey,kbKey,onToggle)
	local row=Instance.new("Frame",parent)
	row.Size=UDim2.new(1,0,0,46*GS); row.BackgroundColor3=C.card
	row.BorderSizePixel=0; row.ZIndex=11
	Instance.new("UICorner",row).CornerRadius=UDim.new(0,10*GS)
	Instance.new("UIStroke",row).Color=C.borderDim

	local bar=Instance.new("Frame",row)
	bar.Size=UDim2.new(0,3,0.6,0); bar.Position=UDim2.new(0,0,0.2,0)
	bar.BackgroundColor3=C.mutedWht; bar.BorderSizePixel=0; bar.ZIndex=12
	Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)

	-- KB pill
	local kbBtn=Instance.new("TextButton",row)
	kbBtn.Size=UDim2.new(0,32*GS,0,20*GS); kbBtn.Position=UDim2.new(0,10*GS,0.5,-10*GS)
	kbBtn.BackgroundColor3=C.surface; kbBtn.Text=KB[kbKey].Name
	kbBtn.TextColor3=C.offWhite; kbBtn.Font=Enum.Font.GothamBold
	kbBtn.TextSize=8*GS; kbBtn.ZIndex=13; kbBtn.BorderSizePixel=0
	Instance.new("UICorner",kbBtn).CornerRadius=UDim.new(0,6*GS)
	Instance.new("UIStroke",kbBtn).Color=C.border
	KBtns[kbKey]=kbBtn

	local lbl=Instance.new("TextLabel",row)
	lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0,48*GS,0,0)
	lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C.offWhite
	lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12*GS
	lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=12

	local isOn=Enabled[eKey] or false

	local tBg=Instance.new("Frame",row)
	tBg.Size=UDim2.new(0,44*GS,0,22*GS); tBg.Position=UDim2.new(1,-54*GS,0.5,-11*GS)
	tBg.BackgroundColor3=isOn and C.white or C.card; tBg.ZIndex=12
	Instance.new("UICorner",tBg).CornerRadius=UDim.new(1,0)
	Instance.new("UIStroke",tBg).Color=C.accentDim

	local knob=Instance.new("Frame",tBg)
	knob.Size=UDim2.new(0,16*GS,0,16*GS)
	knob.Position=isOn and UDim2.new(1,-19*GS,0.5,-8*GS) or UDim2.new(0,3*GS,0.5,-8*GS)
	knob.BackgroundColor3=isOn and C.bg or C.accentDim; knob.ZIndex=13
	Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

	local hit=Instance.new("TextButton",row)
	hit.Size=UDim2.new(0.45,0,1,0); hit.Position=UDim2.new(0.55,0,0,0)
	hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=14

	local function setV(state,skip)
		isOn=state; Enabled[eKey]=state
		TweenService:Create(tBg,TweenInfo.new(0.2),{BackgroundColor3=isOn and C.white or C.card}):Play()
		TweenService:Create(knob,TweenInfo.new(0.2,Enum.EasingStyle.Back),{
			BackgroundColor3=isOn and C.bg or C.accentDim,
			Position=isOn and UDim2.new(1,-19*GS,0.5,-8*GS) or UDim2.new(0,3*GS,0.5,-8*GS)
		}):Play()
		TweenService:Create(bar,TweenInfo.new(0.2),{BackgroundColor3=isOn and C.white or C.mutedWht}):Play()
		if not skip then onToggle(isOn) end
	end
	VSetters[eKey]=setV
	hit.MouseButton1Click:Connect(function() setV(not isOn); playClick() end)
	kbBtn.MouseButton1Click:Connect(function()
		waitKB=kbKey; kbBtn.Text="···"; playClick()
	end)
	return row
end

-- Slider
local function mkSlider(parent,label,vKey,mn,mx)
	local container=Instance.new("Frame",parent)
	container.Size=UDim2.new(1,0,0,54*GS); container.BackgroundColor3=C.card
	container.BorderSizePixel=0; container.ZIndex=11
	Instance.new("UICorner",container).CornerRadius=UDim.new(0,10*GS)
	Instance.new("UIStroke",container).Color=C.borderDim

	local lbl=Instance.new("TextLabel",container)
	lbl.Size=UDim2.new(0.6,0,0,18*GS); lbl.Position=UDim2.new(0,12*GS,0,7*GS)
	lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C.dimWhite
	lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=10*GS
	lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=12

	local def=Val[vKey]
	local vBox=Instance.new("TextBox",container)
	vBox.Size=UDim2.new(0,48*GS,0,22*GS); vBox.Position=UDim2.new(1,-56*GS,0,5*GS)
	vBox.BackgroundColor3=C.surface; vBox.Text=tostring(def)
	vBox.TextColor3=C.white; vBox.Font=Enum.Font.GothamBold
	vBox.TextSize=11*GS; vBox.ClearTextOnFocus=false; vBox.ZIndex=12
	Instance.new("UICorner",vBox).CornerRadius=UDim.new(0,7*GS)
	Instance.new("UIStroke",vBox).Color=C.border

	local track=Instance.new("Frame",container)
	track.Size=UDim2.new(0.88,0,0,6*GS); track.Position=UDim2.new(0.06,0,0,34*GS)
	track.BackgroundColor3=C.surface; track.ZIndex=12
	Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

	local pct=(def-mn)/(mx-mn)
	local fill=Instance.new("Frame",track)
	fill.Size=UDim2.new(pct,0,1,0); fill.BackgroundColor3=C.white; fill.ZIndex=13
	Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

	local thumb=Instance.new("Frame",track)
	thumb.Size=UDim2.new(0,12*GS,0,12*GS)
	thumb.Position=UDim2.new(pct,-6*GS,0.5,-6*GS)
	thumb.BackgroundColor3=C.white; thumb.ZIndex=14
	Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)

	local btn=Instance.new("TextButton",track)
	btn.Size=UDim2.new(1,0,5,0); btn.Position=UDim2.new(0,0,-2,0)
	btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=15

	local drag=false
	local function upd(rel)
		rel=math.clamp(rel,0,1)
		fill.Size=UDim2.new(rel,0,1,0)
		thumb.Position=UDim2.new(rel,-6*GS,0.5,-6*GS)
		local v=math.floor(mn+(mx-mn)*rel)
		vBox.Text=tostring(v); Val[vKey]=v
	end
	SSetters[vKey]=function(v)
		v=math.clamp(v,mn,mx); local r=(v-mn)/(mx-mn)
		fill.Size=UDim2.new(r,0,1,0); thumb.Position=UDim2.new(r,-6*GS,0.5,-6*GS)
		vBox.Text=tostring(v); Val[vKey]=v
	end
	btn.MouseButton1Down:Connect(function() drag=true end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
	end)
	UIS.InputChanged:Connect(function(i)
		if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
			upd((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X)
		end
	end)
	vBox.FocusLost:Connect(function()
		local n=tonumber(vBox.Text)
		if n then n=math.clamp(math.floor(n),mn,mx); vBox.Text=tostring(n); Val[vKey]=n
			local r=(n-mn)/(mx-mn); fill.Size=UDim2.new(r,0,1,0); thumb.Position=UDim2.new(r,-6*GS,0.5,-6*GS)
		end
	end)
	return container
end

-- Button
local function mkButton(parent,text,accent,cb)
	local col=accent or C.white
	local btn=Instance.new("TextButton",parent)
	btn.Size=UDim2.new(1,0,0,42*GS); btn.BackgroundColor3=col
	btn.Text=text; btn.TextColor3=accent==C.danger and C.white or C.bg
	btn.Font=Enum.Font.GothamBold; btn.TextSize=12*GS; btn.ZIndex=11; btn.BorderSizePixel=0
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10*GS)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.offWhite}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=col}):Play()
	end)
	btn.MouseButton1Click:Connect(function() cb(btn); playClick() end)
	return btn
end

--   TAB 1: COMBAT
local t1=tabPanels[1]
mkSection(t1,"SPEED")
mkToggleKB(t1,"Speed Boost","Speed","SPEED",function(s) if s then startSpeed() else stopSpeed() end end)
mkSlider(t1,"Boost Speed","SpeedAmt",5,80)
mkSection(t1,"SPIN & AIMBOT")
mkToggleKB(t1,"Spin Bot","Spin","SPIN",function(s) if s then startSpin() else stopSpin() end end)
mkSlider(t1,"Spin Speed","SpinAmt",5,60)
mkToggleKB(t1,"Bat Aimbot","Aimbot","AIMBOT",function(s) if s then startAimbot() else stopAimbot() end end)
mkToggle(t1,"Spam Bat","SpamBat",function(s) if s then startSpam() else stopSpam() end end)
mkSection(t1,"DEFENSE")
mkToggle(t1,"Anti Ragdoll","AntiRagdoll",function(s) if s then startAntiRag() else stopAntiRag() end end)
mkButton(t1,"⚡  NUKE NEAREST",C.danger,function() nuke() end)

--   TAB 2: MOVEMENT
local t2=tabPanels[2]
mkSection(t2,"GALAXY PHYSICS")
mkToggleKB(t2,"Galaxy Mode","Galaxy","GALAXY",function(s) if s then startGalaxy() else stopGalaxy() end end)
mkSlider(t2,"Gravity %","GravPct",25,130)
mkSlider(t2,"Hop Power","HopPow",10,80)
mkSection(t2,"AUTO DUEL WALK")
mkToggleKB(t2,"Auto Left","AutoLeft","LEFT",function(s)
	AutoLeft=s; Enabled.AutoLeft=s
	if s then startLeft() else stopLeft() end
end)
mkToggleKB(t2,"Auto Right","AutoRight","RIGHT",function(s)
	AutoRight=s; Enabled.AutoRight=s
	if s then startRight() else stopRight() end
end)
mkSection(t2,"ANIMATIONS")
mkToggle(t2,"Unwalk (no anims)","Unwalk",function(s) if s then startUnwalk() else stopUnwalk() end end)

--   TAB 3: UTILITY
local t3=tabPanels[3]
mkSection(t3,"AUTO STEAL")
mkToggle(t3,"Auto Steal","Steal",function(s) if s then startSteal() else stopSteal() end end)
mkSlider(t3,"Steal Duration","StealDur",0.5,3)
mkToggle(t3,"Speed While Stealing","StealSpeed",function(s) if s then startStealSpeed() else stopStealSpeed() end end)
mkSlider(t3,"Steal Speed","StealSpd",10,40)
mkSection(t3,"VISUALS")
mkToggle(t3,"ESP","ESP",function(s) if s then enableESP() else disableESP() end end)
mkToggle(t3,"Galaxy Sky Bright","SkyBright",function(s) if s then startSkyBright() else stopSkyBright() end end)
mkToggle(t3,"Optimizer + XRay","Optimizer",function(s) if s then startOptimizer() else stopOptimizer() end end)

--   TAB 4: MISC
local t4=tabPanels[4]
mkSection(t4,"ANTI STEAL")
mkToggle(t4,"Auto Kick (you stole)","AutoKick",function(s) if s then enableKick() else disableKick() end end)
mkSection(t4,"CONFIG")
mkButton(t4,"◈  Save Config",C.white,function(btn)
	local ok=SaveConfig()
	btn.Text=ok and "✓  Saved!" or "✗  Failed"
	btn.BackgroundColor3=ok and C.success or C.danger
	btn.TextColor3=C.bg
	task.delay(1.5,function()
		btn.Text="◈  Save Config"; btn.BackgroundColor3=C.white; btn.TextColor3=C.bg
	end)
end)
mkSection(t4,"KEYBINDS")
local infoCard=Instance.new("Frame",t4)
infoCard.Size=UDim2.new(1,0,0,80*GS); infoCard.BackgroundColor3=C.card
infoCard.BorderSizePixel=0; infoCard.ZIndex=11
Instance.new("UICorner",infoCard).CornerRadius=UDim.new(0,10*GS)
Instance.new("UIStroke",infoCard).Color=C.borderDim
local infoLbl=Instance.new("TextLabel",infoCard)
infoLbl.Size=UDim2.new(1,-16*GS,1,0); infoLbl.Position=UDim2.new(0,8*GS,0,0)
infoLbl.BackgroundTransparency=1; infoLbl.ZIndex=12
infoLbl.Text="[V] Speed  ·  [N] Spin  ·  [M] Galaxy\n[X] Aimbot  ·  [Q] Nuke  ·  [U] Hide\n[Z] Auto Left  ·  [C] Auto Right"
infoLbl.TextColor3=C.mutedWht; infoLbl.Font=Enum.Font.GothamMedium
infoLbl.TextSize=10*GS; infoLbl.TextWrapped=true; infoLbl.TextXAlignment=Enum.TextXAlignment.Left

mkSection(t4,"CREDITS")
local credCard=Instance.new("Frame",t4)
credCard.Size=UDim2.new(1,0,0,36*GS); credCard.BackgroundColor3=C.card
credCard.BorderSizePixel=0; credCard.ZIndex=11
Instance.new("UICorner",credCard).CornerRadius=UDim.new(0,10*GS)
Instance.new("UIStroke",credCard).Color=C.borderDim
local credLbl=Instance.new("TextLabel",credCard)
credLbl.Size=UDim2.new(1,0,1,0); credLbl.BackgroundTransparency=1; credLbl.ZIndex=12
credLbl.Text="Singularity Duels  ·  made by @fcaouss  ·  discord.gg/singularityhere"
credLbl.TextColor3=C.accentDim; credLbl.Font=Enum.Font.GothamBold; credLbl.TextSize=9*GS


--   INPUT
local guiVis=true

UIS.InputBegan:Connect(function(inp,gpe)
	if gpe then return end
	if waitKB and inp.KeyCode~=Enum.KeyCode.Unknown then
		KB[waitKB]=inp.KeyCode
		if KBtns[waitKB] then KBtns[waitKB].Text=inp.KeyCode.Name end
		waitKB=nil; return
	end
	if inp.KeyCode==Enum.KeyCode.U then
		guiVis=not guiVis; main.Visible=guiVis; return
	end
	if inp.KeyCode==Enum.KeyCode.Space then spaceDown=true end

	local map={
		[KB.SPEED]  = function() local s=not Enabled.Speed;  Enabled.Speed=s;  if VSetters.Speed  then VSetters.Speed(s)  end; if s then startSpeed()  else stopSpeed()  end end,
		[KB.SPIN]   = function() local s=not Enabled.Spin;   Enabled.Spin=s;   if VSetters.Spin   then VSetters.Spin(s)   end; if s then startSpin()   else stopSpin()   end end,
		[KB.GALAXY] = function() local s=not Enabled.Galaxy; Enabled.Galaxy=s; if VSetters.Galaxy then VSetters.Galaxy(s) end; if s then startGalaxy() else stopGalaxy() end end,
		[KB.AIMBOT] = function() local s=not Enabled.Aimbot; Enabled.Aimbot=s; if VSetters.Aimbot then VSetters.Aimbot(s) end; if s then startAimbot() else stopAimbot() end end,
		[KB.NUKE]   = function() nuke() end,
		[KB.LEFT]   = function()
			AutoLeft=not AutoLeft; Enabled.AutoLeft=AutoLeft
			if VSetters.AutoLeft then VSetters.AutoLeft(AutoLeft) end
			if AutoLeft then startLeft() else stopLeft() end
		end,
		[KB.RIGHT]  = function()
			AutoRight=not AutoRight; Enabled.AutoRight=AutoRight
			if VSetters.AutoRight then VSetters.AutoRight(AutoRight) end
			if AutoRight then startRight() else stopRight() end
		end,
	}
	if map[inp.KeyCode] then map[inp.KeyCode]() end
end)

UIS.InputEnded:Connect(function(inp)
	if inp.KeyCode==Enum.KeyCode.Space then spaceDown=false end
end)

-- Respawn
lp.CharacterAdded:Connect(function()
	task.wait(1)
	captureJumpPower()
	if Enabled.Spin    then stopSpin();    task.wait(0.1); startSpin()    end
	if Enabled.Galaxy  then setupGVF();    adjustJump()                   end
	if Enabled.SpamBat then stopSpam();    task.wait(0.1); startSpam()    end
	if Enabled.Aimbot  then stopAimbot();  task.wait(0.1); startAimbot()  end
	if Enabled.Unwalk  then startUnwalk()                                 end
	if Enabled.ESP     then
		task.wait(0.2)
		for _,p in ipairs(Players:GetPlayers()) do
			if p~=lp and p.Character then buildESP(p) end
		end
	end
end)

-- Delayed init from saved config
task.spawn(function()
	task.wait(3)
	local c=lp.Character
	if not c or not c:FindFirstChild("HumanoidRootPart") then
		c=lp.CharacterAdded:Wait(); task.wait(1)
	end
	for k,btn in pairs(KBtns) do if btn and KB[k] then btn.Text=KB[k].Name end end
	for k,s in pairs(VSetters) do if Enabled[k] then s(true,true) end end
	for k,s in pairs(SSetters) do if Val[k] then s(Val[k]) end end
	if Enabled.AntiRagdoll  then startAntiRag()     end
	if Enabled.Steal        then startSteal()        end
	if Enabled.StealSpeed   then startStealSpeed()   end
	if Enabled.Optimizer    then startOptimizer()    end
	if Enabled.SkyBright    then startSkyBright()    end
	if Enabled.AutoKick     then enableKick()        end
	if Enabled.ESP          then enableESP()         end
	task.wait(0.4)
	if Enabled.Speed        then startSpeed()        end
	if Enabled.Spin         then startSpin()         end
	if Enabled.SpamBat      then startSpam()         end
	if Enabled.Aimbot       then startAimbot()       end
	if Enabled.Galaxy       then startGalaxy()       end
	if Enabled.Unwalk       then startUnwalk()       end
	if Enabled.AutoLeft     then AutoLeft=true;  startLeft()  end
	if Enabled.AutoRight    then AutoRight=true; startRight() end
end)

print("[Singularity] loaded")
