local mod	= DBM:NewMod("ScourgelordTyrannus", "DBM-Party-WotLK", 15)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4373 $"):sub(12, -3))
mod:SetCreatureID(36658, 36661)
mod:SetUsedIcons(8)

mod:RegisterCombat("yell", L.CombatStart)
mod:RegisterKill("yell", L.YellCombatEnd)
mod:SetMinCombatTime(40)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_PERIODIC_DAMAGE",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

local warnUnholyPower			= mod:NewSpellAnnounce(69629, 3)
local warnForcefulSmash			= mod:NewSpellAnnounce(69627, 2)
local warnOverlordsBrand		= mod:NewTargetNoFilterAnnounce(69172, 4)
local warnHoarfrost				= mod:NewTargetNoFilterAnnounce(69246, 2)

--local specWarnGluttonousMiasma					= mod:NewSpecialWarningYouPos(48451, nil, nil, nil, 1, 2)
--local yellGluttonousMiasma						= mod:NewShortPosYell(48451, nil, false, 2)
local specWarnHoarfrost			= mod:NewSpecialWarningMoveAway(69246, nil, nil, nil, 4, 3)
local specWarnHoarfrostNear		= mod:NewSpecialWarningClose(69246, nil, nil, nil, 1, 3)
local specWarnIcyBlast			= mod:NewSpecialWarningMove(69628)
local specWarnOverlordsBrand	= mod:NewSpecialWarningYou(69172)

local timerCombatStart			= mod:NewCombatTimer(40)
local timerOverlordsBrand		= mod:NewTargetTimer(8, 69172, nil, nil, nil, 3)
local timerUnholyPower			= mod:NewBuffActiveTimer(10, 69629)
local timerForcefulSmash		= mod:NewCDTimer(46, 69155, nil, nil, nil, 3, nil, DBM_CORE_L.TANK_ICON) --hotfixed? new combat logs show it every 50 seconds'ish.(16.0, 24814, nil, nil, nil, 3)


mod:AddBoolOption("SetIconOnHoarfrostTarget", true)


function mod:OnCombatStart(delay)
	timerCombatStart:Start(-delay)
	timerForcefulSmash:Start(54-delay)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(69629, 69167) then					-- Unholy Power
        warnUnholyPower:Show()
		timerUnholyPower:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(69155, 69627) then					-- Forceful Smash
        warnForcefulSmash:Show()
        timerForcefulSmash:Start()
	end
end

do 
	local lasticyblast = 0
	function mod:SPELL_PERIODIC_DAMAGE(args)
		if args:IsSpellID(69238, 69628) and args:IsPlayer() and time() - lasticyblast > 3 then		-- Icy Blast, MOVE!
			specWarnIcyBlast:Show()
			lasticyblast = time()
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(69172) then							-- Overlord's Brand
		warnOverlordsBrand:Show(args.destName)
		timerOverlordsBrand:Show(args.destName)
		if args:IsPlayer() then
			specWarnOverlordsBrand:Show()
		end
	--elseif args:IsSpellID(48451) then
	--	specWarnGluttonousMiasma:Show(self:IconNumToTexture(1))
		--yellGluttonousMiasma:Yell(1, 1)
	end
end





function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target)
	if msg == L.HoarfrostTarget or msg:match(L.HoarfrostTarget) or msg:find(L.HoarfrostTarget) then
		if target then
			warnHoarfrost:Show(target)
			if target == UnitName("player") then
				specWarnHoarfrost:Show()
				specWarnHoarfrost:Play("targetyou")
			elseif target then
				local uId = DBM:GetRaidUnitId(target)
				if uId then
					local inRange = CheckInteractDistance(uId, 3)
					if inRange then
						specWarnHoarfrostNear:Show(target)
						specWarnHoarfrostNear:Play("watchorb")
					end
				end
			end
			if self.Options.SetIconOnHoarfrostTarget then
				self:SetIcon(target, 8, 5)
			end
		end
	end
end