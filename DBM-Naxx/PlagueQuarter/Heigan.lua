local mod	= DBM:NewMod("Heigan", "DBM-Naxx", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2248 $"):sub(12, -3))
mod:SetCreatureID(15936)

mod:RegisterCombat("combat")


mod:RegisterEvents()

local warnTeleportSoon	= mod:NewAnnounce("WarningTeleportSoon", 2, 46573)
local warnTeleportNow	= mod:NewAnnounce("WarningTeleportNow", 3, 46573)

local timerTeleport		= mod:NewTimer(90, "TimerTeleport", 46573)

mod.vb.phase = 0

function mod:OnCombatStart(delay)
	self.vb.phase = 1
	mod:BackInRoom(90 - delay)
end

function mod:DancePhase()
	timerTeleport:Show(47)
	warnTeleportSoon:Schedule(37, 10)
	warnTeleportNow:Schedule(47)
	self:ScheduleMethod(47, "BackInRoom", 88)
	self.vb.phase = self.vb.phase + 1
end

function mod:BackInRoom(time)
	timerTeleport:Show(time)
	warnTeleportSoon:Schedule(time - 15, 15)
	warnTeleportNow:Schedule(time)
	self:ScheduleMethod(time, "DancePhase")
	self.vb.phase = self.vb.phase + 1
end