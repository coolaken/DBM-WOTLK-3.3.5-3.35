local mod	= DBM:NewMod("Halion", "DBM-ChamberOfAspects", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4483 $"):sub(12, -3))
mod:SetCreatureID(39863)--40142 (twilight form)
mod:SetMinSyncRevision(4358)
mod:SetUsedIcons(7, 8)

mod:RegisterCombat("combat")
--mod:RegisterKill("yell", L.Kill)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"SPELL_DAMAGE",
	"CHAT_MSG_MONSTER_YELL",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_HEALTH"
)

local warnPhase2Soon				= mod:NewAnnounce("WarnPhase2Soon", 2)
local warnPhase3Soon				= mod:NewAnnounce("WarnPhase3Soon", 2)
local warnPhase2					= mod:NewPhaseAnnounce(2)
local warnPhase3					= mod:NewPhaseAnnounce(3)
local warningShadowConsumption		= mod:NewTargetNoFilterAnnounce(74792, 4)
local warningFieryConsumption		= mod:NewTargetNoFilterAnnounce(74562, 4)
local warningMeteor					= mod:NewSpellAnnounce(74648, 3)
local warningShadowBreath			= mod:NewSpellAnnounce(75954, 2, nil, mod:IsTank() or mod:IsHealer())
local warningFieryBreath			= mod:NewSpellAnnounce(74526, 2, nil, mod:IsTank() or mod:IsHealer())
local warningTwilightCutter			= mod:NewAnnounce("TwilightCutterCast", 4, 77844)

local specWarnShadowConsumption		= mod:NewSpecialWarningRun(74792) --灵魂吞噬
local specWarnFieryConsumption		= mod:NewSpecialWarningRun(74562) --炽焰燃烧
local specWarnMeteorStrike			= mod:NewSpecialWarningMove(75952) --流星打击
local specWarnTwilightCutter		= mod:NewSpecialWarningSpell(77844) --暮光撕裂射线

local timerShadowConsumptionCD		= mod:NewNextTimer(25, 74792, nil, nil, nil, 3)
local timerFieryConsumptionCD		= mod:NewNextTimer(25, 74562, nil, nil, nil, 3)
local timerMeteorCD					= mod:NewNextTimer(40, 74648, nil, nil, nil, 2)
local timerMeteorCast				= mod:NewCastTimer(7, 74648, nil, nil, nil, 2, nil, DBM_CORE_L.IMPORTANT_ICON)--7-8 seconds from boss yell the meteor impacts.
local timerTwilightCutterCast		= mod:NewCastTimer(5, 77844, nil, nil, nil, 7, nil, DBM_CORE_L.IMPORTANT_ICON)
local timerTwilightCutter			= mod:NewBuffActiveTimer(10, 77844, nil, nil, nil, 2, nil, DBM_CORE_L.DEADLY_ICON)
local timerTwilightCutterCD			= mod:NewNextTimer(15, 77844, nil, nil, nil, 2)
local timerShadowBreathCD			= mod:NewCDTimer(19, 75954, nil, "Tank|Healer", nil, 2, nil, DBM_CORE_L.TANK_ICON)--Same as debuff timers, same CD, can be merged into 1.
local timerFieryBreathCD			= mod:NewCDTimer(19, 74526, nil, "Tank|Healer", nil, 2, nil, DBM_CORE_L.TANK_ICON)--But unique icons are nice pertaining to phase you're in ;)

local berserkTimer					= mod:NewBerserkTimer(480)

--local soundConsumption 				= mod:NewSound(74562, "SoundOnConsumption")
local sndWOP					= mod:NewSpecialWarning("SoundWOP", nil, nil, nil, 4, 2)

mod:AddBoolOption("YellOnConsumption", true, "announce")
mod:AddBoolOption("AnnounceAlternatePhase", false, "announce")
mod:AddBoolOption("WhisperOnConsumption", false, "announce")
mod:AddBoolOption("SetIconOnConsumption", true)

local warned_preP2 = false
local warned_preP3 = false
local lastflame = 0
local lastshroud = 0
local phases = {}

function mod:LocationChecker()
	if GetTime() - lastshroud < 6 then
		DBM.BossHealth:RemoveBoss(39863)--you took damage from twilight realm recently so remove the physical boss from health frame.
	else
		DBM.BossHealth:RemoveBoss(40142)--you have not taken damage from twilight realm so remove twilight boss health bar.
	end
end

