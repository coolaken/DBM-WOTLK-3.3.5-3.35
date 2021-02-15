local mod	= DBM:NewMod("Kel'Thuzad", "DBM-Naxx", 5)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4548 $"):sub(12, -3))
mod:SetCreatureID(15990)
mod:SetMinCombatTime(60)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6, 7, 8)

mod:RegisterCombat("yell", L.Yell)


mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_CAST_SUCCESS",
	"CHAT_MSG_MONSTER_YELL",
	"CHAT_MSG_MONSTER_EMOTE",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_HEALTH"
)

--[[
local isControler = select(2, UnitClass("player")) == "PALADIN"
	    		 or select(2, UnitClass("player")) == "PRIEST"
	    		 or select(2, UnitClass("player")) == "DRUID"
]]

local warnAddsSoon			= mod:NewAnnounce("WarnAddsSoon", 1, 45419)
local warnPhase2			= mod:NewPhaseAnnounce(2, 3)
local warnBlastTargets		= mod:NewTargetNoFilterAnnounce(27808, 2)
local warnFissure			= mod:NewSpellAnnounce(27810, 3)
local warnMana				= mod:NewTargetNoFilterAnnounce(27819, 2)
local warnChainsTargets		= mod:NewTargetNoFilterAnnounce(28410, 2)

local specwarnP2Soon		= mod:NewSpecialWarning("SpecwarnP2Soon")

local blastTimer			= mod:NewBuffActiveTimer(4, 27808)
local timerMC				= mod:NewBuffActiveTimer(20, 28410)
local timerMCCD				= mod:NewCDTimer(90, 28410)--actually 60 second cdish but its easier to do it this way for the first one.
local timerFissureCD		= mod:NewCDTimer(25, 27810)--25人25秒cd? 原来写的40?
local timerFrostBlastCD		= mod:NewCDTimer(45, 27808) --冰霜冲击 10人id 29879
local timerFrostboltCD		= mod:NewCDTimer(24, 29923)--群体寒冰箭 55807
local timerManaDetonationCD		= mod:NewCDTimer(30, 27819) --自爆法力
--test local timerOutPortal	= mod:NewTimer(20,"TimerOutPortal", "Interface\\Icons\\spell_arcane_portalshattrath")
local timerPhase2			= mod:NewTimer(225, "TimerPhase2", "Interface\\Icons\\Spell_Nature_WispSplode")
local timerMob			= mod:NewTimer(15, "TimerMob", "Interface\\Icons\\inv_misc_ahnqirajtrinket_01")
--寒冰箭 25人            55802 danti             55807 aoe                                10人              28479 aoe                       28478 danti
mod:AddBoolOption("SetIconOnMC", true)
mod:AddBoolOption("SetIconOnManaBomb", true)
mod:AddBoolOption("SetIconOnFrostTomb", true)
mod:AddBoolOption("ShowRange", true)
mod:AddBoolOption("IsControler", true)

local warnedAdds = false
local MCIcon = 1
local frostBlastTargets = {}
local chainsTargets = {}
local counttime = 0

local sndWOP					= mod:NewSpecialWarning("SoundWOP", nil, nil, nil, 4, 2)

mod.vb.phase = 0

local function AnnounceChainsTargets()
	warnChainsTargets:Show(table.concat(chainsTargets, "< >"))
	table.wipe(chainsTargets)
	MCIcon = 1
end

local function AnnounceBlastTargets()
	warnBlastTargets:Show(table.concat(frostBlastTargets, "< >"))
	if mod.Options.SetIconOnFrostTomb then
		for i = #frostBlastTargets, 1, -1 do
			mod:SetIcon(frostBlastTargets[i], 8 - i, 4.5) 
			frostBlastTargets[i] = nil
		end
	end
end

function mod:OnCombatStart(delay)
	table.wipe(chainsTargets)
	table.wipe(frostBlastTargets)
	warnedAdds = false
	MCIcon = 1
	counttime = 0
	specwarnP2Soon:Schedule(215-delay)
	if mod:IsDifficulty("normal25") then
		timerMCCD:Schedule(225-delay)
		sndWOP:ScheduleVoice(220, "findmc")
	end
	timerPhase2:Start()
	warnPhase2:Schedule(225)
	sndWOP:ScheduleVoice(210, "ptwo")
	if self.Options.ShowRange then
		self:ScheduleMethod(210-delay, "RangeToggle", true)
	end
	--self:ScheduleMethod(226, "StartPhase2")
	self.vb.phase = 1
	
