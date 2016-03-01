if not myHero then
	myHero = GetMyHero()
end
if myHero.charName ~= "Teemo" then return end

local ScriptVersion = 0.1
local ScriptVersionDisp = "0.1"
local ScriptUpdate = "01.03.2016"
local SupportedVersion = "6.4HF"
local target = nil
local jungleMinions = minionManager(MINION_JUNGLE, 350, myHero)
local enemyMinions = minionManager(MINION_ENEMY, 350, myHero)
local LastCastingPacket = ""



function toHex(int)
  return "0x"..string.format("%04X",int)
end

function print_msg(msg)
  if msg ~= nil then
    msg = tostring(msg)
    print("<font color=\"#79E886\"><b>[Teemo the Cancer God]</b></font> <font color=\"#FFFFFF\">".. msg .."</font>")
  end
end

function LoadSimpleLib()
  if FileExist(LIB_PATH .. "/SimpleLib.lua") then
    require("SimpleLib")
    return true
  else
    print_msg("Downloading SimpleLib, please don't press F9")
    DelayAction(function() DownloadFile("https://raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua".."?rand="..math.random(1,10000), LIB_PATH.."SimpleLib.lua", function () print_msg("Successfully downloaded SimpleLib. Press F9 twice.") end) end, 3) 
    return false
  end
end

function LoadSLK()
  if FileExist(LIB_PATH .. "/SourceLibk.lua") then
    require("SourceLibk")
    return true
  else
    print_msg("Downloading SourceLibk, please don't press F9")
    DelayAction(function() DownloadFile("https://raw.githubusercontent.com/kej1191/anonym/master/Common/SourceLibk.lua".."?rand="..math.random(1,10000), LIB_PATH.."SourceLibk.lua", function () print_msg("Successfully downloaded SourceLibk. Press F9 twice.") end) end, 3) 
    return false
  end
end

-- [Script Function] --


function OnLoad()

	--Check SLK
	if LoadSLK then

		--Check SimpleLib
		if LoadSimpleLib() then

			--Update with SimpleLib
			local UpdateInfo= {}
			UpdateInfo.LocalVersion = ScriptVersion
			UpdateInfo.VersionPath = ""
			UpdateInfo.ScriptPath = ""
			UpdateInfo.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
			UpdateInfo.CallbackUpdate = function(NewVersion, OldVersion) print_msg("Updated to v".. NewVersion ..". Press F9x2!") end
      		UpdateInfo.CallbackNoUpdate = LoadScript()
     		UpdateInfo.CallbackNewVersion = function(NewVersion) print_msg("New version found. Don't press F9.") end
      		UpdateInfo.CallbackError = function(NewVersion) print_msg("Error to download new version. Please try again.") end
      		_ScriptUpdate(UpdateInfo)
    	end
    end
end
function LoadScript()
	CT = CancerTeemo()
	_G.CancerTeemo = true
	DelayAction(function() print_msg("Lastset version (v".. ScriptVersion ..") loaded!") end, 2)
end



--[Main Class] --

class "CancerTeemo"

function CancerTeemo__init()
	self:Config()
end