local function updateHealthFrame(phase)
	if phases[phase] then
		return
	end
	phases[phase] = true
	if phase == 1 then
		DBM.BossHealth:Clear()
		DBM.BossHealth:AddBoss(39863, L.NormalHalion)
	elseif phase == 2 then
		DBM.BossHealth:Clear()
		DBM.BossHealth:AddBoss(40142, L.TwilightHalion)
	elseif phase == 3 then
		DBM.BossHealth:AddBoss(39863, L.NormalHalion)--Add 1st bar back on. you have two bars for time being.
		mod:ScheduleMethod(20, "LocationChecker")--we remove the extra bar in 20 seconds depending on where you are at when check is run.
	end
end

function mod:OnCombatStart(delay)--These may still need retuning too, log i had didn't have pull time though.
	table.wipe(phases)
	warned_preP2 = false
	warned_preP3 = false
	phase2Started = 0
	lastflame = 0
	lastshroud = 0
	berserkTimer:Start(-delay)
	timerMeteorCD:Start(20-delay)
	timerFieryConsumptionCD:Start(15-delay)
	timerFieryBreathCD:Start(10-delay)
	updateHealthFrame(1)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(74806, 75954, 75955, 75956) then
		warningShadowBreath:Show()
		timerShadowBreathCD:Start()
	elseif args:IsSpellID(74525, 74526, 74527, 74528) then
		warningFieryBreath:Show()
		timerFieryBreathCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)--We use spell cast success for debuff timers in case it gets resisted by a player we still get CD timer for next one
	if args:IsSpellID(74792) then
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerShadowConsumptionCD:Start(20)
		else
			timerShadowConsumptionCD:Start()
		end
		if mod:LatencyCheck() then
			self:SendSync("ShadowCD")
		end
	elseif args:IsSpellID(74562) then
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerFieryConsumptionCD:Start(20)
		else
			timerFieryConsumptionCD:Start()
		end
		if mod:LatencyCheck() then
			self:SendSync("FieryCD")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)--We don't use spell cast success for actual debuff on >player< warnings since it has a chance to be resisted.
	if args:IsSpellID(74792) then
		if mod:LatencyCheck() then
			self:SendSync("ShadowTarget", args.destName)
		end
		if args:IsPlayer() then
			specWarnShadowConsumption:Show()
--			soundConsumption:Play()
			sndWOP:Play("runout")
			if self.Options.YellOnConsumption then
				SendChatMessage(L.YellConsumption, "SAY")
			end
		else
			sndWOP:Play("shadowmark")
		end
		if not self.Options.AnnounceAlternatePhase then
			warningShadowConsumption:Show(args.destName)
			if IsRaidLeader() and self.Options.WhisperOnConsumption then
				self:SendWhisper(L.WhisperConsumption, args.destName)
			end
		end
		if self.Options.SetIconOnConsumption then
			self:SetIcon(args.destName, 7)
		end
	elseif args:IsSpellID(74562) then
		if mod:LatencyCheck() then
			self:SendSync("FieryTarget", args.destName)
		end
		if args:IsPlayer() then
			specWarnFieryConsumption:Show()
--			soundConsumption:Play()
			sndWOP:Play("runout")
			if self.Options.YellOnConsumption then
				SendChatMessage(L.YellCombustion, "SAY")
			end
		else
			sndWOP:Play("firemark")
		end
		if not self.Options.AnnounceAlternatePhase then
			warningFieryConsumption:Show(args.destName)
			if IsRaidLeader() and self.Options.WhisperOnConsumption then
				self:SendWhisper(L.WhisperCombustion, args.destName)
			end
		end
		if self.Options.SetIconOnConsumption then
			self:SetIcon(args.destName, 8)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(74792) then
		if self.Options.SetIconOnConsumption then
			self:SetIcon(args.destName, 0)
		end
	elseif args:IsSpellID(74562) then
		if self.Options.SetIconOnConsumption then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:SPELL_DAMAGE(args)
	if (args:IsSpellID(75952, 75951, 75950, 75949) or args:IsSpellID(75948, 75947)) and args:IsPlayer() and GetTime() - lastflame > 2 then
		specWarnMeteorStrike:Show()
		sndWOP:Play("runaway")
		lastflame = GetTime()
	elseif args:IsSpellID(75483, 75484, 75485, 75486) and args:IsPlayer() then
		lastshroud = GetTime()--keeps a time stamp for twilight realm damage to determin if you're still there or not for bosshealth frame.
	end
end

