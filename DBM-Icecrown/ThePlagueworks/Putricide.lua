local mod	= DBM:NewMod("Putricide", "DBM-Icecrown", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4534 $"):sub(12, -3))
mod:SetCreatureID(36678)
mod:RegisterCombat("yell", L.YellPull)
mod:SetMinSyncRevision(3860)
mod:SetUsedIcons(5, 6, 7, 8)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_AURA_REFRESH",
	"SPELL_AURA_REMOVED",
	"SPELL_DAMAGE",
	"CHAT_MSG_MONSTER_EMOTE",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_HEALTH"
)

local warnSlimePuddle				= mod:NewSpellAnnounce(70341, 2)
local warnUnstableExperimentSoon	= mod:NewSoonAnnounce(70351, 3)
local warnUnstableExperiment		= mod:NewSpellAnnounce(70351, 4)
local warnVolatileOozeAdhesive		= mod:NewTargetAnnounce(70447, 3)
local warnGaseousBloat				= mod:NewTargetAnnounce(70672, 3)
local warnPhase2Soon				= mod:NewAnnounce("WarnPhase2Soon", 2)
local warnTearGas					= mod:NewSpellAnnounce(71617, 2)		-- Phase transition normal
local warnVolatileExperiment		= mod:NewSpellAnnounce(72840, 4)		-- Phase transition heroic
local warnMalleableGoo				= mod:NewSpellAnnounce(72295, 2)		-- Phase 2 ability
local warnChokingGasBombSoon		= mod:NewPreWarnAnnounce(71255, 5, 3, nil, "Melee")
local warnChokingGasBomb			= mod:NewSpellAnnounce(71255, 3, nil, "Melee")		-- Phase 2 ability
local warnPhase3Soon				= mod:NewAnnounce("WarnPhase3Soon", 2)
local warnMutatedPlague				= mod:NewAnnounce("WarnMutatedPlague", 2, 72451, "Tank|Healer") -- Phase 3 ability
local warnUnboundPlague				= mod:NewTargetAnnounce(72856, 3)			-- Heroic Ability

local specWarnVolatileOozeAdhesive	= mod:NewSpecialWarningYou(70447)
local specWarnGaseousBloat			= mod:NewSpecialWarningYou(70672)
local specWarnVolatileOozeOther		= mod:NewSpecialWarningTarget(70447, false)
local specWarnGaseousBloatOther		= mod:NewSpecialWarningTarget(70672, false)
local specWarnMalleableGoo			= mod:NewSpecialWarning("SpecWarnMalleableGoo")
local specWarnMalleableGooNear		= mod:NewSpecialWarning("SpecWarnMalleableGooNear")
local specWarnChokingGasBomb		= mod:NewSpecialWarningSpell(71255, "Tank")
local specWarnMalleableGooCast		= mod:NewSpecialWarningSpell(72295, false)
local specWarnOozeVariable			= mod:NewSpecialWarningYou(70352)		-- Heroic Ability
local specWarnGasVariable			= mod:NewSpecialWarningYou(70353)		-- Heroic Ability
local specWarnUnboundPlague			= mod:NewSpecialWarningYou(72856)		-- Heroic Ability

local timerGaseousBloat				= mod:NewTargetTimer(20, 70672, nil, nil, nil, 3)			-- Duration of debuff
local timerSlimePuddleCD			= mod:NewCDTimer(35, 70341, nil, nil, nil, 2)			 -- Approx
local timerUnstableExperimentCD		= mod:NewNextTimer(38, 70351, nil, nil, nil, 1)			-- Used every 38 seconds exactly except after phase changes
local timerChokingGasBombCD			= mod:NewNextTimer(35.5, 71255, nil, nil, nil, 2)
local timerMalleableGooCD			= mod:NewCDTimer(25, 72295, nil, nil, nil, 3, nil, DBM_CORE_L.IMPORTANT_ICON)
local timerTearGas					= mod:NewBuffActiveTimer(16, 71615, nil, nil, nil, 5)
local timerPotions					= mod:NewBuffActiveTimer(30, 73122, nil, nil, nil, 6)
local timerMutatedPlagueCD			= mod:NewCDTimer(10, 72451, nil, nil, nil, 3, nil, L.ENRAGE_ICON)				-- 10 to 11
local timerUnboundPlagueCD			= mod:NewNextTimer(60, 72856, nil, nil, nil, 3, nil, DBM_CORE_L.HEROIC_ICON)
local timerUnboundPlague			= mod:NewBuffActiveTimer(12, 72856, nil, nil, nil, 3, nil, DBM_CORE_L.HEROIC_ICON)		-- Heroic Ability: we can't keep the debuff 60 seconds, so we have to switch at 12-15 seconds. Otherwise the debuff does to much damage!