end

function mod:OnCombatEnd()
	if self.Options.ShowRange then
		self:RangeToggle(false)
	end
end



function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(27808) then -- Frost Blast
		table.insert(frostBlastTargets, args.destName)
		self:Unschedule(AnnounceBlastTargets)
		self:Schedule(0.5, AnnounceBlastTargets)
		blastTimer:Start()
	elseif args:IsSpellID(27819) then -- Mana Bomb
		timerManaDetonationCD:Start()
		warnMana:Show(args.destName)
		if self.Options.SetIconOnManaBomb then
			self:SetIcon(args.destName, 8, 5.5)
		end
	elseif args:IsSpellID(28410) then -- Chains of Kel'Thuzad
		chainsTargets[#chainsTargets + 1] = args.destName
		timerMC:Start()
		timerMCCD:Start(60)--60 seconds?
		sndWOP:CancelVoice("findmc")
		sndWOP:ScheduleVoice(55, "findmc")
		if self.Options.SetIconOnMC then
			self:SetIcon(args.destName, MCIcon, 20)
			MCIcon = MCIcon + 1
		end
		self:Unschedule(AnnounceChainsTargets)
		if #chainsTargets >= 3 then
			AnnounceChainsTargets()
		else
			self:Schedule(1.0, AnnounceChainsTargets)
		end
--test	elseif args:IsPlayer() and args:IsSpellID(48441) then
--		counttime = counttime + 1
--		sndWOP:Play("count\\"..counttime.."")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(27810) then
		warnFissure:Show()
		timerFissureCD:Start()
	elseif args:IsSpellID(27808) then
		timerFrostBlastCD:Start()
	elseif args:IsSpellID(55807, 28479) then
		timerFrostboltCD:Start()
	end
end

function mod:UNIT_HEALTH(uId)
	if not warnedAdds and self:GetUnitCreatureId(uId) == 15990 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.48 then
		warnedAdds = true
		warnAddsSoon:Show()
	end
end

function mod:RangeToggle(show)
	if show then
		DBM.RangeCheck:Show(10, nil, true, nil)
	else
		DBM.RangeCheck:Hide(true)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == ((L.YellPhasetwo1 or msg:find(L.YellPhasetwo1)) or (L.YellPhasetwo2 or msg:find(L.YellPhasetwo2)) or (L.YellPhasetwo3 or msg:find(L.YellPhasetwo3)) or (L.YellPhasetwo4 or msg:find(L.YellPhasetwo4))) then
		self.vb.phase = 2
		timerPhase2:Cancel()
		warnPhase2:Cancel()
		warnPhase2:Show()
		timerMCCD:Cancel()
		sndWOP:CancelVoice("ptwo")
		sndWOP:CancelVoice("findmc")
		sndWOP:Play("phasechange")
		timerFissureCD:Start(25)
		timerFrostBlastCD:Start(45)
		timerManaDetonationCD:Start(20)
		if mod:IsDifficulty("normal25") then
			sndWOP:Play("findmc")
		end
	elseif msg == L.YellMob or msg:find(L.YellMob) then
		-- 准备小怪
		sndWOP:Play("mobsoon")
		timerMob:Start()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == (L.YellMobOut or msg:find(L.YellMobOut)) or (msg == L.YellMobOute or msg:find(L.YellMobOute)) then
		counttime = counttime + 1
		if (mod:IsDifficulty("normal25") and (counttime <= 4)) or (mod:IsDifficulty("normal10") and (counttime <= 2)) then
			timerMob:Start(5)
		end
		if self.Options.IsControler  then
			sndWOP:Play("crowdcontrol")
			sndWOP:ScheduleVoice(1, "group"..counttime.."")
		end
	end
end

--mod.CHAT_MSG_RAID_BOSS_EMOTE = mod.CHAT_MSG_MONSTER_EMOTE