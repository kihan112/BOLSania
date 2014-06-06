if myHero.charName ~= "Syndra" then return end

local version = 0.25
local AUTOUPDATE = false
local SCRIPT_NAME = "PentaKill_Syndra"
local ForceUseSimpleTS = false

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
	require("SourceLib")
else
	DOWNLOADING_SOURCELIB = true
	DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

if AUTOUPDATE then
	 SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/kihan112/BOLSania/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/kihan112/BOLSania/master/VersionFiles/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
RequireI:Add("Prodiction", "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/7f8427d943e993667acd4a51a39cf9aa2b71f222/Test/Prodiction/Prodiction.lua")
RequireI:Add("vPrediction", "https://raw.githubusercontent.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.githubusercontent.com/Hellsing/BoL/master/common/SOW.lua")
RequireI:Add("Selector", "https://raw.githubusercontent.com/pqmailer/BoL_Scripts/master/Paid/Selector.lua")
RequireI:Check()

if RequireI.downloadNeeded == true then return end
local Q = {range = 790, rangeSqr = math.pow(790, 2), width = 125, delay = 0.6, speed = math.huge, LastCastTime = 0, IsReady = function() return myHero:CanUseSpell(_Q) == READY end}
local W = {range = 925, rangeSqr = math.pow(925, 2), width = 190, delay = 0.8, speed = math.huge, LastCastTime = 0, IsReady = function() return myHero:CanUseSpell(_W) == READY end, status = 0}
local E = {range = 700, rangeSqr = math.pow(700, 2), width = 45 * 0.5, delay = 0.25, speed = 2500, LastCastTime = 0, IsReady = function() return myHero:CanUseSpell(_E) == READY end}
local R = {range = 675, rangeSqr = math.pow(675, 2), delay = 0.25, IsReady = function() return myHero:CanUseSpell(_R) == READY end}
local QE = {range = 1290, rangeSqr = math.pow(1290, 2), width = 60, delay = 0, speed = 1600}

local pets = {"annietibbers", "shacobox", "malzaharvoidling", "heimertyellow", "heimertblue", "yorickdecayedghoul"}

local Balls = {}
local BallDuration = 6.9

local QECombo = 0

local DontUseRTime = 0
local UseRTime = 0

local MainCombo = {ItemManager:GetItem("DFG"):GetId(), _W, _E, _R, _R, _R, _IGNITE}