-- buffs from "Drink Me"
local timerMutatedSlash				= mod:NewTargetTimer(20, 70542)
local timerRegurgitatedOoze			= mod:NewTargetTimer(20, 70539)

local berserkTimer					= mod:NewBerserkTimer(600)

--local soundGaseousBloat 			= mod:NewSound(72455)
local sndWOP					= mod:NewAnnounce("SoundWOP", nil, nil, true)

mod:AddBoolOption("OozeAdhesiveIcon")
mod:AddBoolOption("GaseousBloatIcon")
mod:AddBoolOption("MalleableGooIcon")
mod:AddBoolOption("UnboundPlagueIcon")					-- icon on the player with active buff
mod:AddBoolOption("GooArrow")
mod:AddBoolOption("YellOnMalleableGoo", true, "announce")
--mod:AddBoolOption("YellOnUnbound", false, "announce")
mod:AddBoolOption("YellOnUnboundUrgent", true, "announce")
mod:AddBoolOption("BypassLatencyCheck", false)--Use old scan method without syncing or latency check (less reliable but not dependant on other DBM users in raid)

local warned_preP2 = false
local warned_preP3 = false
local spamPuddle = 0
local spamGas = 0
--local phase = 0
local glime = true

local function UnboundUrgent()
	SendChatMessage(L.YellUnboundUrgent, "YELL")
end

function mod:OnCombatStart(delay)
	berserkTimer:Start(-delay)
	timerSlimePuddleCD:Start(10-delay)
	timerUnstableExperimentCD:Start(30-delay)
	warnUnstableExperimentSoon:Schedule(25-delay)
	warned_preP2 = false
	warned_preP3 = false
	glime = true
	self.vb.phase = 1
	if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
		timerUnboundPlagueCD:Start(10-delay)
	end
end

function mod:MalleableGooTarget()
	local targetname = self:GetBossTarget(36678)
	if not targetname then return end
	if mod:LatencyCheck() then--Only send sync if you have low latency.
		self:SendSync("GooOn", targetname)
	end
end

function mod:OldMalleableGooTarget()
	local targetname = self:GetBossTarget(36678)
	if not targetname then return end
		if self.Options.MalleableGooIcon then
			self:SetIcon(targetname, 6, 10)
		end
	if targetname == UnitName("player") then
		specWarnMalleableGoo:Show()
		sndWOP:Play("runaway")
		if self.Options.YellOnMalleableGoo then
			SendChatMessage(L.YellMalleable, "SAY")
		end
	elseif targetname then
		local uId = DBM:GetRaidUnitId(targetname)
		if uId then
			local inRange = CheckInteractDistance(uId, 2)
			local x, y = GetPlayerMapPosition(uId)
			if x == 0 and y == 0 then
				SetMapToCurrentZone()
				x, y = GetPlayerMapPosition(uId)
			end
			if inRange then
				specWarnMalleableGooNear:Show()
				sndWOP:Play("runaway")
				if self.Options.GooArrow then
					DBM.Arrow:ShowRunAway(x, y, 10, 5)
				end
			end
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(70351, 71966, 71967, 71968) then
		warnUnstableExperimentSoon:Cancel()
		warnUnstableExperiment:Show()
		timerUnstableExperimentCD:Start()
		warnUnstableExperimentSoon:Schedule(33)
		if glime then
			sndWOP:ScheduleVoice(3, "gslime")
			sndWOP:ScheduleVoice(7, "ex_so_rnkd")
			glime = false
		else
			sndWOP:ScheduleVoice(3, "rslime")
			sndWOP:ScheduleVoice(7, "ex_so_rnkd")
			glime = true
		end
	elseif args:IsSpellID(71617) then				--Tear Gas, normal phase change trigger
		warnTearGas:Show()
		sndWOP:Play("phasechange")
	elseif args:IsSpellID(72842, 72843) then		--Volatile Experiment (heroic phase change begin)
		warnVolatileExperiment:Show()		
	elseif args:IsSpellID(72851, 72852) then		--Create Concoction (Heroic phase change end)
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
		--	self:ScheduleMethod(40, "NextPhase")	--May need slight tweaking +- a second or two
			timerPotions:Start()
		end
	elseif args:IsSpellID(73121, 73122) then		--Guzzle Potions (Heroic phase change end)
		if mod:IsDifficulty("heroic10") then
		--	self:ScheduleMethod(40, "NextPhase")	--May need slight tweaking +- a second or two
			timerPotions:Start()
		elseif mod:IsDifficulty("heroic25") then
		--	self:ScheduleMethod(30, "NextPhase")
			timerPotions:Start(20)
		end
	elseif args:IsSpellID(70853) then
		SendChatMessage("test1a", "SAY")
		SendChatMessage(args.destName.."70853Start", "WHISPER", nil, "一锤定音")
	elseif args:IsSpellID(72458) then
		SendChatMessage("test2a", "SAY")
		SendChatMessage(args.destName.."72458Start", "WHISPER", nil, "一锤定音")
	elseif args:IsSpellID(72873) then
		SendChatMessage("test3a", "SAY")
		SendChatMessage(args.destName.."72873Start", "WHISPER", nil, "一锤定音")
	elseif args:IsSpellID(72874) then
		SendChatMessage("test4a", "SAY")
		SendChatMessage(args.destName.."72874Start", "WHISPER", nil, "一锤定音")
	elseif args:IsSpellID(70852) then
		SendChatMessage("test5a", "SAY")
		SendChatMessage(args.destName.."70852Start", "WHISPER", nil, "一锤定音")
	end
