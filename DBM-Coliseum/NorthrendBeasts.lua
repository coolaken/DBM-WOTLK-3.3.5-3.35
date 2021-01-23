local mod	= DBM:NewMod("NorthrendBeasts", "DBM-Coliseum", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4385 $"):sub(12, -3))
mod:SetCreatureID(34797)
mod:SetMinCombatTime(30)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6, 7, 8)

mod:RegisterCombat("yell", L.CombatStart)

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_DAMAGE",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED"
)

-- 模板 local warnHeartRend								= mod:NewTargetCountAnnounce(334765, 4, nil, "Healer", 2, nil, nil, nil, true)
-- 要做同步才可以用这个local warningSnoboldTest	= mod:NewTargetNoFilterAnnounce(66406, 4) --狗头人出现 66046 test
local warnImpaleOn			= mod:NewTargetCountAnnounce(67477, 4, 67477, "Tank|Healer", 2, nil, nil, nil, true)
local warnToxin				= mod:NewTargetNoFilterAnnounce(66823, 4)
local warnBile				= mod:NewTargetNoFilterAnnounce(66869, 3)
local warnFireBomb			= mod:NewSpellAnnounce(66317, 3, nil, false)
local warnBreath			= mod:NewSpellAnnounce(67650, 2)
local warnRage				= mod:NewSpellAnnounce(67657, 3)
local warnSlimePool			= mod:NewSpellAnnounce(67643, 2, nil, "Melee")
local warningSnobold		= mod:NewAnnounce("WarningSnobold", 4) --狗头人出现 66046
local warnEnrageWorm		= mod:NewSpellAnnounce(68335, 3)

local specWarnSnobolledOn 	= mod:NewSpecialWarningDefensive(66406, "-Tank", nil, nil, 5, 2) --狗头人上身 test
local specWarnImpale3		= mod:NewSpecialWarning("SpecialWarningImpale3")


local specWarnAnger			= mod:NewSpecialWarningCount(66636)
local specWarnImpale		= mod:NewSpecialWarningTargetCount(67477, "Tank|Healer") --3是层数 nil 默认就是3
local specWarnFireBomb		= mod:NewSpecialWarningMove(66317)
local specWarnSlimePool		= mod:NewSpecialWarningMove(67640)
local specWarnToxin			= mod:NewSpecialWarningMove(67620)
local specWarnBile			= mod:NewSpecialWarningYou(66869)
local specWarnSilence		= mod:NewSpecialWarning("SpecialWarningSilence")
local specWarnCharge		= mod:NewSpecialWarning("SpecialWarningCharge")
local specWarnChargeNear	= mod:NewSpecialWarning("SpecialWarningChargeNear", nil, nil, nil, 4, 2) -- 第一个名字, 第二个条件, 第5个是选择警报颜色, 第六个是使用默认声音还是自定义声音
local specWarnTranq			= mod:NewSpecialWarning("SpecialWarningTranq", "RemoveEnrage", nil, nil, 1, 2)
--local warnDeepBreath		= mod:NewSpecialWarning("WarningDeepBreath", nil, nil, nil, 1, 2)