function OnLoad()	
	VP = VPrediction()
	SOWi = SOW(VP)
	DLib = DamageLib()
	DManager = DrawManager()


	DLib:RegisterDamageSource(_Q, _MAGIC, 30, 40, _MAGIC, _AP, 0.60, function() return (player:CanUseSpell(_Q) == READY) end)--Without the 15% increase at rank 5
	DLib:RegisterDamageSource(_LV5Q, _MAGIC, 264.5, 0, _MAGIC, _AP, 0.69, function() return (player:CanUseSpell(_Q) == READY) end)--With the 15% increase at rank 5
	DLib:RegisterDamageSource(_W, _MAGIC, 40, 40, _MAGIC, _AP, 0.70, function() return (player:CanUseSpell(_W) == READY) end)
	DLib:RegisterDamageSource(_E, _MAGIC, 25, 45, _MAGIC, _AP, 0.4, function() return (player:CanUseSpell(_E) == READY) end)
	DLib:RegisterDamageSource(_R, _MAGIC, 45, 45, _MAGIC, _AP, 0.2, function() return (player:CanUseSpell(_R) == READY) end)--1 sphere

	Menu = scriptConfig("PentaKill Syndra by Sania", "PentaKill_Syndra")

	Menu:addSubMenu("Orbwalking", "Orbwalking")
		SOWi:LoadToMenu(Menu.Orbwalking)

	Menu:addSubMenu("Choose Target Selector", "SelectTS")
		Menu.SelectTS:addParam("TS", "Select TS (Require reload)", SCRIPT_PARAM_LIST, 1, {"Use SimpleTS", "Use Selector"})

	if (Menu.SelectTS.TS == 1) or ForceUseSimpleTS then
		STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
		Menu:addSubMenu("Set Target Selector Priority", "STS")
		STS:AddToMenu(Menu.STS)
	else
		Selector.Instance() 
	end


         
         Menu:addSubMenu("Choose Prediction Type", "SelectPred")
         Menu.SelectPred:addParam("predictionType", "Prediction Type", SCRIPT_PARAM_LIST, 2, { "VPrediction", "Prodiction" })




	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseEQ", "Use QE", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("Enabled", "Use Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("UseEQ", "Use QE", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Menu.Harass:addParam("Enabled2", "Harass (toggle)!", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))

	--Menu:addSubMenu("Farm", "Farm")
	--	Menu.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
	--	Menu.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
	--	Menu.Farm:addParam("UseE",  "Use E", SCRIPT_PARAM_LIST, 1, { "No", "Freeze", "LaneClear", "Both" })
	--	Menu.Farm:addParam("ManaCheck2", "Don't farm if mana < % (freeze)", SCRIPT_PARAM_SLICE, 0, 0, 100)
	--	Menu.Farm:addParam("ManaCheck", "Don't farm if mana < % (laneclear)", SCRIPT_PARAM_SLICE, 0, 0, 100)
	--	Menu.Farm:addParam("Freeze", "Farm freezing", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
	--	Menu.Farm:addParam("LaneClear", "Farm LaneClear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	--Menu:addSubMenu("JungleFarm", "JungleFarm")
	--	Menu.JungleFarm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, true)
	--	Menu.JungleFarm:addParam("UseW",  "Use W", SCRIPT_PARAM_ONOFF, true)
	--	Menu.JungleFarm:addParam("UseE",  "Use E", SCRIPT_PARAM_ONOFF, false)
	--	Menu.JungleFarm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("QE combo settings", "EQ")
		Menu.EQ:addParam("Range", "Place Q at range:", SCRIPT_PARAM_SLICE, E.range, 0, E.range)

	Menu:addSubMenu("Ultimate", "R")
		Menu.R:addSubMenu("Don't use R on", "Targets")
		for i, enemy in ipairs(GetEnemyHeroes()) do
			Menu.R.Targets:addParam(enemy.hash,  enemy.charName, SCRIPT_PARAM_ONOFF, false)
		end
		Menu.R:addParam("CastR", "Force ultimate cast", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("J"))
		Menu.R:addParam("DontUseR", "Don't use R in the next 10 seconds", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))

	Menu:addSubMenu("Misc", "Misc")
		Menu.Misc:addParam("WPet",  "Auto grab pets using W", SCRIPT_PARAM_ONOFF, true)

		Menu.Misc:addSubMenu("Auto-Interrupt", "Interrupt")
			Interrupter(Menu.Misc.Interrupt, OnInterruptSpell)

		Menu.Misc:addSubMenu("Anti-Gapclosers", "AG")
			AntiGapcloser(Menu.Misc.AG, OnGapclose)

		Menu.Misc:addParam("MEQ", "Manual Q+E Combo", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("T"))

	Menu:addSubMenu("Drawings", "Drawings")
		DManager:CreateCircle(myHero, SOWi:MyRange() + 50, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "AA Range", true, true, true)		
		DManager:CreateCircle(myHero, Q.range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, SpellToString(_Q).." Range", true, true, true)
		DManager:CreateCircle(myHero, W.range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, SpellToString(_W).." Range", true, true, true)
		DManager:CreateCircle(myHero, E.range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, SpellToString(_E).." Range", true, true, true)
		DManager:CreateCircle(myHero, R.range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, SpellToString(_R).." Range", true, true, true)
		DManager:CreateCircle(myHero, QE.range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "Q+E Range", true, true, true)
		
		
	--[[Predicted damage on healthbars]]
	DLib:AddToMenu(Menu.Drawings, MainCombo)

	EnemyMinions = minionManager(MINION_ENEMY, W.range, myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, QE.range, myHero, MINION_SORT_MAXHEALTH_DEC)
	PosiblePets = minionManager(MINION_OTHER, W.range, myHero, MINION_SORT_MAXHEALTH_DEC)
