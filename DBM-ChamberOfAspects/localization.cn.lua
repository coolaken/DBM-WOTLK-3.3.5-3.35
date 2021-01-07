-- author: callmejames @《凤凰之翼》 一区藏宝海湾
-- commit by: yaroot <yaroot AT gmail.com>


if GetLocale() ~= "zhCN" then return end

local L

----------------------------
--  The Obsidian Sanctum  --
----------------------------
--  Shadron  --
---------------
L = DBM:GetModLocalization("Shadron")

L:SetGeneralLocalization({
	name = "沙德隆"
})

----------------
--  Tenebron  --
----------------
L = DBM:GetModLocalization("Tenebron")

L:SetGeneralLocalization({
	name = "塔尼布隆"
})

----------------
--  Vesperon  --
----------------
L = DBM:GetModLocalization("Vesperon")

L:SetGeneralLocalization({
	name = "维斯匹隆"
})

------------------
--  Sartharion  --
------------------
L = DBM:GetModLocalization("Sartharion")

L:SetGeneralLocalization({
	name = "萨塔里奥"
})

L:SetWarningLocalization({
	WarningTenebron	        = "塔尼布隆到来",
	WarningShadron	        = "沙德隆到来",
	WarningVesperon	        = "维斯匹隆到来",
	WarningFireWall	        = "烈焰之啸",
	WarningVesperonPortal	= "维斯匹隆的传送门",
	WarningTenebronPortal	= "塔尼布隆的传送门",
	WarningShadronPortal    = "沙德隆的传送门"
})

L:SetTimerLocalization({
	TimerTenebron	= "塔尼布隆到来",
	TimerShadron	= "沙德隆到来",
	TimerVesperon	= "维斯匹隆到来"
})

L:SetOptionLocalization({
	PlaySoundOnFireWall	    = "为烈焰之啸播放音效",
	AnnounceFails           = "公布踩中暗影裂隙和撞上烈焰之啸的玩家到团队频道 (需要团长或助理权限)",
	TimerTenebron           = "为塔尼布隆到来显示计时条",
	TimerShadron            = "为沙德隆到来显示计时条",
	TimerVesperon           = "为维斯匹隆到来显示计时条",
	WarningFireWall         = "为烈焰之啸显示特别警报",
	WarningTenebron         = "提示塔尼布隆到来",
	WarningShadron          = "提示沙德隆到来",
	WarningVesperon         = "提示维斯匹隆到来",
	WarningTenebronPortal	= "为塔尼布隆的传送门显示特别警报",
	WarningShadronPortal	= "为沙德隆的传送门显示特别警报",
	WarningVesperonPortal	= "为维斯匹隆的传送门显示特别警报"
})

L:SetMiscLocalization({
	Wall			= "%s周围的岩浆沸腾了起来！",
	Portal			= "%s开始开启暮光传送门!",
	NameTenebron	= "塔尼布隆",
	NameShadron		= "沙德隆",
	NameVesperon	= "维斯匹隆",
	FireWallOn		= "烈焰之啸: %s",
	VoidZoneOn		= "暗影裂隙: %s",
	VoidZones		= "踩中暗影裂隙 (这一次): %s",
	FireWalls		= "撞上烈焰之啸 (这一次): %s"
})

------------------------
--  The Ruby Sanctum  --
------------------------
--  Baltharus the Warborn  --
-----------------------------
L = DBM:GetModLocalization("Baltharus")

L:SetGeneralLocalization({
	name = "战争之子巴尔萨鲁斯"
})

L:SetWarningLocalization({
	WarningSplitSoon	= "分裂 即将到来"
})

L:SetOptionLocalization({
	SoundWOP = "为重要技能播放额外的警报语音",
	WarningSplitSoon	= "为分裂显示预先警告",
	RangeFrame		= "显示距离框(12码)",
	SetIconOnBrand		= DBM_CORE_AUTO_ICONS_OPTION_TEXT:format(74505)
})

L:SetMiscLocalization({
})

-------------------------
--  Saviana Ragefire  --
-------------------------
L = DBM:GetModLocalization("Saviana")

L:SetGeneralLocalization({
	name = "塞维娅娜·怒火"
})

L:SetWarningLocalization({
	SpecialWarningTranq	= "激怒 - 宁神驱散"
})

L:SetOptionLocalization({
	SoundWOP = "为重要技能播放额外的警报语音",
	SpecialWarningTranq	= "为激怒显示特别警告(驱散用)",
	RangeFrame		= "显示距离框(10码)",
	BeaconIcon		= DBM_CORE_AUTO_ICONS_OPTION_TEXT:format(74453)
})

L:SetMiscLocalization{
}

--------------------------
--  General Zarithrian  --
--------------------------
L = DBM:GetModLocalization("Zarithrian")

L:SetGeneralLocalization({
	name = "萨瑞瑟里安将军"
})

L:SetWarningLocalization({
	WarnAdds		= "新的小怪",
	warnCleaveArmor		= "%s 于 >%s< (%s)"	-- Cleave Armor on >args.destName< (args.amount)
})

L:SetTimerLocalization({
	TimerAdds		= "新的小怪"
})

L:SetOptionLocalization({
	SoundWOP = "为重要技能播放额外的警报语音",
	WarnAdds		= "提示新的小怪",
	TimerAdds		= "为新的小怪显示定时器"
})

L:SetMiscLocalization({
	SummonMinions		= "去吧，将他们挫骨扬灰！"
})

-------------------------------------
--  Halion the Twilight Destroyer  --
-------------------------------------
L = DBM:GetModLocalization("Halion")

L:SetGeneralLocalization({
	name = "海里昂"
})

L:SetWarningLocalization({
	WarnPhase2Soon		= "第二阶段 即将到来",
	WarnPhase3Soon		= "第三阶段 即将到来",
	TwilightCutterCast	= "施放暮光撕裂射线: 5秒后"
})

L:SetOptionLocalization({
	SoundWOP = "为重要技能播放额外的警报语音",
	WarnPhase2Soon		= "为第二阶段显示预先警告(约79%)",
	WarnPhase3Soon		= "为第三阶段显示预先警告(约54%)",
	TwilightCutterCast	= "当$spell:77844开始施放时显示警告",
	AnnounceAlternatePhase	= "显示你不在的另一个领域内的技能报警和计时",
	SoundOnConsumption	= "为$spell:74562或$spell:74792播放音效",--We use localized text for these functions
	SetIconOnConsumption	= "为中了$spell:74562或$spell:74792的目标设置标记",--So we can use single functions for both versions of spell.
	YellOnConsumption	= "当你中了$spell:74562或$spell:74792时大喊",
	WhisperOnConsumption	= "悄悄话提示$spell:74562或$spell:74792的目标(需要团长权限)"
})

L:SetMiscLocalization({
	NormalHalion		= "物理领域 海里昂",
	TwilightHalion		= "暮光领域 海里昂",
	MeteorCast		= "天堂也将燃烧!",
	Phase2			= "在暮光的国度只有磨难在等着你!有胆量的话就进去吧!",
	Phase3			= "我是光明亦是黑暗!凡人，匍匐在死亡之翼的信使面前吧!",
	twilightcutter		= "这些环绕的球体散发着黑暗能量!",
	YellCombustion		= "我中了炽焰燃烧！",
	WhisperCombustion		= "你中了炽焰燃烧！快跑墙边！",
	YellConsumption		= "我中了灵魂吞噬！",
	WhisperConsumption		= "你中了灵魂吞噬！快跑墙边！",
	Kill			= "享受这场胜利吧，凡人们，因为这是你们最后一次的胜利。这世界将会在主人回归时化为火海!"
})