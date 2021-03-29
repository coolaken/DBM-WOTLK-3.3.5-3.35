local mod	= DBM:NewMod("Sindragosa", "DBM-Icecrown", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4512 $"):sub(12, -3))
mod:SetCreatureID(36853)
--mod:RegisterCombat("combat")
mod:RegisterCombat("yell", L.YellPull)
mod:SetMinSyncRevision(3712)
mod:SetUsedIcons(3, 4, 5, 6, 7, 8)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_AURA_REMOVED",
	"SPELL_CAST_SUCCESS",
	"UNIT_HEALTH",
	"CHAT_MSG_MONSTER_YELL"
)

local warnAirphase				= mod:NewAnnounce("WarnAirphase", 2, 43810)
local warnGroundphaseSoon		= mod:NewAnnounce("WarnGroundphaseSoon", 2, 43810)
local warnPhase2soon			= mod:NewAnnounce("WarnPhase2soon", 1)
local warnPhase2				= mod:NewPhaseAnnounce(2, 2)
local warnInstability			= mod:NewAnnounce("WarnInstability", 2, 69766, false)
local warnChilledtotheBone		= mod:NewAnnounce("WarnChilledtotheBone", 2, 70106, false)
local warnMysticBuffet			= mod:NewAnnounce("WarnMysticBuffet", 2, 70128, false)
local warnBlisteringCold		= mod:NewSpellAnnounce(70123, 3)
local warnFrostBreath			= mod:NewSpellAnnounce(71056, 2, nil, "Tank|Healer")

local warnFrostBeacon			= mod:NewTargetNoFilterAnnounce(70126, 4)
local warnUnchainedMagic		= mod:NewTargetNoFilterAnnounce(69762, 2, nil, "-Melee")

local specWarnUnchainedMagic	= mod:NewSpecialWarningYou(69762, nil, nil, nil, 4, 2)
local specWarnFrostBeacon		= mod:NewSpecialWarningMoveAway(70126, nil, nil, nil, 1, 2)
local specWarnInstability		= mod:NewSpecialWarningStack(69766, nil, 4, nil, nil, 1, 2)
local specWarnChilledtotheBone	= mod:NewSpecialWarningStack(70106, nil, 4, nil, nil, 1, 2)
local specWarnMysticBuffet		= mod:NewSpecialWarningStack(70128, false, 5)
local specWarnBlisteringCold	= mod:NewSpecialWarningRun(70123, nil, nil, nil, 1, 2)


local timerNextAirphase			= mod:NewTimer(110, "TimerNextAirphase", 43810, nil, nil, 6)
local timerNextGroundphase		= mod:NewTimer(45, "TimerNextGroundphase", 43810, nil, nil, 6)
local timerNextFrostBreath		= mod:NewNextTimer(22, 71056, nil, "Tank|Healer", nil, 2, nil, DBM_CORE_L.TANK_ICON)
local timerNextBlisteringCold	= mod:NewCDTimer(67, 70123, nil, nil, nil, 2, nil, DBM_CORE_L.DEADLY_ICON)
local timerNextBeacon			= mod:NewCDCountTimer(20, 70126, nil, nil, nil, 1, nil, DBM_CORE_L.IMPORTANT_ICON)               --NewNextTimer(20, 70126, nil, nil, nil, 1)
local timerBlisteringCold		= mod:NewCastTimer(6, 70123, nil, nil, nil, 2, nil, DBM_CORE_L.DEADLY_ICON)
local timerUnchainedMagic		= mod:NewBuffActiveTimer(30, 69762, nil, nil, nil, 3)
local timerInstability			= mod:NewBuffActiveTimer(5, 69766, nil, nil, nil, 3)
local timerChilledtotheBone		= mod:NewBuffActiveTimer(8, 70106, nil, nil, nil, 3)
local timerMysticBuffet			= mod:NewBuffActiveTimer(8, 70128, nil, nil, nil, 2)
local timerNextMysticBuffet		= mod:NewNextTimer(6, 70128, nil, nil, nil, 2)
local timerMysticAchieve		= mod:NewAchievementTimer(30, 4620)



local berserkTimer				= mod:NewBerserkTimer(600)
local isPAL = select(2, UnitClass("player")) == "PALADIN"

mod:AddBoolOption("SetIconOnFrostBeacon", true)
mod:AddBoolOption("SetIconOnUnchainedMagic", true)
mod:AddBoolOption("ClearIconsOnAirphase", true)
mod:AddBoolOption("AnnounceFrostBeaconIcons", false)
mod:AddBoolOption("AchievementCheck", false, "announce")
mod:AddBoolOption("YellOnBeacon")
mod:AddBoolOption("YellOnBeaconPlanB", false)
mod:AddBoolOption("RangeFrame")