end

--Change the combo table depending on the situation.
function GetCombo(target)
	if target ~= nil then
		local result = {}
		for i, spell in ipairs(MainCombo) do
			if (spell == ItemManager:GetItem("DFG"):GetId()) and GetDistanceSqr(target.visionPos, myHero.visionPos) < math.pow(650, 2) then 
				table.insert(result, spell)
			elseif (spell == _IGNITE) and GetDistanceSqr(target.visionPos, myHero.visionPos) < math.pow(600, 2) then
				table.insert(result, spell)
			else
				table.insert(result, spell)
			end
		end
		if myHero:GetSpellData(_Q).level == 5 then
			table.insert(result, _LV5Q)
		else
			table.insert(result, _Q)
		end
		for i = 1, #GetValidBalls() do
			table.insert(result, _R)
		end
		return result		
	else
		local result = {}
		for i, spell in ipairs(MainCombo) do
			table.insert(result, spell)
		end
		if myHero:GetSpellData(_Q).level == 5 then
			table.insert(result, _LV5Q)
		else
			table.insert(result, _Q)
		end
		for i = 1, #GetValidBalls() do
			table.insert(result, _R)
		end
		return result
	end
end

-- Track the balls


function OnProcessSpell(unit, spell)
	if unit.isMe then
		if spell.name == "SyndraQ" then
			Q.LastCastTime = os.clock()
			OnCastQ(spell)
		elseif spell.name == "SyndraE" then	
			E.LastCastTime = os.clock()
		elseif spell.name == "SyndraW" then
			W.LastCastTime = os.clock()
		elseif spell.name == "syndrae5" then
			E.LastCastTime = os.clock()
		end
	end
end

--Track the balls :p
function GetValidBalls(ForE)
	if (ForE == nil) or (ForE == false) then
		local result = {}
		for i, ball in ipairs(Balls) do
			if (ball.added or ball.startT <= os.clock()) and Balls[i].endT >= os.clock() and ball.object.valid then
				if not WObject or ball.object.networkID ~= WObject.networkID then
					table.insert(result, ball)
				end
			end
		end
		return result
	else
		local result = {}
		for i, ball in ipairs(Balls) do
			if (ball.added or ball.startT <= os.clock() + (E.delay + GetDistance(myHero.visionPos, ball.object) / E.speed)) and Balls[i].endT >= os.clock() + (E.delay + GetDistance(myHero.visionPos, ball.object) / E.speed) and ball.object.valid then
				if not WObject or ball.object.networkID ~= WObject.networkID then
					table.insert(result, ball)
				end
			end
		end
		return result
	end
end

function AddBall(obj)
	for i = #Balls, 1, -1 do
		if not Balls[i].added and GetDistanceSqr(Balls[i].object, obj) < 50*50 then
			Balls[i].added = true
			Balls[i].object = obj
			do return end
		end
	end

	--R balls
	local BallInfo = {
							 added = true, 
							 object = obj,
							 startT = os.clock(),
							 endT = os.clock() + BallDuration - GetLatency()/2000
					}
	table.insert(Balls, BallInfo)						
end

function OnCreateObj(obj)
	if obj and obj.valid then
		if GetDistanceSqr(obj) < Q.rangeSqr * 2 then
			if obj.name:find("Seed") then
				DelayAction(AddBall, 0, {obj})
			end
		end
	end
end

function OnDeleteObj(obj)
	if obj.name:find("Syndra_") and (obj.name:find("_Q_idle.troy") or obj.name:find("_Q_Lv5_idle.troy")) then
		for i = #Balls, 1, -1 do
			if Balls[i].object and Balls[i].object.valid and GetDistanceSqr(Balls[i].object, obj) < 50 * 50 then
				table.remove(Balls, i)
				break
			end
		end
	end
