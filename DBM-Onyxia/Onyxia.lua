local mod	= DBM:NewMod("Onyxia", "DBM-Onyxia")
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4536 $"):sub(12, -3))
mod:SetCreatureID(10184)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_CAST_START",
	"SPELL_DAMAGE",
	"UNIT_DIED",
	CHAT_MSG_RAID_BOSS_EMOTE,
	"UNIT_HEALTH"
)

local warnWhelpsSoon		= mod:NewAnnounce("WarnWhelpsSoon", 1, 69004)
local warnPhase2			= mod:NewPhaseAnnounce(2)
local warnPhase3			= mod:NewPhaseAnnounce(3)
local warnPhase2Soon		= mod:NewAnnounce("WarnPhase2Soon", 1, "Interface\\Icons\\Spell_Nature_WispSplode")
local warnPhase3Soon		= mod:NewAnnounce("WarnPhase3Soon", 1, "Interface\\Icons\\Spell_Nature_WispSplode")

--local preWarnDeepBreath     = mod:NewSoonAnnounce(17086, 2)--Experimental, if it is off please let me know.
local specWarnBreath		= mod:NewSpecialWarningRun(17086)
local specWarnBlastNova		= mod:NewSpecialWarningRun(68958, "Melee")

local timerNextFlameBreath	= mod:NewCDTimer(20, 68970, nil, nil, nil, 2)--Breath she does on ground in frontal cone.
local timerNextDeepBreath	= mod:NewCDTimer(35, 17086, nil, nil, nil, 3)--Range from 35-60seconds in between based on where she moves to.
local timerBreath			= mod:NewCastTimer(8, 17086, nil, nil, nil, 2, nil, DBM_CORE_L.DEADLY_ICON)
local timerBellowingRoarCD	= mod:NewCDTimer(22, 18431, nil, nil, nil, 2, nil, DBM_CORE_L.TANK_ICON) -- 低沉咆哮 CD大概22
local timerBellowingRoar	= mod:NewCastTimer(2.5, 18431, nil, nil, nil, 2, nil, DBM_CORE_L.HEALER_ICON)
local timerWhelps			= mod:NewTimer(105, "TimerWhelps", 10697, nil, nil, 1)
local timerAchieve			= mod:NewAchievementTimer(300, 4405) 
local timerAchieveWhelps	= mod:NewAchievementTimer(10, 4406) 

--local soundBlastNova		= mod:NewSound(68958, nil, mod:IsMelee())
--local soundDeepBreath 		= mod:NewSound(17086)

--local sndFunny				= mod:NewAnnounce("SoundWTF", nil, nil, false)

local sndWOP					= mod:NewSpecialWarning("SoundWOP", nil, nil, nil, 4, 2)

local warned_preP2 = false
local warned_preP3 = false
local phase = 0

mod.vb.phase = 0


function mod:OnCombatStart(delay)
	phase = 1
	self.vb.phase = 1
    warned_preP2 = false
	warned_preP3 = false
	timerAchieve:Start(-delay)
	--sndFunny:Play("Interface\\AddOns\\DBM-Onyxia\\sounds\\dps-very-very-slowly.mp3")
	--sndFunny:ScheduleVoice(20, "Interface\\AddOns\\DBM-Onyxia\\sounds\\hit-it-like-you-mean-it.mp3")
	--sndFunny:ScheduleVoice(30, "Interface\\AddOns\\DBM-Onyxia\\sounds\\now-hit-it-very-hard-and-fast.mp3")
end

function mod:Whelps()
	if self:IsInCombat() then
		timerWhelps:Start()
		warnWhelpsSoon:Schedule(95)
		self:ScheduleMethod(105, "Whelps")
		-- we replay sounds as long as p2 is running
		--sndFunny:Play("Interface\\AddOns\\DBM-Onyxia\\sounds\\i-dont-see-enough-dots.mp3")
		--sndFunny:Schedule(35, "Interface\\AddOns\\DBM-Onyxia\\sounds\\throw-more-dots.mp3")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellP2 or msg:find(L.YellP2) then
		phase = 2
		self.vb.phase = 2
		warnPhase2:Show()
		sndWOP:Play("phasechange")
