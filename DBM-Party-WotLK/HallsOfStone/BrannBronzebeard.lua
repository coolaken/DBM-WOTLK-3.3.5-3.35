local mod	= DBM:NewMod("BrannBronzebeard", "DBM-Party-WotLK", 7)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4282 $"):sub(12, -3))
mod:SetCreatureID(28070)
--mod:SetZone()
mod:SetMinSyncRevision(2861)

mod:RegisterCombat("yell", L.Pull)
mod:RegisterKill("yell", L.Kill)
mod:SetMinCombatTime(50)
mod:SetWipeTime(25)

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

local warningPhase	= mod:NewAnnounce("WarningPhase", 2, "Interface\\Icons\\Spell_Nature_WispSplode")
local timerEvent	= mod:NewTimer(302, "timerEvent", "Interface\\Icons\\Spell_Holy_BorrowedTime")

local WaveAddsCd	= mod:NewAddsCustomTimer(50, 68959)

local WaveTime = 50
local WaveCount = 0


function mod:OnCombatStart(delay)
	WaveCount = 1
	timerEvent:Start(-delay)
	WaveAddsCd:Start(21-delay, WaveCount)
	self:ScheduleMethod(21-delay, "NextAdds")
end

function mod:NextAdds()
	WaveCount = WaveCount + 1
	WaveAddsCd:Start(WaveTime - WaveCount*2.5, WaveCount)
	self:UnscheduleMethod("NextAdds")
	self:ScheduleMethod(WaveTime - WaveCount*2.5, "NextAdds")
end

function mod:CHAT_MSG_MONSTER_YELL(msg, sender)
	if L.Phase1 == msg then
		warningPhase:Show(1)
	elseif msg == L.Phase2 then
		warningPhase:Show(2)
	elseif msg == L.Phase3 then
		warningPhase:Show(3)
	end
end