local beaconTargets		= {}
local beaconIconTargets	= {}
local unchainedTargets	= {}
local warned_P2 = false
local warnedfailed = false
local unchainedIcons = 7
local spamBeaconIcon = 0
local activeBeacons	= false
local beaconIcons = 0
local beaconCount = 0
local FrostBeaconIndex = 0

mod.vb.phase = 0

local function ClearBeaconTargets()
	table.wipe(beaconIconTargets)
end

do
	local function sort_by_group(v1, v2)
		return DBM:GetRaidSubgroup(UnitName(v1)) < DBM:GetRaidSubgroup(UnitName(v2))
	end
	function mod:SetBeaconIcons()
		if DBM:GetRaidRank() > 0 then
			table.sort(beaconIconTargets, sort_by_group)
			local beaconIcons = 8
			for i, v in ipairs(beaconIconTargets) do
				if self.Options.AnnounceFrostBeaconIcons then
					SendChatMessage(L.BeaconIconSet:format(beaconIcons, UnitName(v)), "RAID")
				end
				self:SetIcon(UnitName(v), beaconIcons)
				beaconIcons = beaconIcons - 1
			end
			self:Schedule(5, ClearBeaconTargets)
		end
	end
end

local function warnBeaconTargets()
	warnFrostBeacon:Show(table.concat(beaconTargets, "<, >"))
	table.wipe(beaconTargets)
end

local function warnUnchainedTargets()
	warnUnchainedMagic:Show(table.concat(unchainedTargets, "<, >"))
	timerUnchainedMagic:Start()
	table.wipe(unchainedTargets)
	unchainedIcons = 7
end

