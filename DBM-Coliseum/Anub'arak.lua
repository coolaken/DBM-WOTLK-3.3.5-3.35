﻿local mod	= DBM:NewMod("Anub'arak_Coliseum", "DBM-Coliseum", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4531 $"):sub(12, -3))
mod:SetCreatureID(34564)  

mod:RegisterCombat("yell", L.YellPull)

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REFRESH",
	"SPELL_AURA_REMOVED",
	"SPELL_CAST_START",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_HEALTH"
)

mod:SetUsedIcons(3, 4, 5, 6, 7, 8)

local warnAdds				= mod:NewAnnounce("warnAdds", 3, 45419)
local preWarnShadowStrike	= mod:NewSoonAnnounce(66134, 3)
local warnShadowStrike		= mod:NewSpellAnnounce(66134, 4)
local warnPursue			= mod:NewTargetNoFilterAnnounce(67574, 4)
local warnFreezingSlash		= mod:NewTargetNoFilterAnnounce(66012, 2, nil, "Tank|Healer")
local warnHoP				= mod:NewTargetNoFilterAnnounce(10278, 2, nil, false)--Heroic strat revolves around kiting pursue and using Hand of Protection.
local warnEmerge			= mod:NewAnnounce("WarnEmerge", 3, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnEmergeSoon		= mod:NewAnnounce("WarnEmergeSoon", 1, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnSubmerge			= mod:NewAnnounce("WarnSubmerge", 3, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local warnSubmergeSoon		= mod:NewAnnounce("WarnSubmergeSoon", 1, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local warnPhase3			= mod:NewPhaseAnnounce(3)

local specWarnPursue		= mod:NewSpecialWarning("SpecWarnPursue")
local specWarnSubmergeSoon	= mod:NewSpecialWarning("specWarnSubmergeSoon", "Tank")
local specWarnShadowStrike	= mod:NewSpecialWarning("SpecWarnShadowStrike", "Tank")
local specWarnPCold			= mod:NewSpecialWarningDefensive(68510, "-Tank", nil, nil, 5, 2)

--local timerAdds				= mod:NewTimer(45, "timerAdds", 45419, nil, nil, 1)
local timerAdds		= mod:NewAddsTimer(45, 45419, "timerAdds", nil, "timerAdds")
local timerSubmerge			= mod:NewTimer(75, "TimerSubmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 5)
--local timerSubmerge			= mod:NewPhaseTimer(75, nil, "TimerSubmerge", nil, "TimerSubmerge", 5, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp") --图标有问题啊
local timerEmerge			= mod:NewTimer(65, "TimerEmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp", nil, nil, 5)
local timerFreezingSlash	= mod:NewCDTimer(16, 66012, nil, "Tank|Healer", nil, 3, nil, DBM_CORE_L.TANK_ICON..DBM_CORE_L.HEALER_ICON)
local timerPCold			= mod:NewBuffActiveTimer(15, 68509, nil, false)
local timerShadowStrike		= mod:NewNextTimer(30.5, 66134, nil, nil, nil, 4, nil, DBM_CORE_L.INTERRUPT_ICON, nil, 1, 3)
local timerHoP				= mod:NewBuffActiveTimer(10, 10278, nil, false)--So we will track bops to make this easier.

local enrageTimer			= mod:NewBerserkTimer(570)	-- 9:30 ? hmpf (no enrage while submerged... this sucks)

local sndWOP					= mod:NewSpecialWarning("SoundWOP", nil, nil, nil, 4, 2)

mod:AddBoolOption("PlaySoundOnPursue")
mod:AddBoolOption("PlaySoundOnShadowStrike", false)
mod:AddBoolOption("PursueIcon")
mod:AddBoolOption("SetIconsOnPCold", true)
mod:AddBoolOption("AnnouncePColdIcons", false)
mod:AddBoolOption("AnnouncePColdIconsRemoved", false)
mod:AddBoolOption("RemoveHealthBuffsInP3", false)

local PColdTargets = {}
local Burrowed = false 
local warned_preP3 = false

mod.vb.phase = 0

function mod:OnCombatStart(delay)
	warned_preP3 = false
	Burrowed = false 
	timerAdds:Start(10-delay) 
	warnAdds:Schedule(10-delay) 
	self:ScheduleMethod(10-delay, "Adds")
	warnSubmergeSoon:Schedule(70-delay)
	specWarnSubmergeSoon:Schedule(70-delay)
	sndWOP:ScheduleVoice(70-delay, "burrowsoon")
	timerSubmerge:Start(80-delay)
	enrageTimer:Start(-delay)
	timerFreezingSlash:Start(-delay)
	table.wipe(PColdTargets)
	if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
		timerShadowStrike:Start()
		preWarnShadowStrike:Schedule(25.5-delay)
		if self.Options.PlaySoundOnShadowStrike then
			sndWOP:ScheduleVoice(25.5-delay, "sstrikesoon")
			--sndWOP:ScheduleVoice(27.5-delay, "countthree")
			--sndWOP:ScheduleVoice(28.5-delay, "counttwo")
			--sndWOP:ScheduleVoice(29.5-delay, "countone")
		end
		self:ScheduleMethod(30.5-delay, "ShadowStrike")
	end
	self.vb.phase = 1
end

function mod:Adds() 
	if self:IsInCombat() then 
		if not Burrowed then 
			timerAdds:Start() 
			warnAdds:Schedule(45) 
			sndWOP:ScheduleVoice(40, "bigmobsoon")
			sndWOP:ScheduleVoice(45, "bigmob")
			self:ScheduleMethod(45, "Adds") 
		end 
	end 
end

function mod:ShadowStrike()
	if self:IsInCombat() then
		timerShadowStrike:Start()
		preWarnShadowStrike:Cancel()
		if self.Options.PlaySoundOnShadowStrike then
			sndWOP:CancelVoice("sstrikesoon")
			--sndWOP:CancelVoice("countthree")
			--sndWOP:CancelVoice("counttwo")
			--sndWOP:CancelVoice("countone")
			sndWOP:ScheduleVoice(25.5, "sstrikesoon")
			--sndWOP:ScheduleVoice(27.5, "countthree")
			--sndWOP:ScheduleVoice(28.5, "counttwo")
			--sndWOP:ScheduleVoice(29.5, "countone")
		end
		preWarnShadowStrike:Schedule(25.5)
		self:UnscheduleMethod("ShadowStrike")
		self:ScheduleMethod(30.5, "ShadowStrike")
	end
end

local function ClearPcoldTargets()
	table.wipe(PColdTargets)
end

do
	local function sort_by_group(v1, v2)
		return DBM:GetRaidSubgroup(UnitName(v1)) < DBM:GetRaidSubgroup(UnitName(v2))
	end
	function mod:SetPcoldIcons()
		if DBM:GetRaidRank() > 0 then
			table.sort(PColdTargets, sort_by_group)
			local PColdIcon = 7
			for i, v in ipairs(PColdTargets) do
				if self.Options.AnnouncePColdIcons then
					SendChatMessage(L.PcoldIconSet:format(PColdIcon, UnitName(v)), "RAID")
				end
				self:SetIcon(UnitName(v), PColdIcon)
				PColdIcon = PColdIcon - 1
			end
			self:Schedule(5, ClearPcoldTargets)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(67574) then			-- Pursue
		if args:IsPlayer() then
			specWarnPursue:Show()
			if self.Options.PlaySoundOnPursue then
				DBM:PlaySoundFile("Interface\\AddOns\\DBM-VPYike\\justrun.ogg")
			end
		end
		if self.Options.PursueIcon then
			self:SetIcon(args.destName, 8, 15)
		end
		warnPursue:Show(args.destName)
	elseif args:IsSpellID(66013, 67700, 68509, 68510) then		-- Penetrating Cold
		timerPCold:Show()
		if args:IsPlayer() then
			specWarnPCold:Show()
			if self.vb.phase == 3 then
				specWarnPCold:Play("holdit")
			end
		end
		if self.Options.SetIconsOnPCold then
			table.insert(PColdTargets, DBM:GetRaidUnitId(args.destName))
			self:UnscheduleMethod("SetPcoldIcons")
			if ((mod:IsDifficulty("normal25") or mod:IsDifficulty("heroic25")) and #PColdTargets >= 5) or ((mod:IsDifficulty("normal10") or mod:IsDifficulty("heroic10")) and #PColdTargets >= 2) then
				self:SetPcoldIcons()--Sort and fire as early as possible once we have all targets.
			else
				if mod:LatencyCheck() then
					self:ScheduleMethod(0.3, "SetPcoldIcons")
				end
			end
		end
	elseif args:IsSpellID(66012) then							-- Freezing Slash
		warnFreezingSlash:Show(args.destName)
		timerFreezingSlash:Start()
	elseif args:IsSpellID(10278) and self:IsInCombat() then		-- Hand of Protection
		warnHoP:Show(args.destName)
		timerHoP:Start(args.destName)
	end
end

function mod:SPELL_AURA_REFRESH(args)
	if args:IsSpellID(66013, 67700, 68509, 68510) then		-- Penetrating Cold
		timerPCold:Show()
		if args:IsPlayer() then
			specWarnPCold:Show()
		end
		if self.Options.SetIconsOnPCold then
			table.insert(PColdTargets, DBM:GetRaidUnitId(args.destName))
			self:UnscheduleMethod("SetPcoldIcons")
			if ((mod:IsDifficulty("normal25") or mod:IsDifficulty("heroic25")) and #PColdTargets >= 5) or ((mod:IsDifficulty("normal10") or mod:IsDifficulty("heroic10")) and #PColdTargets >= 2) then
				self:SetPcoldIcons()--Sort and fire as early as possible once we have all targets.
			else
				if mod:LatencyCheck() then
					self:ScheduleMethod(0.3, "SetPcoldIcons")
				end
			end
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(66013, 67700, 68509, 68510) then			-- Penetrating Cold
		if self.Options.SetIconsOnPCold then
			self:SetIcon(args.destName, 0)
			if self.Options.AnnouncePColdIconsRemoved and DBM:GetRaidRank() >= 1 then
				SendChatMessage(L.PcoldIconRemoved:format(args.destName), "RAID")
			end
		end
	elseif args:IsSpellID(10278) and self:IsInCombat() then		-- Hand of Protection
		timerHoP:Cancel(args.destName)
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(66118, 67630, 68646, 68647) then			-- Swarm (start p3)
		self.vb.phase = 3
		sndWOP:Play("phasechange")
		warnPhase3:Show()
		warnEmergeSoon:Cancel()
		warnSubmergeSoon:Cancel()
		sndWOP:CancelVoice("burrowsoon")
		specWarnSubmergeSoon:Cancel()
		timerEmerge:Stop()
		timerSubmerge:Stop()
		if self.Options.RemoveHealthBuffsInP3 then
			mod:ScheduleMethod(0.1, "RemoveBuffs")
		end
		if mod:IsDifficulty("normal10") or mod:IsDifficulty("normal25") then
			timerAdds:Cancel()
			warnAdds:Cancel()
			sndWOP:CancelVoice("bigmobsoon")
			sndWOP:CancelVoice("bigmob")
			self:UnscheduleMethod("Adds")
		end
	elseif args:IsSpellID(66134) then							-- Shadow Strike
		self:ShadowStrike()
		specWarnShadowStrike:Show()
		warnShadowStrike:Show()
		sndWOP:Play("kickcast")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg and msg:find(L.Burrow) then
		self.vb.phase = 2
		Burrowed = true
		timerAdds:Cancel()
		warnAdds:Cancel()
		warnSubmerge:Show()
		sndWOP:CancelVoice("bigmobsoon")
		sndWOP:CancelVoice("bigmob")
		warnEmergeSoon:Schedule(55)
		timerEmerge:Start()
		timerFreezingSlash:Stop()
	elseif msg and msg:find(L.Emerge) then
		self.vb.phase = 1
		Burrowed = false
		timerAdds:Start(5)
		warnAdds:Schedule(5)
		self:ScheduleMethod(5, "Adds")
		warnEmerge:Show()
		warnSubmergeSoon:Schedule(65)
		sndWOP:ScheduleVoice(65, "burrowsoon")
		specWarnSubmergeSoon:Schedule(65)
		timerSubmerge:Start()
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerShadowStrike:Stop()
			preWarnShadowStrike:Cancel()
			if self.Options.PlaySoundOnShadowStrike then
				sndWOP:CancelVoice("sstrikesoon")
				--sndWOP:CancelVoice("countthree")
				--sndWOP:CancelVoice("counttwo")
				--sndWOP:CancelVoice("countone")
			end
			self:UnscheduleMethod("ShadowStrike")
			self:ScheduleMethod(5.5, "ShadowStrike")  -- 35-36sec after Emerge next ShadowStrike
		end
	end
end

function mod:RemoveBuffs()
	CancelUnitBuff("player", (GetSpellInfo(47440)))		-- Commanding Shout
	CancelUnitBuff("player", (GetSpellInfo(48161)))		-- Power Word: Fortitude
	CancelUnitBuff("player", (GetSpellInfo(48162)))		-- Prayer of Fortitude
	CancelUnitBuff("player", (GetSpellInfo(69377)))		-- Runescroll of Fortitude
end

function mod:UNIT_HEALTH(uId)
	if self.vb.phase == 1 and not warned_preP3 and self:GetUnitCreatureId(uId) == 34564 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.32 then
		warned_preP3 = true
		sndWOP:Play("pthree")
	end
end