end

--Remove the non-active balls to save memory
function BTOnTick()
	for i = #Balls, 1, -1 do
		if Balls[i].endT <= os.clock() then
			table.remove(Balls, i)
		end
	end
end

function BTOnDraw()--For testings
	local activeballs = GetValidBalls()
	for i, ball in ipairs(activeballs) do
		DrawCircle(ball.object.x, myHero.y, ball.object.z, 100, ARGB(255,255,255,255))
	end
end

function IsPet(name) 
	return table.contains(pets, name:lower())
end

function IsPetDangerous(name)
	return (name:lower() == "annietibbers") or (name:lower() == "heimertblue")
end

function AutoGrabPets()
	if W.IsReady() and W.status == 0 then
		local pet = GetPet(true)
		if pet then
			CastSpell(_W, pet.x, pet.z)
		end
	end
end

function GetPet(dangerous)
	PosiblePets:update()
	--Priorize Enemy Pet's
	for i, object in ipairs(PosiblePets.objects) do
		if object and object.valid and object.team ~= myHero.team and IsPet(object.charName) and (not dangerous or IsPetDangerous(object.charName)) then
			return object
		end
	end
end

function GetWValidBall(OnlyBalls)
	local all = GetValidBalls()
	local inrange = {}

	local Pet = GetPet(true)
	if Pet then
		return {object = Pet}
	end

	--Get the balls in W range
	for i, ball in ipairs(all) do
		if GetDistanceSqr(ball.object, myHero.visionPos) <= W.rangeSqr then
			table.insert(inrange, ball)
		end
	end

	local minEnd = math.huge
	local minBall

	--Get the ball that will expire earlier
	for i, ball in ipairs(inrange) do
		if ball.endT < minEnd then
			minBall = ball
			minEnd = ball.endT
		end
	end

	if minBall then
		return minBall
	end
	if OnlyBalls then 
		return 
	end

	Pet = GetPet()
	if Pet then
		return {object = Pet}
	end

	EnemyMinions:update()
	JungleMinions:update()
	PosiblePets:update()
	local t = MergeTables(MergeTables(EnemyMinions.objects, JungleMinions.objects), PosiblePets.objects)
	SelectUnits(t, function(t) return ValidTarget(t) and GetDistanceSqr(myHero.visionPos, t) < W.rangeSqr end)
	if t[1] then
		return {object = t[1]}
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



function OnInterruptSpell(unit, spell)
	if GetDistanceSqr(unit.visionPos, myHero.visionPos) < E.rangeSqr and E.IsReady() then
		
		if Q.IsReady() then
			StartEQCombo(unit)
		else
			CastSpell(_E, unit.visionPos.x, unit.visionPos.z)
		end

	elseif GetDistanceSqr(unit.visionPos,  myHero.visionPos) < QE.rangeSqr and Q.IsReady() and E.IsReady() then
		StartEQCombo(unit)
	end 
end

function OnGapclose(unit, data)
	if GetDistanceSqr(unit.visionPos, myHero.visionPos) < E.rangeSqr and E.IsReady() then
		
		if Q.IsReady() then
			Qdistance = 300
			StartEQCombo(unit)
		else
			CastSpell(_E, unit.visionPos.x, unit.visionPos.z)
		end

	elseif GetDistanceSqr(unit.visionPos,  myHero.visionPos) < QE.rangeSqr and Q.IsReady() and E.IsReady() then
		StartEQCombo(unit)
	end 
end

function OnRecvPacket(p)
	if p.header == 112 then
		p.pos = 1
		local NetworkID = p:DecodeF()
		local Active = p:Decode1()

		if NetworkID and Active == 1 then
			if not WObject then
				for i, ball in ipairs(Balls) do
					if ball.networkID == NetworkID then
						Balls[i].endT = os.clock() + BallDuration - GetLatency()/2000
					end
				end
			end
			WObject = objManager:GetObjectByNetworkId(NetworkID)
		else
			WObject = nil
		end
	end
