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
local warnOverlordsBrand		= mod:NewTargetAnnounce(69172, 4)
local warnHoarfrost				= mod:NewTargetAnnounce(69246, 2)

local specWarnHoarfrost			= mod:NewSpecialWarning("specWarnHoarfrost")
local specWarnHoarfrostNear		= mod:NewSpecialWarning("specWarnHoarfrostNear")
local specWarnIcyBlast			= mod:NewSpecialWarningMove(69628)
local specWarnOverlordsBrand	= mod:NewSpecialWarningYou(69172)

local timerCombatStart			= mod:NewCombatTimer(40)
local timerOverlordsBrand		= mod:NewTargetTimer(8, 69172)
local timerUnholyPower			= mod:NewBuffActiveTimer(10, 69629)
local timerForcefulSmash		= mod:NewCDTimer(50, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.IMPORTANT_ICON) --hotfixed? new combat logs show it every 50 seconds'ish.(16.0, 24814, nil, nil, nil, 3)
-- mod:NewCDTimer(25, 20566, nil, nil, nil, 2, nil, DBM_CORE_L.IMPORTANT_ICON, nil, mod:IsMelee() and 1, 4)

local timerForcefulSmash1		= mod:NewCDTimer(10, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.TANK_ICON)
local timerForcefulSmash2		= mod:NewCDTimer(20, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.DAMAGE_ICON)
local timerForcefulSmash3		= mod:NewCDTimer(30, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.HEALER_ICON)
local timerForcefulSmash4		= mod:NewCDTimer(40, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.TANK_ICON_SMALL)
local timerForcefulSmash5		= mod:NewCDTimer(50, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.DAMAGE_ICON_SMALL)
local timerForcefulSmash6		= mod:NewCDTimer(60, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.HEALER_ICON_SMALL)
local timerForcefulSmash7		= mod:NewCDTimer(70, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.HEROIC_ICON)
local timerForcefulSmash8		= mod:NewCDTimer(80, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.DEADLY_ICON)
local timerForcefulSmash9		= mod:NewCDTimer(90, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.HEROIC_ICON_SMALL)
local timerForcefulSmash10		= mod:NewCDTimer(100, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.POISON_ICON)
local timerForcefulSmash11		= mod:NewCDTimer(110, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.IMPORTANT_ICON)
local timerForcefulSmash12		= mod:NewCDTimer(120, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.IMPORTANT_ICON)
local timerForcefulSmash13		= mod:NewCDTimer(120, 69627, 69627, 69627, nil, 3, nil, DBM_CORE_L.DISEASE_ICON)

local sndWOP					= mod:NewAnnounce("SoundWOP", nil, nil, true)

mod:AddBoolOption("SetIconOnHoarfrostTarget", true)


function mod:OnCombatStart(delay)
	timerCombatStart:Start(-delay)
	timerForcefulSmash1:Start(-delay)
	timerForcefulSmash2:Start(-delay)
	timerForcefulSmash3:Start(-delay)
	timerForcefulSmash4:Start(-delay)
	timerForcefulSmash5:Start(-delay)
	timerForcefulSmash6:Start(-delay)
	timerForcefulSmash7:Start(-delay)
	timerForcefulSmash8:Start(-delay)
	timerForcefulSmash9:Start(-delay)
	timerForcefulSmash10:Start(-delay)
	timerForcefulSmash11:Start(-delay)
	timerForcefulSmash12:Start(-delay)
	timerForcefulSmash13:Start(-delay)
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
	end
end


--[[
function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	local target = msg and msg:match(L.HoarfrostTarget)
	if target then
		SendChatMessage("doudou", "SAY") --测试
		warnHoarfrost:Show(target)
		if target == UnitName("player") then
			specWarnHoarfrost:Show()
			sndWOP:Play("Interface\\AddOns\\DBM-Core\\DBM-VPYike\\targetyou.ogg")
		elseif target then
			local uId = DBM:GetRaidUnitId(target)
			if uId then
				local inRange = CheckInteractDistance(uId, 2)
				if inRange then
					specWarnHoarfrostNear:Show()
					sndWOP:Play("Interface\\AddOns\\DBM-Core\\DBM-VPYike\\watchorb.ogg")
				end
			end
		end
		if self.Options.SetIconOnHoarfrostTarget then
			self:SetIcon(target, 8, 5)
		end
	end
end
]]


function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target) --测试!
	--if target and (msg:match(L.HoarfrostTarget) or msg:find(L.HoarfrostTarget)) then
	--if msg == L.HoarfrostTarget or msg:match(L.HoarfrostTarget) or msg:find(L.HoarfrostTarget) then
		--SendChatMessage("sdsd", "SAY") --测试不通过
	--end
	if msg == L.HoarfrostTarget or msg:match(L.HoarfrostTarget) or msg:find(L.HoarfrostTarget) then
		--SendChatMessage("abba", "SAY") --测试通过
		if target then --可以
			warnHoarfrost:Show(target)
			--SendChatMessage(target, "SAY")
			if target == UnitName("player") then
				--SendChatMessage(target, "SAY")
				specWarnHoarfrost:Show()
				sndWOP:Play("targetyou")
			elseif target then
				local uId = DBM:GetRaidUnitId(target)
				if uId then
					local inRange = CheckInteractDistance(uId, 2)
					if inRange then
						specWarnHoarfrostNear:Show()
						sndWOP:Play("watchorb")
					end
				end
			end
			if self.Options.SetIconOnHoarfrostTarget then
				self:SetIcon(target, 8, 5)
			end
		end
	end
end