local mod = DBM:NewMod("Falric", "DBM-Party-WotLK", 16)
local L = mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2153 $"):sub(12, -3))
mod:SetCreatureID(38112)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED"
)

local warnFear					= mod:NewSpellAnnounce(72452, 3)
local warnImpendingDespair		= mod:NewTargetAnnounce(72426, 3)
local warnQuiveringStrike		= mod:NewTargetAnnounce(72453, 3)

local timerFear					= mod:NewBuffActiveTimer(4, 72452)
local timerImpendingDespair		= mod:NewTargetTimer(6, 72426)
local timerQuiveringStrike		= mod:NewTargetTimer(5, 72453)

local timerFearCD				= mod:NewCDTimer(20, 72435)-- 亵渎尖啸 20秒!

local lastfear = 0

local sndWOP					= mod:NewAnnounce("SoundWOP", nil, nil, true)


local function sendFearWarning()
	SendChatMessage("3秒后恐惧", "SAY")
end


function mod:OnCombatStart(delay)
	lastfear = 0
	timerFearCD:Start() --第一次有可能 是23秒出来!
	sndWOP:ScheduleVoice(17, "fearsoon")
	self:Schedule(17, sendFearWarning) -- 有待商榷
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(72422, 72453) then
		timerQuiveringStrike:Start(args.destName)
		warnQuiveringStrike:Show(args.destName)
	elseif args:IsSpellID(72426) then
		timerImpendingDespair:Start(args.destName)
		warnImpendingDespair:Show(args.destName)
	elseif args:IsSpellID(72452, 72435) and GetTime() - lastfear > 2 then --他一次恐惧多人 所以加个判断是不是同一次!!
		warnFear:Show()
		timerFear:Start()
		sndWOP:CancelVoice("fearsoon")
		sndWOP:ScheduleVoice(17, "fearsoon")
		self:Unschedule(sendFearWarning)
		self:Schedule(17, sendFearWarning)
		timerFearCD:Start()
		lastfear = GetTime()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(72422, 72453) then
		timerQuiveringStrike:Cancel(args.destName)
	elseif args:IsSpellID(72426) then
		timerImpendingDespair:Cancel(args.destName)
	end
end