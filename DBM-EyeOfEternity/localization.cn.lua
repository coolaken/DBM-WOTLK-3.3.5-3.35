-- author: callmejames @《凤凰之翼》 一区藏宝海湾
-- commit by: yaroot <yaroot AT gmail.com>


if GetLocale() ~= "zhCN" then return end

local L

---------------
--  Malygos  --
---------------
L = DBM:GetModLocalization("Malygos")

L:SetGeneralLocalization({
	name 			= "玛里苟斯"
})

L:SetWarningLocalization({
	WarningSpark		= "能量火花 出现了",
	WarningBreathSoon	= "奥术吐息 即将到来",
	WarningBreath		= "奥术吐息"
})

L:SetTimerLocalization({
	TimerSpark		= "下一次 能量火花",
	TimerBreath		= "下一次 奥术吐息"
})

L:SetOptionLocalization({
	WarningSpark		= "为能量火花显示警报",
	WarningBreathSoon	= "为奥术吐息显示预先警报",
	WarningBreath		= "为奥术吐息显示警报",
	TimerSpark		= "为下一次 能量火花显示计时条",
	TimerBreath		= "为下一次 奥术吐息显示计时条"
})

L:SetMiscLocalization({
	--YellPull		= "我的耐心到此为止了。我要亲自消灭你们！",
	YellPull		= "我的耐心到此为止了，我要亲自消灭你们!",
	--EmoteSpark		= "附近的裂隙中冒出了一团能量火花！",
	EmoteSpark		= "一个力量火花从附近的裂缝中形成!",
	--YellPhase2		= "我原本只是想尽快结束你们的生命",
	YellPhase2		= "我原本只想尽快结束你们的生命，但你们竟然远比我想象的要坚韧……虽然如此，你们的努力仍将付诸东流。事实上，这场战争本身就是因为你们凡人不计后果的行为而起！我只是在尽自己的责任罢了……如果这责任意味着要灭绝你们……那就这样吧!",
	--EmoteBreath		= "%s深深地吸了一口气", --也许是  深深地吸了一口气……
	EmoteBreath		= "%s深深地吸了一口气.",
	--YellBreath		= "在我的龙息之下，一切都将荡然无存！",
	YellBreath		= "在我的龙息之下一切都将荡然无存!",
	--YellPhase3		= "现在你们幕后的主使终于出现了"
	YellKill	=	"不可思议！这群凡人竟然毁灭了一切……我的妹妹……你都做了些……什么……-",
	YellPhase3		= "现在你们的幕后主使终于出现了……但已经太迟了。这里弥漫着的能量已经足以将这个世界毁灭十次！你们觉得它们会对你做些什么呢?"
})
--[[Details!: Emotes for 玛里苟斯 [ EF]
0m14s: 一个力量火花从附近的裂缝中形成!
0m25s: 我无坚不摧!
0m29s: 就这样无助地看着希望破灭吧...
0m59s: 一个力量火花从附近的裂缝中形成!
1m27s: 一个力量火花从附近的裂缝中形成!
1m29s: 我原本只想尽快结束你们的生命，但你们竟然远比我想象的要坚韧……虽然如此，你们的努力仍将付诸东流。事实上，这场战争本身就是因为你们凡人不计后果的行为而起！我只是在尽自己的责任罢了……如果这责任意味着要灭绝你们……那就这样吧!
1m53s: 没有人体验过你们将要承受的痛苦!
2m48s: 在我的龙息之下一切都将荡然无存!
2m53s: 玛里苟斯深深地吸了一口气.
3m21s: 够了！既然你们这么想夺回艾泽拉斯的魔法，我就给你们...
3m36s: 现在你们的幕后主使终于出现了……但已经太迟了。这里弥漫着的能量已经足以将这个世界毁灭十次！你们觉得它们会对你做些什么呢?
3m56s: Malygos fixes his eyes on you!
4m53s: Malygos fixes his eyes on you!
5m7s: Malygos fixes his eyes on you!
5m23s: 不可思议！这群凡人竟然毁灭了一切……我的妹妹……你都做了些……什么……-

阶段转换 23秒
]]--