function mod:UNIT_HEALTH(uId)
	if not warned_preP2 and self:GetUnitCreatureId(uId) == 39863 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.79 then
		warned_preP2 = true
		warnPhase2Soon:Show()	
		sndWOP:Play("ptwo")
	elseif not warned_preP3 and self:GetUnitCreatureId(uId) == 40142 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.54 then
		warned_preP3 = true
		warnPhase3Soon:Show()	
		sndWOP:Play("pthree")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Phase2 or msg:find(L.Phase2) then
		updateHealthFrame(2)
		timerFieryBreathCD:Cancel()
		timerMeteorCD:Cancel()
		timerFieryConsumptionCD:Cancel()
		warnPhase2:Show()
		timerShadowBreathCD:Start(25)
		timerShadowConsumptionCD:Start(20)--not exact, 15 seconds from tank aggro, but easier to add 5 seconds to it as a estimate timer than trying to detect this
		timerTwilightCutterCD:Start(35)
	elseif msg == L.Phase3 or msg:find(L.Phase3) then
		self:SendSync("Phase3")
	elseif msg == L.MeteorCast or msg:find(L.MeteorCast) then--There is no CLEU cast trigger for meteor, only yell
		if not self.Options.AnnounceAlternatePhase then
			warningMeteor:Show()
			sndWOP:Play("meteorrun")
			timerMeteorCast:Start()--7 seconds from boss yell the meteor impacts.
			timerMeteorCD:Start()
		end
		if mod:LatencyCheck() then
			self:SendSync("Meteor")
		end
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.twilightcutter or msg:find(L.twilightcutter) then
			specWarnTwilightCutter:Schedule(3)
		if not self.Options.AnnounceAlternatePhase then
			timerTwilightCutterCD:Cancel()
			warningTwilightCutter:Show()
			sndWOP:Play("cutsoon")
			sndWOP:Schedule(1.2, "countthree")
			sndWOP:Schedule(2, "counttwo")
			sndWOP:Schedule(2.8, "countone")			
			sndWOP:Schedule(3.3, "cutnow")
			timerTwilightCutterCast:Start()
			timerTwilightCutter:Schedule(3)--Delay it since it happens 5 seconds after the emote
			timerTwilightCutterCD:Schedule(15)
		end
		if mod:LatencyCheck() then
			self:SendSync("TwilightCutter")
		end
	end
end

function mod:OnSync(msg, target)
	if msg == "TwilightCutter" then
		if self.Options.AnnounceAlternatePhase then
			timerTwilightCutterCD:Cancel()
			warningTwilightCutter:Show()
			sndWOP:Play("cutsoon")
			sndWOP:Schedule(1.2, "countthree")
			sndWOP:Schedule(2, "counttwo")
			sndWOP:Schedule(2.8, "countone")			
			sndWOP:Schedule(3.3, "cutnow")
			timerTwilightCutterCast:Start()
			timerTwilightCutter:Schedule(3)--Delay it since it happens 5 seconds after the emote
			timerTwilightCutterCD:Schedule(15)
		end
	elseif msg == "Meteor" then
		if self.Options.AnnounceAlternatePhase then
			warningMeteor:Show()
			sndWOP:Play("meteorrun")
			timerMeteorCast:Start()
			timerMeteorCD:Start()
		end
	elseif msg == "ShadowTarget" then
		if self.Options.AnnounceAlternatePhase then
			warningShadowConsumption:Show(target)
			if IsRaidLeader() and self.Options.WhisperOnConsumption then
				self:SendWhisper(L.WhisperConsumption, args.destName)
			end
		end
	elseif msg == "FieryTarget" then
		if self.Options.AnnounceAlternatePhase then
			warningFieryConsumption:Show(target)
			if IsRaidLeader() and self.Options.WhisperOnConsumption then
				self:SendWhisper(L.WhisperCombustion, args.destName)
			end
		end
	elseif msg == "ShadowCD" then
		if self.Options.AnnounceAlternatePhase then
			if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
				timerShadowConsumptionCD:Start(20)
			else
				timerShadowConsumptionCD:Start()
			end
		end
	elseif msg == "FieryCD" then
		if self.Options.AnnounceAlternatePhase then
			if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
				timerFieryConsumptionCD:Start(20)
			else
				timerFieryConsumptionCD:Start()
			end
		end
	elseif msg == "Phase3" then
		updateHealthFrame(3)
		warnPhase3:Show()
		timerMeteorCD:Start(30) --These i'm not sure if they start regardless of drake aggro, or if it varies as well.
		timerFieryConsumptionCD:Start(20)--not exact, 15 seconds from tank aggro, but easier to add 5 seconds to it as a estimate timer than trying to detect this
	end
end