--		preWarnDeepBreath:Schedule(72)	-- Pre-Warn Deep Breath
		timerNextDeepBreath:Start(42)    -- 25人本 还剩35 秒就第一次 ? 他本来写的77  
		timerAchieveWhelps:Start()
		timerNextFlameBreath:Cancel()
		self:ScheduleMethod(5, "Whelps")
		--sndFunny:ScheduleVoice(10, "Interface\\AddOns\\DBM-Onyxia\\sounds\\throw-more-dots.mp3")
		--sndFunny:ScheduleVoice(17, "Interface\\AddOns\\DBM-Onyxia\\sounds\\whelps-left-side-even-side-handle-it.mp3")
	elseif msg == L.YellP3 or msg:find(L.YellP3) then
		phase = 3
		self.vb.phase = 3
		warnPhase3:Show()
		sndWOP:Play("phasechange")
		sndWOP:ScheduleVoice(2, "fearsoon")
		self:UnscheduleMethod("Whelps")
		timerWhelps:Stop()
		timerNextDeepBreath:Stop()
		warnWhelpsSoon:Cancel()
--		preWarnDeepBreath:Cancel()
		--sndFunny:ScheduleVoice(20, "Interface\\AddOns\\DBM-Onyxia\\sounds\\now-hit-it-very-hard-and-fast.mp3")
   		--sndFunny:ScheduleVoice(35, "Interface\\AddOns\\DBM-Onyxia\\sounds\\i-dont-see-enough-dots.mp3")
		--sndFunny:ScheduleVoice(50, "Interface\\AddOns\\DBM-Onyxia\\sounds\\hit-it-like-you-mean-it.mp3")
		--sndFunny:ScheduleVoice(65, "Interface\\AddOns\\DBM-Onyxia\\sounds\\throw-more-dots.mp3")
	end
end


function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if (msg == L.Breath or msg:find(L.Breath)) or (msg == L.Breath2 or msg:find(L.Breath2)) then
		sndWOP:Play("breathsoon")

	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(68958) then
        specWarnBlastNova:Show()
		--soundBlastNova:Play()
	elseif args:IsSpellID(17086, 18351, 18564, 18576) or args:IsSpellID(18584, 18596, 18609, 18617) then	-- 1 ID for each direction
		specWarnBreath:Show()
		--soundDeepBreath:Play()
		timerBreath:Start()
		timerNextDeepBreath:Start()
--		preWarnDeepBreath:Schedule(35)              -- Pre-Warn Deep Breath
	elseif args:IsSpellID(18435, 68970) then        -- Flame Breath (Ground phases)
		timerNextFlameBreath:Start()
	elseif args:IsSpellID(18431) then
		timerBellowingRoar:Start()
		sndWOP:CancelVoice("fearsoon")
		sndWOP:Play(18, "fearsoon")
		timerBellowingRoarCD:Start() -- timerBellowingRoarCD 这种不需要 Cancel() 自动会Cancel  NewCDTimer
	end
end

function mod:SPELL_DAMAGE(args)
	if args:IsSpellID(68867, 69286) and args:IsPlayer() then		-- Tail Sweep
		--sndFunny:Play("Interface\\AddOns\\DBM-Onyxia\\sounds\\watch-the-tail.mp3")
	end
end

function mod:UNIT_DIED(args)
	if self:IsInCombat() and args:IsPlayer() then
		--sndFunny:Play("Interface\\AddOns\\DBM-Onyxia\\sounds\\thats-a-fucking-fifty-dkp-minus.mp3")
	end
end

function mod:UNIT_HEALTH(uId)
	if phase == 1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 10184 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.67 then
		warned_preP2 = true
		warnPhase2Soon:Show()	
		sndWOP:Play("ptwo")
	elseif phase == 2 and not warned_preP3 and self:GetUnitCreatureId(uId) == 10184 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.41 then
		warned_preP3 = true
		warnPhase3Soon:Show()	
		sndWOP:Play("pthree")
	end
end