end

function OnCastQ(spell)
	local BallInfo = {
						added = false, 
						object = {valid = true, x = spell.endPos.x, y = myHero.y, z = spell.endPos.z},
						startT = os.clock() + Q.delay - GetLatency()/2000,
						endT = os.clock() + BallDuration + Q.delay - GetLatency()/2000
					 }
	if (os.clock() - QECombo < 1.5) or (Menu.Combo.Enabled and (Menu.Combo.UseE or Menu.Combo.UseEQ)) or (Menu.Harass.Enabled and (Menu.Harass.UseE or Menu.Harass.UseEQ)) then
		local Delay = Q.delay - (E.delay + GetDistance(myHero.visionPos, BallInfo.object) / E.speed)
		DelayAction(function(t) CastQE2(t) end, Delay, {BallInfo})
	else
		Qdistance = nil
		EQTarget = nil
		EQCombo = 0
	end
	table.insert(Balls, BallInfo)
end

function CastQE2(BallInfo)
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			if GetDistanceSqr(BallInfo.object, myHero.visionPos) < E.rangeSqr then

				enemyPos = nil
				if Menu.SelectPred.predictionType == 1 then
					tmp1, tmp2, enemyPos = VP:GetPredictedPos(enemy, (E.delay + (GetDistance(myHero.visionPos, BallInfo.object) / E.speed) - (GetDistance(myHero.visionPos, BallInfo.object) / QE.speed)), QE.speed, myHero.visionPos, false)
				else
					enemyPos, info = Prodiction.GetPrediction(enemy, QE.range, QE.speed, (E.delay + (GetDistance(myHero.visionPos, BallInfo.object) / E.speed) - (GetDistance(myHero.visionPos, BallInfo.object) / QE.speed)), QE.width)
				end		

				if enemyPos and enemyPos.z then		
					local EP = Vector(BallInfo.object) +  (100+(-0.6 * GetDistance(BallInfo.object, myHero.visionPos) + 966)) * (Vector(BallInfo.object) - Vector(myHero.visionPos)):normalized()
					local SP = Vector(BallInfo.object) - 100 * (Vector(BallInfo.object) - Vector(myHero.visionPos)):normalized()
					local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(SP, EP, enemyPos)
					if isOnSegment and GetDistanceSqr(pointLine, enemyPos) <= (QE.width + VP:GetHitBox(enemy))^2 then
						if (E.delay + GetDistance(myHero.visionPos, BallInfo.object) / E.speed) >= (BallInfo.startT - os.clock()) then
							CastSpell(_E, BallInfo.object.x, BallInfo.object.z)
						else
							DelayAction(function(t) CastQE3(t) end, BallInfo.startT - os.clock() - (E.delay + GetDistance(myHero.visionPos, BallInfo.object) / E.speed), {BallInfo})	
						end				
					end
				end
			end
		end
	end
end


function CastQE3(BallInfo)
	if (E.delay + GetDistance(myHero.visionPos, BallInfo.object) / E.speed) >= (BallInfo.startT - os.clock()) then
		if GetDistanceSqr(BallInfo.object, myHero.visionPos) < E.rangeSqr then
			CastSpell(_E, BallInfo.object.x, BallInfo.object.z)
		end
	else
		DelayAction(function(t) CastQE3(t) end, BallInfo.startT - os.clock() - (E.delay + GetDistance(myHero.visionPos, BallInfo.object) / E.speed), {BallInfo})	
	end				
end


function StartEQCombo(unit)
	QECombo = os.clock()
	Cast2Q(unit)
end