end


--[[
function mod:NextPhase()
	self.vb.phase = self.vb.phase + 1
	if self.vb.phase == 2 then
		warnUnstableExperimentSoon:Schedule(15)
		timerUnstableExperimentCD:Start(20)
		timerSlimePuddleCD:Start(10)
		timerMalleableGooCD:Start(9)
		timerChokingGasBombCD:Start(15)
		warnChokingGasBombSoon:Schedule(10)
		if mod:IsMelee() then
			sndWOP:ScheduleVoice(12, "bombsoon")
		end
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerUnboundPlagueCD:Start(50)
		end
	elseif self.vb.phase == 3 then
		timerSlimePuddleCD:Start(15)
		timerMalleableGooCD:Start(9)
		timerChokingGasBombCD:Start(12)
		warnChokingGasBombSoon:Schedule(7)
		if mod:IsMelee() then
			sndWOP:ScheduleVoice(9, "bombsoon")
		end
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerUnboundPlagueCD:Start(50)
		end
	end
end
]]

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(70341) and GetTime() - spamPuddle > 5 then
		warnSlimePuddle:Show()
		if self.vb.phase == 3 then
			timerSlimePuddleCD:Start(20)--In phase 3 it's faster 
		else
			timerSlimePuddleCD:Start()
		end
		spamPuddle = GetTime()
	elseif args:IsSpellID(71255) then
		warnChokingGasBomb:Show()
		specWarnChokingGasBomb:Show()
		timerChokingGasBombCD:Start()
		warnChokingGasBombSoon:Schedule(30.5)
		sndWOP:Play("gasbomb")
		if mod:IsMelee() then
			sndWOP:ScheduleVoice(32, "bombsoon")
		end
	elseif args:IsSpellID(72855, 72856, 70911) then
		timerUnboundPlagueCD:Start()
	elseif args:IsSpellID(72615, 72295, 74280, 74281) then
		warnMalleableGoo:Show()
		specWarnMalleableGooCast:Show()
		sndWOP:Play("greenball")
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerMalleableGooCD:Start(20)
		else
			timerMalleableGooCD:Start()
		end
		if self.Options.BypassLatencyCheck then
			self:ScheduleMethod(0.1, "OldMalleableGooTarget")
		else
			self:ScheduleMethod(0.1, "MalleableGooTarget")
		end
	elseif args:IsSpellID(70853) then
		--if mod:LatencyCheck() then--Only send sync if you have low latency.
		self:SendSync("GooOn", args.destName)
		--end
		SendChatMessage("test1", "SAY")
		SendChatMessage(args.destName.."70853", "WHISPER", nil, "一锤定音")
	elseif args:IsSpellID(72458) then
		SendChatMessage("test2", "SAY")
		SendChatMessage(args.destName.."72458", "WHISPER", nil, "一锤定音")
	elseif args:IsSpellID(72873) then
		SendChatMessage("test3", "SAY")
		SendChatMessage(args.destName.."72873", "WHISPER", nil, "一锤定音")
	elseif args:IsSpellID(72874) then
		SendChatMessage("test4", "SAY")
		SendChatMessage(args.destName.."72874", "WHISPER", nil, "一锤定音")
	elseif args:IsSpellID(70852) then
		SendChatMessage("test5", "SAY")
		SendChatMessage(args.destName.."70852", "WHISPER", nil, "一锤定音")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(70447, 72836, 72837, 72838) then--Green Slime
		warnVolatileOozeAdhesive:Show(args.destName)
		specWarnVolatileOozeOther:Show(args.destName)
		if args:IsPlayer() then
			specWarnVolatileOozeAdhesive:Show()
		end
		-- 可以写点什么 靠近之类的!
		if self.Options.OozeAdhesiveIcon then
			self:SetIcon(args.destName, 8, 8)
		end
	elseif args:IsSpellID(72615, 72295, 74280, 74281) then --延展 不知道是不是这id!
		args.destName = UnitName("player")

	elseif args:IsSpellID(70672, 72455, 72832, 72833) then	--Red Slime
		warnGaseousBloat:Show(args.destName)
		specWarnGaseousBloatOther:Show(args.destName)
		timerGaseousBloat:Start(args.destName)
		if args:IsPlayer() then
			specWarnGaseousBloat:Show()
			--soundGaseousBloat:Play()
		end
		if self.Options.GaseousBloatIcon then
			self:SetIcon(args.destName, 7, 20)
		end
	elseif args:IsSpellID(71615, 71618) then	--71615 used in 10 and 25 normal, 71618?
		timerTearGas:Start()
	elseif args:IsSpellID(72451, 72463, 72671, 72672) then	-- Mutated Plague
		warnMutatedPlague:Show(args.spellName, args.destName, args.amount or 1)
		timerMutatedPlagueCD:Start()
	elseif args:IsSpellID(70542) then
		timerMutatedSlash:Show(args.destName)
	elseif args:IsSpellID(70539, 72457, 72875, 72876) then
		timerRegurgitatedOoze:Show(args.destName)
	elseif args:IsSpellID(70352, 74118) then	--Ooze Variable
		if args:IsPlayer() then
			specWarnOozeVariable:Show()
			sndWOP:Play("gslime")
		end
	elseif args:IsSpellID(70353, 74119) then	-- Gas Variable
		if args:IsPlayer() then
			specWarnGasVariable:Show()
			sndWOP:Play("rslime")
		end
	elseif args:IsSpellID(72855, 72856, 70911) then	 -- Unbound Plague
		warnUnboundPlague:Show(args.destName)
		if self.Options.UnboundPlagueIcon then
			self:SetIcon(args.destName, 5, 20)
		end
		if args:IsPlayer() then
			specWarnUnboundPlague:Show()
			timerUnboundPlague:Start()
			--specWarnUnboundPlague:Schedule(10)
			--self:ScheduleMethod(3, "AcquireTargetForUnboundPlague")		-- we acquire target after 3 sec, 7 sec to get the target positioned must be enough ^^^
			local plaguesickness = GetSpellInfo(73117)
			local	hasplaguesickness = 0
			local _, _, _, count = UnitDebuff("player", plaguesickness)
			if count and count == 1 then
				hasplaguesickness = 1
			elseif count and count > 1 then
				hasplaguesickness = 2
			end
			if mod:IsDifficulty("heroic10") and hasplaguesickness == 0 then
				sndWOP:ScheduleVoice(10, "transplague")
				if self.Options.YellOnUnboundUrgent then
					self:Unschedule(UnboundUrgent)
					self:Schedule(10, UnboundUrgent)
				end
			elseif mod:IsDifficulty("heroic25") and hasplaguesickness == 0 then
				sndWOP:ScheduleVoice(8, "transplague")
				if self.Options.YellOnUnboundUrgent then
					self:Unschedule(UnboundUrgent)
					self:Schedule(8, UnboundUrgent)
				end
			elseif hasplaguesickness == 1 then
				sndWOP:ScheduleVoice(4, "transplague")
				if self.Options.YellOnUnboundUrgent then
					self:Unschedule(UnboundUrgent)
					self:Schedule(4, UnboundUrgent)
				end
			elseif hasplaguesickness == 2 then
				sndWOP:Play("transplague")
				if self.Options.YellOnUnboundUrgent then
					SendChatMessage(L.YellUnboundUrgent, "YELL")
				end
			end
