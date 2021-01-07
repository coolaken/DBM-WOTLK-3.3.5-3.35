local mod	= DBM:NewMod("Targorr", "DBM-Party-WotLK", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20190614210311")
mod:SetCreatureID(1696)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS"
)



local berserkTimer					= mod:NewBerserkTimer(50)

function mod:OnCombatStart(delay)
    DBM:Debug("99")
    berserkTimer:Start(10)
end

function mod:SPELL_CAST_SUCCESS(args)
    if args:IsSpellID(8599) then	
        DBM:Debug("98")			--Incite Terror (fear before air phase)
		berserkTimer:Start()
	end
end