function Cast2Q(target)
	if not Q.IsReady() then return end
	if GetDistanceSqr(target) > Q.rangeSqr then
		QEtargetPos = nil
		Position = nil
		if Menu.SelectPred.predictionType == 1 then
			QEtargetPos, Hitchance, Position = VP:GetLineCastPosition(target, 0.6 - (Menu.EQ.Range / QE.speed), QE.width, QE.range, QE.speed)
		else
			QEtargetPos, info = Prodiction.GetPrediction(target, QE.range, QE.speed, 0.6 - (Menu.EQ.Range / QE.speed), QE.width)
		end
		if QEtargetPos and QEtargetPos.z then 
			local pos = Vector(myHero.visionPos) + Menu.EQ.Range * (Vector(QEtargetPos) - Vector(myHero.visionPos)):normalized()
			CastSpell(_Q, pos.x, pos.z)
		end
	else
		if Qdistance then
			QEtargetPos = nil
			Position = nil
			if Menu.SelectPred.predictionType == 1 then
				QEtargetPos, Hitchance, Position = VP:GetLineCastPosition(target, 0.6 - (Qdistance / QE.speed), QE.width, QE.range, QE.speed)
			else
				QEtargetPos, info = Prodiction.GetPrediction(target, QE.range, QE.speed, 0.6 - (Qdistance / QE.speed), QE.width)
			end
			if QEtargetPos and QEtargetPos.z then 
				local pos = Vector(myHero.visionPos) + Qdistance * (Vector(QEtargetPos) - Vector(myHero.visionPos)):normalized()
				CastSpell(_Q, pos.x, pos.z)
			end
		else
			pos = nil
			if Menu.SelectPred.predictionType == 1 then
				VP.ShotAtMaxRange = true
				pos, hitChance, nTargets = VP:GetCircularAOECastPosition(target, Q.delay, Q.width, Q.range, Q.speed)
				VP.ShotAtMaxRange = false
			else
				pos, info = Prodiction.GetPrediction(target, Q.range, Q.speed, Q.delay, Q.width)
			end
			if pos and pos.z then
				CastSpell(_Q, pos.x, pos.z)
			end
		end
	end
end

