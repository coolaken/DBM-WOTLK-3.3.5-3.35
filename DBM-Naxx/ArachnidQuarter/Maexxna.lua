local mod	= DBM:NewMod("Maexxna", "DBM-Naxx", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2943 $"):sub(12, -3))
mod:SetCreatureID(15952)

mod:RegisterCombat("combat")


mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"CHAT_MSG_MONSTER_EMOTE",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"SPELL_CAST_SUCCESS"
)

local warnWebWrap		= mod:NewTargetNoFilterAnnounce(28622, 2)
local warnWebSpraySoon	= mod:NewSoonAnnounce(29484, 1)
local warnWebSprayNow	= mod:NewSpellAnnounce(29484, 3)
local warnSpidersSoon	= mod:NewAnnounce("WarningSpidersSoon", 2, 17332)
local warnSpidersNow	= mod:NewAnnounce("WarningSpidersNow", 4, 17332)

local timerWebSpray		= mod:NewNextTimer(40.5, 29484)
local timerSpider		= mod:NewTimer(30, "TimerSpider", 17332)

function mod:OnCombatStart(delay)
	warnWebSpraySoon:Schedule(35.5 - delay)
	timerWebSpray:Start(40.5 - delay)
	warnSpidersSoon:Schedule(25 - delay)
	warnSpidersNow:Schedule(30 - delay)
	timerSpider:Start(30 - delay)
end

function mod:OnCombatEnd(wipe)
	if not wipe then
		if DBM.Bars:GetBar(L.ArachnophobiaTimer) then
			DBM.Bars:CancelBar(L.ArachnophobiaTimer) 
		end	
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(28622) then -- Web Wrap
		warnWebWrap:Show(args.destName)
		if args.destName == UnitName("player") then
			SendChatMessage(L.YellWebWrap, "YELL")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(29484, 54125) then -- Web Spray
		warnWebSprayNow:Show()
		warnWebSpraySoon:Schedule(35.5)
		timerWebSpray:Start()
		warnSpidersSoon:Schedule(25)
		warnSpidersNow:Schedule(30)
		timerSpider:Start()
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg == L.PenShe or msg:find(L.PenShe) then
		warnWebSprayNow:Show()
		warnWebSpraySoon:Schedule(35.5)
		timerWebSpray:Start()
		warnSpidersSoon:Schedule(25)
		warnSpidersNow:Schedule(30)
		timerSpider:Start()
	end
end

mod.CHAT_MSG_RAID_BOSS_EMOTE = mod.CHAT_MSG_MONSTER_EMOTE
