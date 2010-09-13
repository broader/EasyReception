/*
---

script: Date.Chinese.CN.js

description: Date messages for Chinese.

license: MIT-style license

authors:
- Broader.ZHONG

requires:
- /Lang
- /Date

provides: [Date.Chinese]

...
*/

MooTools.lang.set('zh-CN', 'Date', {

	months: ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'],
	days: ['周日', '周一', '周二', '周三', '周四', '周五', '周六'],
	//culture's date order: MM/DD/YYYY
	dateOrder: ['月', '日', '年'],
	shortDate: '%Y年%m月%d日',
	shortTime: '%H:%M',
	AM: '上午',
	PM: '下午',

	/* Date.Extras */
	ordinal: '.',

	lessThanMinuteAgo: '不超过一分钟前',
	minuteAgo: '大约一分钟前',
	minutesAgo: '{delta} 己分钟前',
	hourAgo: '大约一小时前',
	hoursAgo: '大约 {delta} 小时前',
	dayAgo: '一小时前',
	daysAgo: '{delta} 天前',
	weekAgo: '一星期前',
	weeksAgo: '{delta} 星期前',
	monthAgo: '一个月前',
	monthsAgo: '{delta} 月前',
	yearAgo: '一年前',
	yearsAgo: '{delta} 年前',
	lessThanMinuteUntil: '从现在起不超过一分钟',
	minuteUntil: '从现在起大约一分钟',
	minutesUntil: '从现在起{delta}分钟后',
	hourUntil: '从现在起大约一小时后',
	hoursUntil: '从现在起大约{delta} 小时后',
	dayUntil: '从现在起一天后',
	daysUntil: '从现在起{delta}天后',
	weekUntil: '从现在起一周后',
	weeksUntil: '从现在起{delta}星期后',
	monthUntil: '从现在起一月后',
	monthsUntil: '从现在起{delta}月后',
	yearUntil: '从现在起一年后',
	yearsUntil: '从现在{delta}年后'

});