function UseSpells(UseQ, UseW, UseE, UseEQ, UseR)

	local Qtarget
	local QEtarget
	local Rtarget

	if STS == nil then
		Qtarget = Selector.GetTarget(SelectorMenu.Get().mode, 'AP', {distance = W.range})
		QEtarget = Selector.GetTarget(SelectorMenu.Get().mode, 'AP', {distance = QE.range})
		Rtarget = Selector.GetTarget(SelectorMenu.Get().mode, 'AP', {distance = R.range})
	else
		Qtarget = STS:GetTarget(W.range)
		QEtarget = STS:GetTarget(QE.range)
		Rtarget = STS:GetTarget(R.range)
	end 

	local DFGUsed = false

	if (os.clock() - DontUseRTime < 10) then
		UseR = false
	end

	if UseW and W.IsReady() then
		if Qtarget and W.status == 1 and (os.clock() - Q.LastCastTime > 0.25) and (os.clock() - E.LastCastTime > 0.25) then
			if WObject.charName == nil or WObject.charName:lower() ~= "heimertblue" then 
				pos = nil
				if Menu.SelectPred.predictionType == 1 then
					VP.ShotAtMaxRange = true
					pos, hitChance, nTargets = VP:GetCircularAOECastPosition(Qtarget, W.delay, W.width, W.range, W.speed)
					VP.ShotAtMaxRange = false
				else
					pos, info = Prodiction.GetPrediction(Qtarget, W.range, W.speed, W.delay, W.width)
				end
				
				if pos and pos.z then
					CastSpell(_W, pos.x, pos.z)
				end
			end
		elseif Qtarget and W.status == 0 and (os.clock() - E.LastCastTime > 0.7) and (os.clock() - Q.LastCastTime > 0.7) then
			local validball = GetWValidBall()
			if validball then
				CastSpell(_W, validball.object.x, validball.object.z)
			end
		end
	end

	if UseQ and Q.IsReady() then
		if Qtarget and os.clock() - W.LastCastTime > 0.25 and os.clock() - E.LastCastTime > 0.25 then
			pos = nil
			if Menu.SelectPred.predictionType == 1 then
				VP.ShotAtMaxRange = true
				pos, hitChance, nTargets = VP:GetCircularAOECastPosition(Qtarget, Q.delay, Q.width, Q.range, Q.speed)
				VP.ShotAtMaxRange = false
			else
				pos, info = Prodiction.GetPrediction(Qtarget, Q.range, Q.speed, Q.delay, Q.width)
			end
			if pos and pos.z then
				CastSpell(_Q, pos.x, pos.z)
			end
		end
	end


	if UseEQ then
		if not Qtarget and QEtarget and E.IsReady() and Q.IsReady() then
			StartEQCombo(QEtarget)
		end
	end


	if UseE and E.IsReady() then
		--Check to stun people with E
		local validballs = GetValidBalls(true)
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				enemyPos = nil
				if Menu.SelectPred.predictionType == 1 then
					tmp1, tmp2, enemyPos = VP:GetPredictedPos(enemy, 0.25, QE.speed, myHero.visionPos, false)
				else
					enemyPos, info = Prodiction.GetPrediction(enemy, math.huge, QE.speed, 0.25)
				end			
				if enemyPos and enemyPos.z then
					for i, ball in ipairs(validballs) do
						if GetDistanceSqr(ball.object, myHero.visionPos) < E.rangeSqr then
							local EP = Vector(ball.object) +  (100+(-0.6 * GetDistance(ball.object, myHero.visionPos) + 966)) * (Vector(ball.object) - Vector(myHero.visionPos)):normalized()
							local SP = Vector(ball.object) - 100 * (Vector(ball.object) - Vector(myHero.visionPos)):normalized()
							local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(SP, EP, enemyPos)
							if isOnSegment and GetDistanceSqr(pointLine, enemyPos) <= (QE.width + VP:GetHitBox(enemy))^2 then
								CastSpell(_E, ball.object.x, ball.object.z)
							end
						end
					end
				end
			end
		end
	end


	if not Q.IsReady() and not W.IsReady() then
		if (((Qtarget and not Menu.R.Targets[Qtarget.hash]) or (Rtarget and not Menu.R.Targets[Rtarget.hash])) or (os.clock() - UseRTime < 10)) and UseR then
			if Qtarget and GetDistanceSqr(Qtarget.visionPos, myHero.visionPos) < R.rangeSqr and DLib:IsKillable(Qtarget, GetCombo(Qtarget)) and not DLib:IsKillable(Qtarget, {_Q, _E, _W}) then
				ItemManager:CastOffensiveItems(Qtarget)
				if _IGNITE and GetDistanceSqr(Qtarget.visionPos, myHero.visionPos) < 600 * 600 then
					CastSpell(_IGNITE, Qtarget)
				end
				CastSpell(_R, Qtarget)
			elseif Rtarget and GetDistanceSqr(Rtarget.visionPos, myHero.visionPos) < R.rangeSqr and DLib:IsKillable(Rtarget, GetCombo(Rtarget)) and not DLib:IsKillable(Rtarget, {_Q, _E, _W}) then
				ItemManager:CastOffensiveItems(Rtarget)
				if _IGNITE and GetDistanceSqr(Rtarget.visionPos, myHero.visionPos) < 600 * 600 then
					CastSpell(_IGNITE, Rtarget)
				end
				CastSpell(_R, Rtarget)
			end
		end
	end
end



function UpdateSpellData()
	if E.width ~= 2 * E.width and myHero:GetSpellData(_E).level == 5 then
		E.width = 2 * E.width
	end

	if R.range ~= (750) and myHero:GetSpellData(_R).level  == 3 then
		R.range = 750
		R.rangeSqr = math.pow(750, 2)
	end

	W.status = WObject and 1 or 0
end

function Combo()
	SOWi:DisableAttacks()
	if not Q.IsReady() and not W.IsReady() and not E.IsReady() then
		SOWi:EnableAttacks()
	end
	UseSpells(Menu.Combo.UseQ, Menu.Combo.UseW, Menu.Combo.UseE, Menu.Combo.UseEQ, Menu.Combo.UseR)