-- Config , Menu ect
function CancerTeemo:Config()

	-- Set Spells with SimpleLib
	self.Spell_Q = _Spell({Slot = _Q, DamageName = "Q", Range = 580, Delay = 0.125, Aoe= false, Type = SPELL_TYPE.TARGETTED})
	self.Spell_Q:AddDraw({Enable = true, Color = {255,0,125,255}})

	self.Spell_W = _Spell({Slot = _W, DamageName = "W", Type = SPELL_TYPE.SELF})

	--self.Spell_R = _Spell({Slot = _R, DamageName = "R", Range = 400 Type = SPELL_TYPE.CONE})

	-- Make Menu
	self.cfg = scriptConfig("Cancer Teemo","cancer_teemo")

	--Target Selector With SLK
	self.STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
  	self.cfg:addSubMenu("Target Selector", "ts")
  	self.STS:AddToMenu(self.cfg.ts)

  	--Combo Menu
  	self.cfg:addSubMenu("Combo","combo")
  		self.cfg.combo:addParam("useq","Use Q ", SCRIPT_PARAM_ONOFF, true)
  		self.cfg.combo:addParam("user","Use R ", SCRIPT_PARAM_ONOFF, true)
  	--Harass
  	self.cfg:addSubMenu("Harass Settings","harass")
  		self.cfg.harass:addParam("harq","Use Q ", SCRIPT_PARAM_ONOFF, true)

  	--Lane & JungleCLear
  	self.cfg:addSubMenu("Clear Settings","clear")
  		self.cfg.clear:addParam("info1","---- Lane Clear ----", SCRIPT_PARAM_INFO,"")
  		self.cfg.clear:addParam("laneR","Use R in LaneClear", SCRIPT_PARAM_ONOFF, false)
  		self.cfg.clear:addParam("lanecount","Min Minions for R", SCRIPT_PARAM_SLICE,6,3,10)
  		self.cfg.clear:addParam("info","", SCRIPT_PARAM_INFO,"")
  		self.cfg.clear:addParam("info3","---- Jungle Clear ----",SCRIPT_PARAM_INFO,"")
  		self.cfg.clear:addParam("jungleq", "Use Q",SCRIPT_PARAM_ONOFF,true)
  		self.cfg.clear.addParam("Jungleqmana", "Q Mana ",SCRIPT_PARAM_SLICE,0,0,100)

  	self.cfg:addSubMenu("Lasthit Settings", "lasthit")
  		self.cfg.lasthit:addParam("smartq","Use Smart Lasthit Q",SCRIPT_PARAM_ONOFF,true)
  		self.cfg.lasthit:addParam("smartqmana", "Q Mana", SCRIPT_PARAM_SLICE, 0 ,0,100)

  	--Draw Menu
  	self.cfg:addSubMenu("Draw Settings","draw")
  		self.cfg.draw:addParam("info1","What do u want to Draw",SCRIPT_PARAM_INFO,"")


  	--Key Menu with Simple Lib
  	self.cfg:addSubMenu("Key Settings","key")
  		OrbwalkManager:LoadCommonKeys(self.cfg.key)
  		self.cfg.key:addParam("info1","----Other Keys ----",SCRIPT_PARAM_INFO,"")
  		self.cfg.key:addParam("flee","Flee Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))

  	--ETC
  	self.cfg:addSubMenu("Msic Settings","msic")
  		self.cfg:addSubMenu("checkrdistance","Check Hero R Distance", SCRIPT_PARAM_SLICE, 350, 200,900)
  		self.cfg:addParam("info1","Only Take 400+ Range at Shroom Lvl 2",SCRIPT_PARAM_INFO,"")
  		self.cfg:addParam("info2","Only Take 650+ Range at Shrrom Lvl 3",SCRIPT_PARAM_INFO,"")

  	--Info
  	self.cfg:addParam("info1","",SCRIPT_PARAM_INFO,"")
  	self.cfg:addParam("info2", "Script Version", SCRIPT_PARAM_INFO, ScriptVersionDisp)
  	self.cfg:addParam("info3","Last Update",SCRIPT_PARAM_INFO,ScriptUpdate)
  	self.cfg:addParam("info4","Last Tested LoL Version", SCRIPT_PARAM_INFO,SupportedVersion)
  	self.cfg.addParam("info5","",SCRIPT_PARAM_INFO,"")
  	self.cfg.addParam("info6","Script developed by NoSupportNeeded",SCRIPT_PARAM_INFO,"")

  	
  	-- Set CallBack.
  	AddDrawCallback(function() self:Draw() end)
  	AddTickCallback(function() self:Tick() end)
  	AddCastSpellCallback(function(iSpell, startPos, endPos, target) self:OnCastSpell(iSpell, startPos, endPos, target) end)
end

function CancerTeemo:Draw
	-- If dead, disable everything.
	if myHero.dead then
    	return
	end

end

function CancerTeemo:Tick()

	-- If dead, disable everything.
	if myHero.dead then
		return
	end

	--Update
	target = self.STS:GetTarget(1600)

	--Combo Logic
	if OrbwalkManager:IsCombo() then
		self:Combo()
	end

	--Harass
	if OrbwalkManager:IsHarass() then
		self:Harass()
	end
	-- Clear
	if OrbwalkManager:IsClear() then
		self:Clear()
	end

	--Lasthit
	if OrbwalkManager:IsLasthit() then
		self:Lasthit()
	end

end

function CancerTeemo:Combo()
	if self.cfg.combo.useq and self.Spell_Q:IsReady() then
		self.Spell_Q:Cast(target)
	end

function CancerTeemo:Harass()
	if self.cfg.combo.harq and self.Spell_Q:IsReady() then
		self.Spell_Q:Cast(target)
	end

function CancerTeemo:Clear()
	--Get Minion
	local minion = self.GetMinionR()
	local jungle = self.GetJungleR()

	--Lance Clear
	if minion >= self.cfg.clear.lanecount then
		--R
		if self.cfg.clear.laneR and self.Spell_R:IsReady then

		end

	if self.cfg.clear.jungleq and self.Spell_Q:IsReady then 
		CastSpell(_Q, mousePos.x,mousePos.y)

end

function CancerTeemo:Lasthit()
	if not self.cfg.lasthit.smartq then return end

	local lasthit_target = self.Spell_Q:Lasthit()

	if lasthit target and self:CheckMana(self.cfg.lasthit.smartqmana) then
		self.Spell_Q:Cast(lasthit_target)
	end
end

function CancerTeemo:CheckMana(mana)
	-- body
	if not mana then mana = 100 end

	if myHero.mana / myHero.maxMana > /100 then
		return true
	else
		return false
	end
end