local enrageTimer			= mod:NewBerserkTimer(223)
local timerCombatStart		= mod:NewCombatTimer(23)
local timerNextBoss			= mod:NewTimer(190, "TimerNextBoss", 2457, nil, nil, 1)
local timerSubmerge			= mod:NewTimer(45, "TimerSubmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 5) 
local timerEmerge			= mod:NewTimer(10, "TimerEmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp", nil, nil, 5)

local timerPhase			= mod:NewPhaseTimer(15)
local timerBreath			= mod:NewCastTimer(5, 67650, nil, nil, nil, 2, nil, DBM_CORE_L.DEADLY_ICON) --2是aoe 
local timerNextStomp		= mod:NewNextTimer(20, 66330, nil, nil, nil, 2)
local timerNextImpale		= mod:NewNextTimer(10, 67477, nil, "Tank|Healer", nil, 3) --应该改成cd
local timerRisingAnger      = mod:NewCDTimer(20.5, 66636, 66636, nil, nil, 3, nil, DBM_CORE_L.ENRAGE_ICON) --可以加个治疗 T 注意的标记 渐怒
local timerStaggeredDaze	= mod:NewBuffActiveTimer(15, 66758, nil, nil, nil, 5)
local timerNextCrash		= mod:NewCDTimer(55, 67662, nil, nil, nil, 2)
local timerSweepCD			= mod:NewCDTimer(17, 66794, nil, "Melee", nil, 7)
local timerSlimePoolCD		= mod:NewCDTimer(12, 66883, nil, "Melee", nil, 7)
local timerAcidicSpewCD		= mod:NewCDTimer(21, 66819, nil, nil, nil, 2)
local timerMoltenSpewCD		= mod:NewCDTimer(21, 66820, nil, nil, nil, 2)
local timerParalyticSprayCD	= mod:NewCDTimer(21, 66901, nil, nil, nil, 2, nil, DBM_CORE_L.HEALER_ICON)
local timerBurningSprayCD	= mod:NewCDTimer(21, 66902, nil, nil, nil, 2, nil, DBM_CORE_L.HEALER_ICON)
local timerParalyticBiteCD	= mod:NewCDTimer(25, 66824, nil, "Tank", nil, 3, nil, DBM_CORE_L.TANK_ICON)
local timerBurningBiteCD	= mod:NewCDTimer(15, 66879, nil, "Tank", nil, 3, nil, DBM_CORE_L.TANK_ICON)

local sndWOP					= mod:NewSpecialWarning("SoundWOP", nil, nil, nil, 4, 2)

mod:AddBoolOption("PingCharge")
mod:AddBoolOption("SetIconOnChargeTarget", true)
mod:AddBoolOption("SetIconOnBileTarget", true)
mod:AddBoolOption("ClearIconsOnIceHowl", true)
mod:AddBoolOption("YellOnSnobolled", true)
mod:AddBoolOption("RangeFrame")
mod:AddBoolOption("IcehowlArrow")

local bileTargets			= {}
local toxinTargets			= {}
local burnIcon				= 8
local phases				= {}
local DreadscaleActive		= true  	-- Is dreadscale moving?
local DreadscaleDead	= false
local AcidmawDead	= false

mod.vb.phase = 0


local function updateHealthFrame(phase)
	if phases[phase] then
		return
	end
	phases[phase] = true
	if phase == 1 then
		DBM.BossHealth:Clear()
		DBM.BossHealth:AddBoss(34796, L.Gormok)
	elseif phase == 2 then
		DBM.BossHealth:AddBoss(35144, L.Acidmaw)
		DBM.BossHealth:AddBoss(34799, L.Dreadscale)
	elseif phase == 3 then
		DBM.BossHealth:AddBoss(34797, L.Icehowl)
	end
end

function mod:OnCombatStart(delay)
	table.wipe(bileTargets)
	table.wipe(toxinTargets)
	table.wipe(phases)
	burnIcon = 8
	DreadscaleActive = true
	DreadscaleDead = false
	AcidmawDead = false
	specWarnSilence:Schedule(37-delay)
	if self:IsDifficulty("heroic10", "heroic25") then
		timerNextBoss:Start(175 - delay)
		timerNextBoss:Schedule(170)
	end
	timerNextStomp:Start(38-delay)
	timerRisingAnger:Start(48-delay)
	timerCombatStart:Start(-delay)
	updateHealthFrame(1)
	self.vb.phase = 1
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide(true)
	end
end

function mod:specWarnSnobolled()
	local uId = DBM:GetRaidUnitId(UnitName("player"))
	local j = 1
	while true do
		local name = UnitDebuff(uId, j)
		j = j + 1
		if not name then
			break
		elseif name == GetSpellInfo(66406) then
			specWarnSnobolledOn:Show()
			specWarnSnobolledOn:Play("holdit")
			if self.Options.YellOnSnobolled then
				SendChatMessage("快打我的狗头啊!", "SAY")
			end
		end
	end
end

function mod:warnToxin()
	warnToxin:Show(table.concat(toxinTargets, "<, >"))
	table.wipe(toxinTargets)
	burnIcon = 8
end

function mod:warnBile()
	warnBile:Show(table.concat(bileTargets, "<, >"))
	table.wipe(bileTargets)
end

function mod:WormsEmerge()
	timerSubmerge:Show()
	if not AcidmawDead then
		if DreadscaleActive then
			timerSweepCD:Start(16)
			timerParalyticSprayCD:Start(9)			
		else
			timerSlimePoolCD:Start(14)
			timerParalyticBiteCD:Start(5)			
			timerAcidicSpewCD:Start(10)
		end
	end
	if not DreadscaleDead then
		if DreadscaleActive then
			timerSlimePoolCD:Start(14)
			timerMoltenSpewCD:Start(10)
			timerBurningBiteCD:Start(5)
		else
			timerSweepCD:Start(16)
			timerBurningSprayCD:Start(17)
		end
	end	
	self:ScheduleMethod(45, "WormsSubmerge")
end

function mod:WormsSubmerge()
	timerEmerge:Show()
	timerSweepCD:Cancel()
	timerSlimePoolCD:Cancel()
	timerMoltenSpewCD:Cancel()
	timerParalyticSprayCD:Cancel()
	timerBurningBiteCD:Cancel()
	timerAcidicSpewCD:Cancel()
	timerBurningSprayCD:Cancel()
	timerParalyticBiteCD:Cancel()
	DreadscaleActive = not DreadscaleActive
	self:ScheduleMethod(10, "WormsEmerge")
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(67477, 66331, 67478, 67479) then		-- Impale
		warnImpaleOn:CombinedShow(nil, 1, args.destName)
		timerNextImpale:Start()
	elseif args:IsSpellID(67657, 66759, 67658, 67659) then    -- Frothing Rage
		local target = self:GetBossTarget(34797)
		warnRage:Show()
		specWarnTranq:Show()
		specWarnTranq:Play("dispelboss")
		--[[
		if mod:CanRemoveEnrage() then
			DBM:PlaySoundFile("Interface\\AddOns\\DBM-VPYike\\dispelboss.ogg")
		end
		]]
		if mod:IsTank() and target then
			sndWOP:Play("holdit")
		elseif mod:IsHealer() then
			sndWOP:Play("tankheal")
		end
	elseif args:IsSpellID(66823, 67618, 67619, 67620) then	-- Paralytic Toxin
		self:UnscheduleMethod("warnToxin")
		toxinTargets[#toxinTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnToxin:Show()
			sndWOP:Play("poisonrun")
		end
		if self.Options.SetIconOnBileTarget and burnIcon > 0 then
			self:SetIcon(args.destName, burnIcon, 15)
			burnIcon = burnIcon - 1
		end
		mod:ScheduleMethod(0.2, "warnToxin")
	elseif args:IsSpellID(66869) then		-- Burning Bile
		self:UnscheduleMethod("warnBile")
		bileTargets[#bileTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnBile:Show()
			if not mod:IsTank() then
				sndWOP:Play("runout")
			end
		end
		mod:ScheduleMethod(0.2, "warnBile")
	elseif args:IsSpellID(66758) then
		timerStaggeredDaze:Start()
	elseif args:IsSpellID(66636) then						-- Rising Anger
		specWarnAnger:Show(1)
		mod:ScheduleMethod(2.5, "specWarnSnobolled")
		warningSnobold:Show()
		timerRisingAnger:Show()
	elseif args:IsSpellID(68335) then
		warnEnrageWorm:Show()
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(67477, 66331, 67478, 67479) then		-- Impale
		warnImpaleOn:CombinedShow(nil, args.amount, args.destName)
		timerNextImpale:Start()
		if (args.amount >= 3 and not self:IsDifficulty("heroic10", "heroic25") ) or ( args.amount >= 2 and self:IsDifficulty("heroic10", "heroic25") ) then 
			if mod:IsTank() or mod:IsHealer() then
				specWarnImpale:Show(args.amount, args.destName)
			end
		end
	elseif args:IsSpellID(66636) then						-- Rising Anger
		specWarnAnger:Show(args.amount)
		mod:ScheduleMethod(2.5, "specWarnSnobolled")
		warningSnobold:Show()
		timerRisingAnger:Show()
		if args.amount < 3 then
			
		elseif args.amount >= 3 then
			  --可以加个换T嘲讽?
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(66689, 67650, 67651, 67652) then			-- Arctic Breath
		specWarnChargeNear:Show()
		timerBreath:Start()
		warnBreath:Show()
	elseif args:IsSpellID(66313) then							-- FireBomb (Impaler)
		warnFireBomb:Show()
	elseif args:IsSpellID(66330, 67647, 67648, 67649) then		-- Staggering Stomp
		timerNextStomp:Start()
		specWarnSilence:Schedule(19)							-- prewarn ~1,5 sec before next
	elseif args:IsSpellID(66794, 67644, 67645, 67646) then		-- Sweep stationary worm
		timerSweepCD:Start()
	elseif args:IsSpellID(66821) then							-- Molten spew
		timerMoltenSpewCD:Start()
	elseif args:IsSpellID(66818) then							-- Acidic Spew
		timerAcidicSpewCD:Start()
	elseif args:IsSpellID(66901, 67615, 67616, 67617) then		-- Paralytic Spray
		timerParalyticSprayCD:Start()
	elseif args:IsSpellID(66902, 67627, 67628, 67629) then		-- Burning Spray
		timerBurningSprayCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(67641, 66883, 67642, 67643) then			-- Slime Pool Cloud Spawn
		warnSlimePool:Show()
		timerSlimePoolCD:Show()
	elseif args:IsSpellID(66824, 67612, 67613, 67614) then		-- Paralytic Bite
		timerParalyticBiteCD:Start()
	elseif args:IsSpellID(66879, 67624, 67625, 67626) then		-- Burning Bite
		timerBurningBiteCD:Start()
	end
end

function mod:SPELL_DAMAGE(args)
	if args:IsPlayer() and (args:IsSpellID(66320, 67472, 67473, 67475) or args:IsSpellID(66317)) then	-- Fire Bomb (66317 is impact damage, not avoidable but leaving in because it still means earliest possible warning to move. Other 4 are tick damage from standing in it)
		specWarnFireBomb:Show()
		sndWOP:Play("runaway")
	elseif args:IsPlayer() and args:IsSpellID(66881, 67638, 67639, 67640) then							-- Slime Pool
		specWarnSlimePool:Show()
		sndWOP:Play("runaway")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target)
	if msg:match(L.Charge) or msg:find(L.Charge) then
		timerNextCrash:Start()
		sndWOP:ScheduleVoice(50, "scattersoon")
		--sndWOP:ScheduleVoice(50, "ex_tt_cfkd")
		if self.Options.ClearIconsOnIceHowl then
			self:ClearIcons()
		end
		if target == UnitName("player") then
--[[			local x, y = GetPlayerMapPosition(target)
			if x == 0 and y == 0 then
				SetMapToCurrentZone()
				x, y = GetPlayerMapPosition(target)
			end--]]
			specWarnCharge:Show()
--			DBM.Arrow:ShowRunAway(x, y, 12, 5)
			sndWOP:Play("ex_tt_nbcf")
			if self.Options.PingCharge then
				Minimap:PingLocation()
			end
		else
			local uId = DBM:GetRaidUnitId(target)
			if uId then
				local inRange = CheckInteractDistance(uId, 2)
				local x, y = GetPlayerMapPosition(uId)
				if x == 0 and y == 0 then
					SetMapToCurrentZone()
					x, y = GetPlayerMapPosition(uId)
				end
				if inRange then
					specWarnChargeNear:Show()
					sndWOP:Play("chargemove")
					if self.Options.IcehowlArrow then
						DBM.Arrow:ShowRunAway(x, y, 12, 5)
					end
				end
			end
		end
		if self.Options.SetIconOnChargeTarget then
			self:SetIcon(target, 8, 5)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Phase2 or msg:find(L.Phase2) then
		self:ScheduleMethod(17, "WormsEmerge")
		timerPhase:Start(15)
		updateHealthFrame(2)
		self.vb.phase = 2
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(10, nil, true, nil)
		end
	elseif msg == L.Phase3 or msg:find(L.Phase3) then
		updateHealthFrame(3)
		if self:IsDifficulty("heroic10", "heroic25") then
			enrageTimer:Start()
		end
		self:UnscheduleMethod("WormsSubmerge")
		timerPhase:Start(13)
		self.vb.phase = 3
		timerNextCrash:Start(45)
		sndWOP:ScheduleVoice(40, "scattersoon")
		timerNextBoss:Cancel()
		timerSubmerge:Cancel()
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide(true)
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 34796 then
		specWarnSilence:Cancel()
		timerNextStomp:Stop()
		timerNextImpale:Stop()
		DBM.BossHealth:RemoveBoss(cid) -- remove Gormok from the health frame
	elseif cid == 35144 then
		AcidmawDead = true
		timerParalyticSprayCD:Cancel()
		timerParalyticBiteCD:Cancel()
		timerAcidicSpewCD:Cancel()
		if DreadscaleActive then
			timerSweepCD:Cancel()
		else
			timerSlimePoolCD:Cancel()
		end
		if DreadscaleDead then
			DBM.BossHealth:RemoveBoss(35144)
			DBM.BossHealth:RemoveBoss(34799)
		end
	elseif cid == 34799 then
		DreadscaleDead = true
		timerBurningSprayCD:Cancel()
		timerBurningBiteCD:Cancel()
		timerMoltenSpewCD:Cancel()
		if DreadscaleActive then
			timerSlimePoolCD:Cancel()
		else
			timerSweepCD:Cancel()
		end
		if AcidmawDead then
			DBM.BossHealth:RemoveBoss(35144)
			DBM.BossHealth:RemoveBoss(34799)
		end
	end
end