end

function Harass()
	if Menu.Harass.ManaCheck > (myHero.mana / myHero.maxMana) * 100 then return end
	UseSpells(Menu.Harass.UseQ, Menu.Harass.UseW, Menu.Harass.UseE, Menu.Harass.UseEQ, false)
end

function OnTick()
	if Prodiction == nil then
		Menu.SelectPred.predictionType = 1
	end
	DLib.combo = GetCombo()
	DrawJungleStealingIndicator = false
	BTOnTick()
	SOWi:EnableAttacks()
	UpdateSpellData()--update the spells data
	DrawEQIndicators = false
	
	if Menu.Combo.Enabled then
		Combo()
	elseif Menu.Harass.Enabled or Menu.Harass.Enabled2 then
		Harass()
	end

	--if Menu.Farm.LaneClear or Menu.Farm.Freeze then
	--	Farm()
	--end

	--if Menu.JungleFarm.Enabled then
	--	JungleFarm()
	--end

	if Menu.Misc.WPet then
		AutoGrabPets()
	end

	if Menu.R.DontUseR then
		DontUseRTime = os.clock()
		UseRTime = 0
	end

	if Menu.R.CastR then
		UseRTime = os.clock()
		DontUseRTime = 0
	end

	if Menu.Misc.MEQ and Q.IsReady() and E.IsReady() then
		DrawEQIndicators = true
		local PosibleTargets = GetEnemyHeroes()
		local ClosestTargetMouse 
		local closestdist = 200 * 200
		for i, target in ipairs(PosibleTargets) do
			local dist = GetDistanceSqr(mousePos, target)
			if ValidTarget(target) and dist < closestdist then
				ClosestTargetMouse = target
				closestdist = dist
			end
		end
		if ClosestTargetMouse and GetDistanceSqr(ClosestTargetMouse, myHero.visionPos) < (QE.range + 300)^2 then
			if GetDistanceSqr(ClosestTargetMouse) < Q.rangeSqr then
				StartEQCombo(ClosestTargetMouse, true)
			else
				StartEQCombo(ClosestTargetMouse)
			end
		end
	end
end

function GetDistanceToClosestHero(p)
	local result = math.huge
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			result = math.min(result, GetDistanceSqr(p, enemy))
		end
	end
	return result
end

myHero.barData = {PercentageOffset = {x = 0, y = 0}}

function OnDraw()
	if DrawEQIndicators then
		DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, 200, 3, GetDistanceToClosestHero(mousePos) < 200 * 200 and ARGB(200, 255, 0, 0) or ARGB(200, 0, 255, 0), 20)--sorry for colorblind people D:
	end

	if GetTarget() and GetTarget().type == 'obj_AI_Minion' and GetTarget().team == TEAM_NEUTRAL then
		DrawCircle3D(GetTarget().x, GetTarget().y, GetTarget().z, 100, 2, Menu.JungleFarm.Enabled and ARGB(175, 255, 0, 0) or ARGB(175, 0, 255, 0), 25) --sorry for colorblind people D:
	end

	if DrawJungleStealingIndicator then
		local pos = GetEnemyHPBarPos(myHero) + Vector(20, -4)
		pos.x = math.floor(pos.x)
		pos.y = math.floor(pos.y)

		DrawText(tostring("JungleStealing"), 16, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
		DrawText(tostring("JungleStealing"), 16, pos.x, pos.y, ARGB(255, 255, 255, 255))
	end

	if Menu.Harass.Enabled2 then
		local pos = GetEnemyHPBarPos(myHero) + Vector(0, -4)
		pos.x = math.floor(pos.x)
		pos.y = math.floor(pos.y)

		DrawText(tostring("AH"), 16, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
		DrawText(tostring("AH"), 16, pos.x, pos.y, ARGB(255, 255, 255, 255))
	end
end