--			if self.Options.YellOnUnbound then
--				SendChatMessage(L.YellUnbound, "SAY")
--			end
		end
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(72451, 72463, 72671, 72672) then	-- Mutated Plague
		warnMutatedPlague:Show(args.spellName, args.destName, args.amount or 1)
		timerMutatedPlagueCD:Start()
	elseif args:IsSpellID(70542) then
		timerMutatedSlash:Show(args.destName)
	end
end

function mod:SPELL_AURA_REFRESH(args)
	if args:IsSpellID(70539, 72457, 72875, 72876) then
		timerRegurgitatedOoze:Show(args.destName)
	elseif args:IsSpellID(70542) then
		timerMutatedSlash:Show(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(70447, 72836, 72837, 72838) then
		if self.Options.OozeAdhesiveIcon then
			self:SetIcon(args.destName, 0)
		end
	elseif args:IsSpellID(70672, 72455, 72832, 72833) then
		timerGaseousBloat:Cancel(args.destName)
		if self.Options.GaseousBloatIcon then
			self:SetIcon(args.destName, 0)
		end
	elseif args:IsSpellID(72855, 72856, 70911) then 						-- Unbound Plague
		timerUnboundPlague:Stop(args.destName)
		if self.Options.UnboundPlagueIcon then
			self:SetIcon(args.destName, 0)
		end
		if args:IsPlayer() and self.Options.YellOnUnboundUrgent then
			self:Unschedule(UnboundUrgent)
			sndWOP:CancelVoice("transplague")
		end
	elseif args:IsSpellID(71615, 71618) and GetTime() - spamGas > 5 then 	-- Tear Gas Removal
		--self:NextPhase()
		spamGas = GetTime()
	elseif args:IsSpellID(70539, 72457, 72875, 72876) then
		timerRegurgitatedOoze:Cancel(args.destName)
	elseif args:IsSpellID(70542) then
		timerMutatedSlash:Cancel(args.destName)
	end
end

function mod:SPELL_DAMAGE(args)
	if args:IsSpellID(70346, 72456, 72868, 72869) and args:IsPlayer() then
		sndWOP:Play("runaway")
	end
end

--values subject to tuning depending on dps and his health pool
function mod:UNIT_HEALTH(uId)
	if self.vb.phase == 1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 36678 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.83 then
		warned_preP2 = true
		warnPhase2Soon:Show()	
		sndWOP:Play("ptwo")
	elseif self.vb.phase == 2 and not warned_preP3 and self:GetUnitCreatureId(uId) == 36678 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.38 then
		warned_preP3 = true
		warnPhase3Soon:Show()	
		sndWOP:Play("pthree")
	end
end

function mod:OnSync(msg, target)
	if msg == "GooOn" then
		if not self.Options.BypassLatencyCheck then
			if self.Options.MalleableGooIcon then
				self:SetIcon(target, 6, 10)
			end
			if target == UnitName("player") then
				specWarnMalleableGoo:Show()
				sndWOP:Play("runaway")
				if self.Options.YellOnMalleableGoo then
					SendChatMessage(L.YellMalleable, "SAY")
				end
			elseif target then
				local uId = DBM:GetRaidUnitId(target)
				if uId then
					local inRange = CheckInteractDistance(uId, 2)
					local x, y = GetPlayerMapPosition(uId)
					if x == 0 and y == 0 then
						SetMapToCurrentZone()
						x, y = GetPlayerMapPosition(uId)
					end
					if inRange then
						specWarnMalleableGooNear:Show()
						sndWOP:Play("runaway")
						if self.Options.GooArrow then
							DBM.Arrow:ShowRunAway(x, y, 10, 5)
						end
					end
				end
			end
		end
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if (msg == L.Yanzhan or msg:find(L.Yanzhan)) or (msg == L.Yanzhan2 or msg:find(L.Yanzhan2)) then
		warnMalleableGoo:Show()
		specWarnMalleableGooCast:Show()
		SendChatMessage("\124cff71d5ff\124Hspell:70852\124h[可延展黏液]\124h\124r".." 快躲开", "SAY")
		self:SendSync("GooOn", "化羽")
		sndWOP:Play("greenball")
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerMalleableGooCD:Start(20)
		else
			timerMalleableGooCD:Start()
		end
		--if self.Options.BypassLatencyCheck then
			--self:ScheduleMethod(0.1, "OldMalleableGooTarget")
		--else
		--	self:ScheduleMethod(0.1, "MalleableGooTarget")
		--end
	end
end


--mod.CHAT_MSG_MONSTER_EMOTE = mod.CHAT_MSG_RAID_BOSS_EMOTE

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L.YellPhase or msg:find(L.YellPhase)) then
		-- 快打小怪 大概30 秒 40 秒转换阶段了
		sndWOP:Play("phasechange")

	elseif (msg == L.YellPhase2 or msg:find(L.YellPhase2)) then
		self.vb.phase = 2
	-- PT10 嗯，什么感觉也没有。什么？！这是哪儿来的？|| p2 0:56   延展1:11   软泥潭1:10 1:45 毒气弹1:21 不稳定实验 1:35  红软 1:38 绿软 2:23 
	-- 味道像……樱桃！哦！见笑了！ p3 3:40   软泥摊 3:55 4:30   毒气弹 4:11 48 延展 4:21
	--H10  两泥，一室。会有无限惊喜哦！ p2 1:07 嗯，什么感觉也没有。什么？！这是哪儿来的？ 1:44 延展1:57 20秒cd H 两泥，一室。会有无限惊喜哦！4:10 味道像……樱桃！哦！见笑了！ 4:46    延展 4:56
	-- 
	--H25  两泥，一室。会有无限惊喜哦！ p2 1:12  嗯，什么感觉也没有。什么？！这是哪儿来的？ 1:46 延展2:11  两泥，一室。会有无限惊喜哦！4:11   味道像……樱桃！哦！见笑了！ 4:34  延展 5:00
	--H25  两泥，一室。会有无限惊喜哦！ p2 1:19  嗯，什么感觉也没有。什么？！这是哪儿来的？ 1:59
		warnUnstableExperimentSoon:Cancel()
		warnChokingGasBombSoon:Cancel()
		if mod:IsMelee() then
			sndWOP:CancelVoice("bombsoon")
		end
		timerUnstableExperimentCD:Cancel()
		timerMalleableGooCD:Cancel()
		timerSlimePuddleCD:Cancel()
		timerChokingGasBombCD:Cancel()
		timerUnboundPlagueCD:Cancel()
		--难度判断吗?
		warnUnstableExperimentSoon:Schedule(35) --15 
		timerUnstableExperimentCD:Start(40) --20
		timerSlimePuddleCD:Start(14) --10 
		timerMalleableGooCD:Start(15)--9
		timerChokingGasBombCD:Start(25)--15
		warnChokingGasBombSoon:Schedule(20) --10
		if mod:IsMelee() then
			sndWOP:ScheduleVoice(22, "bombsoon")
		end
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerUnboundPlagueCD:Start(50)
		else

		end

	elseif (msg == L.YellPhase3 or msg:find(L.YellPhase3)) then
		self.vb.phase = 3
		warnUnstableExperimentSoon:Cancel()
		warnChokingGasBombSoon:Cancel()
		if mod:IsMelee() then
			sndWOP:CancelVoice("bombsoon")
		end
		timerUnstableExperimentCD:Cancel()
		timerMalleableGooCD:Cancel()
		timerSlimePuddleCD:Cancel()
		timerChokingGasBombCD:Cancel()
		timerUnboundPlagueCD:Cancel()
 		--难度判断吗?
		timerSlimePuddleCD:Start(15) --15 -- 有的H是25秒!
		timerMalleableGooCD:Start(40) --9 有的H25又是32秒
		timerChokingGasBombCD:Start(30) --12
		warnChokingGasBombSoon:Schedule(25) --7 有的H25又是30秒
		if mod:IsMelee() then
			sndWOP:ScheduleVoice(27, "bombsoon")
		end
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerUnboundPlagueCD:Start(50)
		else

		end

	end
end