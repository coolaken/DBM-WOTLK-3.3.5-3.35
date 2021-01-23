local mod	= DBM:NewMod("MageLordUrom", "DBM-Party-WotLK", 9)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 3162 $"):sub(12, -3))
mod:SetCreatureID(27655)
mod:SetMinSyncRevision(2824)

mod:RegisterCombat("yell", L.CombatStart)

mod:RegisterKill("yell", L.YellCombatEnd)

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_CAST_START"
)

local warningTimeBomb		= mod:NewTargetNoFilterAnnounce(51121, 2)
local warningExplosion		= mod:NewCastAnnounce(51110, 3, 8)
local timerTimeBomb			= mod:NewTargetTimer(6, 51121, nil, nil, nil, 3)
local timerExplosion		= mod:NewTargetTimer(8, 51110, nil, nil, nil, 3)
local specWarnBombYou		= mod:NewSpecialWarningYou(51121)

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(51110, 59377) then
		warningExplosion:Show()
		timerExplosion:Start(args.destName)
		if args:IsPlayer() then
			specWarnBombYou:Show()
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(51121, 59376) then
		warningTimeBomb:Show(args.destName)
		timerTimeBomb:Start(args.destName)
	end
end