local function warnIcon()
	FrostBeaconIndex = GetRaidTargetIndex("player")
	if FrostBeaconIndex == 8 then
		SendChatMessage("{rt8}".."左←", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backleft")
	elseif FrostBeaconIndex == 5 then
		SendChatMessage("{rt5}".."左←", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backleft")
	elseif FrostBeaconIndex == 7  then
		SendChatMessage("{rt7}".."中↓", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backcenter")
	elseif FrostBeaconIndex == 4 then
		SendChatMessage("{rt4}".."右→", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backright")
	elseif FrostBeaconIndex == 6 then
		SendChatMessage("{rt6}".."右→", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backright")
	elseif FrostBeaconIndex == 3 then
		SendChatMessage("{rt3}".."中↓", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backcenter")
	end
end

local function warnIconPlanB()
	FrostBeaconIndex = GetRaidTargetIndex("player")
	if FrostBeaconIndex == 8 then
		SendChatMessage("{rt8}".."左←", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backleft")
	elseif FrostBeaconIndex == 5 then
		SendChatMessage("{rt5}".."左←", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backleft")
	elseif FrostBeaconIndex == 6  then
		SendChatMessage("{rt6}".."中↓", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backcenter")
	elseif FrostBeaconIndex == 4 then
		SendChatMessage("{rt4}".."右→", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backright")
	elseif FrostBeaconIndex == 7 then
		SendChatMessage("{rt7}".."右→", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backright")
	elseif FrostBeaconIndex == 3 then
		SendChatMessage("{rt3}".."中↓", "SAY")
		specWarnFrostBeacon:ScheduleVoice(0.32, "backcenter")
	end
end


function mod:OnCombatStart(delay)
	berserkTimer:Start(-delay)
	timerNextAirphase:Start(50-delay)
	timerNextBlisteringCold:Start(33-delay)
	specWarnBlisteringCold:ScheduleVoice(28, "gripsoon")
	warned_P2 = false
	warnedfailed = false
	table.wipe(beaconTargets)
	table.wipe(beaconIconTargets)
	table.wipe(unchainedTargets)
	unchainedIcons = 7
	self.vb.phase = 1
	activeBeacons = false
	if self.Options.RangeFrame then
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			DBM.RangeCheck:Show(20, nil, true, nil)
		else
			DBM.RangeCheck:Show(10, nil, true, nil)
		end
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide(true)
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(69649, 71056, 71057, 71058) or args:IsSpellID(73061, 73062, 73063, 73064) then--Frost Breath
		warnFrostBreath:Show()
		timerNextFrostBreath:Start()
	end
end	

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(70126) then
		beaconTargets[#beaconTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnFrostBeacon:Show()
			specWarnFrostBeacon:CancelVoice("findshelter")
			specWarnFrostBeacon:Play("ex_so_xbdn")
			specWarnFrostBeacon:ScheduleVoice(4, "countthree")
			specWarnFrostBeacon:ScheduleVoice(5, "counttwo")
			specWarnFrostBeacon:ScheduleVoice(6, "countone")
			if self.vb.phase == 1 and self.Options.YellOnBeacon and not self.Options.YellOnBeaconPlanB then
				self:Unschedule(warnIcon)
				self:Schedule(0.31, warnIcon)
			elseif self.vb.phase == 1 and self.Options.YellOnBeaconPlanB and not self.Options.YellOnBeacon then
				self:Unschedule(warnIconPlanB)
				self:Schedule(0.31, warnIconPlanB)
			end
			if self.vb.phase == 2 then
				specWarnFrostBeacon:ScheduleVoice(1, "backcenter")
				if mod:IsHealer() and isPAL then
					if self.Options.YellOnBeacon then
						SendChatMessage("NQ被点,注意刷坦!", "SAY")
					end
				end
			end
		end
		if self.vb.phase == 1 and self.Options.SetIconOnFrostBeacon then
			table.insert(beaconIconTargets, DBM:GetRaidUnitId(args.destName))
			self:UnscheduleMethod("SetBeaconIcons")
			if (mod:IsDifficulty("normal25") and #beaconIconTargets >= 5) or (mod:IsDifficulty("heroic25") and #beaconIconTargets >= 6) or ((mod:IsDifficulty("normal10") or mod:IsDifficulty("heroic10")) and #beaconIconTargets >= 2) then
				self:SetBeaconIcons()--Sort and fire as early as possible once we have all targets.
			else
				if mod:LatencyCheck() then--Icon sorting is still sensitive and should not be done by laggy members that don't have all targets.
					self:ScheduleMethod(0.3, "SetBeaconIcons")
				end
			end
			if self.Options.AnnounceFrostBeaconIcons then
				if GetTime() - spamBeaconIcon > 30 then
					if mod:IsDifficulty("heroic25") then
						SendChatMessage(L.BeaconIconChatHeroic1, "RAID_WARNING")
						SendChatMessage(L.BeaconIconChatHeroic2, "RAID_WARNING")
						spamBeaconIcon = GetTime()
					elseif mod:IsDifficulty("normal25") then
						SendChatMessage(L.BeaconIconChatNormal1, "RAID_WARNING")
						SendChatMessage(L.BeaconIconChatNormal2, "RAID_WARNING")
						spamBeaconIcon = GetTime()
					end
				end
			end
		end
		if self.vb.phase == 2 then--Phase 2 there is only one icon/beacon, don't use sorting method if we don't have to.
			beaconCount = beaconCount + 1
			timerNextBeacon:Start(nil, beaconCount)
			if self.Options.SetIconOnFrostBeacon then
				self:SetIcon(args.destName, 8)
--				if self.Options.AnnounceFrostBeaconIcons then
--					SendChatMessage(L.BeaconIconSet:format(8, args.destName), "RAID")
--				end
			end
		end
		self:Unschedule(warnBeaconTargets)
		if self.vb.phase == 2 or (mod:IsDifficulty("normal25") and #beaconTargets >= 5) or (mod:IsDifficulty("heroic25") and #beaconTargets >= 6) or ((mod:IsDifficulty("normal10") or mod:IsDifficulty("heroic10")) and #beaconTargets >= 2) then
			warnBeaconTargets()
		else
			self:Schedule(0.3, warnBeaconTargets)
		end
	elseif args:IsSpellID(69762) then
		unchainedTargets[#unchainedTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnUnchainedMagic:Show()
			if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
				specWarnUnchainedMagic:Play("runout")
			end		
		end
		if self.Options.SetIconOnUnchainedMagic then
			self:SetIcon(args.destName, unchainedIcons)
			unchainedIcons = unchainedIcons - 1
		end
		self:Unschedule(warnUnchainedTargets)
		if #unchainedTargets >= 6 then
			warnUnchainedTargets()
		else
			self:Schedule(0.3, warnUnchainedTargets)
		end
	elseif args:IsSpellID(70106) then	--Chilled to the bone (melee)
		if args:IsPlayer() then
			warnChilledtotheBone:Show(args.amount or 1)
			timerChilledtotheBone:Start()
			if (args.amount or 1) >= 4 then
				specWarnChilledtotheBone:Show(args.amount)
				if args.amount == 4 or args.amount == 6 or args.amount == 8 or args.amount == 10 then
					specWarnChilledtotheBone:Play("stopatk")
				end
			end
		end
	elseif args:IsSpellID(69766) then	--Instability (casters)
		if args:IsPlayer() then
			warnInstability:Show(args.amount or 1)
			timerInstability:Start()
			if (args.amount or 1) >= 4 then
				specWarnInstability:Show(args.amount)
				if args.amount == 4 or args.amount == 6 or args.amount == 8 or args.amount == 10 then
					specWarnInstability:Play("stopatk")
				end
			end
		end
	elseif args:IsSpellID(70127, 72528, 72529, 72530) then	--Mystic Buffet (phase 3 - everyone)
		if args:IsPlayer() then
			warnMysticBuffet:Show(args.amount or 1)
			timerMysticBuffet:Start()
			timerNextMysticBuffet:Start()
			if (args.amount or 1) >= 5 then
				specWarnMysticBuffet:Show(args.amount)
				if args.amount == 5 or args.amount == 7 or args.amount == 9 or args.amount == 11 or args.amount == 13 then
					DBM:PlaySoundFile("Interface\\AddOns\\DBM-VPYike\\stackhigh.ogg")
				end
			end
			if (args.amount or 1) < 2 then
				timerMysticAchieve:Start()
			end
		end
		if args:IsDestTypePlayer() then
			if self.Options.AchievementCheck and DBM:GetRaidRank() > 0 and not warnedfailed then
				if (args.amount or 1) == 5 then
					SendChatMessage(L.AchievementWarning:format(args.destName), "RAID")
				elseif (args.amount or 1) > 5 then
					SendChatMessage(L.AchievementFailed:format(args.destName, (args.amount or 1)), "RAID_WARNING")
					warnedfailed = true
				end
			end
		end
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(70117) then--Icy Grip Cast, not blistering cold, but adds an extra 1sec to the warning
		warnBlisteringCold:Show()
		specWarnBlisteringCold:Show()
		specWarnBlisteringCold:Play("boomrun")
		timerBlisteringCold:Start()
		timerNextBlisteringCold:Start()
		specWarnBlisteringCold:ScheduleVoice(62, "gripsoon")
	end
end	

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(69762) then
		if self.Options.SetIconOnUnchainedMagic and not activeBeacons then
			self:SetIcon(args.destName, 0)
		end
	elseif args:IsSpellID(70157) then
		if self.Options.SetIconOnFrostBeacon then
			self:SetIcon(args.destName, 0)
		end
	elseif args:IsSpellID(70126) then
		activeBeacons = false
	elseif args:IsSpellID(70106) then	--Chilled to the bone (melee)
		if args:IsPlayer() then
			timerChilledtotheBone:Cancel()
		end
	elseif args:IsSpellID(69766) then	--Instability (casters)
		if args:IsPlayer() then
			timerInstability:Cancel()
		end
	elseif args:IsSpellID(70127, 72528, 72529, 72530) then
		if args:IsPlayer() then
			timerMysticAchieve:Cancel()
			timerMysticBuffet:Cancel()
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if not warned_P2 and self:GetUnitCreatureId(uId) == 36853 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.38 then
		warned_P2 = true
		warnPhase2soon:Show()	
		warnPhase2soon:Play("ptwo")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L.YellAirphase or msg:find(L.YellAirphase)) or (msg == L.YellAirphaseDem or msg:find(L.YellAirphaseDem)) then
		if self.Options.ClearIconsOnAirphase then
			self:ClearIcons()
		end
		warnAirphase:Show()
		timerNextFrostBreath:Cancel()
		specWarnBlisteringCold:CancelVoice("gripsoon")
		if self.vb.phase == 1 then
			specWarnFrostBeacon:ScheduleVoice(13, "findshelter") 
			specWarnFrostBeacon:ScheduleVoice(19, "countone")
			specWarnFrostBeacon:ScheduleVoice(25, "counttwo")
			specWarnFrostBeacon:ScheduleVoice(30, "countthree")
			specWarnFrostBeacon:ScheduleVoice(36, "countfour")
			specWarnFrostBeacon:ScheduleVoice(37, "ex_so_bmkd")
		end
		timerUnchainedMagic:Start(55)
		timerNextBlisteringCold:Start(77)--Not exact anywhere from 80-110seconds after airphase begin
		specWarnBlisteringCold:ScheduleVoice(72, "gripsoon")
		timerNextAirphase:Start()
		timerNextGroundphase:Start()
		warnGroundphaseSoon:Schedule(40)
		activeBeacons = true
	elseif (msg == L.YellPhase2 or msg:find(L.YellPhase2)) or (msg == L.YellPhase2Dem or msg:find(L.YellPhase2Dem)) then
		beaconCount = 1
		self.vb.phase = 2
		warnPhase2:Show()
		warnPhase2:Play("phasechange")
		timerNextBeacon:Start(7, beaconCount)
		timerNextAirphase:Cancel()
		timerNextGroundphase:Cancel()
		warnGroundphaseSoon:Cancel()
		specWarnBlisteringCold:CancelVoice("gripsoon")
		timerNextBlisteringCold:Start(35)
		specWarnBlisteringCold:ScheduleVoice(30, "gripsoon")
	end
end