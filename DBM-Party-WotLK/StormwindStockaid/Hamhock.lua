local mod	= DBM:NewMod("Hamhock", "DBM-Party-WotLK", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20190812041847")
mod:SetCreatureID(1717)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_AURA_APPLIED"
)

--TODO, add timer for chain lightning if it's not spam cast
local warningBloodlust				= mod:NewTargetNoFilterAnnounce(6742, 2)

mod:AddRangeFrameOption("10")

function mod:OnCombatStart(delay)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(10, nil, true, nil)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide(true)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	DBM:Debug("bbb")
	if args:IsSpellID(6742) then
		DBM:Debug("ddd")
		warningBloodlust:Show(args.destName)
	end
end
