
-- 用户活跃日期表与用户活跃日期表做用户ID的左连接，保留两表的用户id与两表的日期
SELECT
	t.user_id user1,
	t.dates dateime1,
	u.user_id user2,
	u.dates dateime2 
FROM
	temp_user_act t
	LEFT JOIN temp_user_act u ON t.user_id = u.user_id;

-- 筛选出右表日期大于等于左表日期的内容
SELECT
	a.user_id,
	a.dates,
	b.user_id,
	b.dates 
FROM
	temp_user_act a
	LEFT JOIN temp_user_act b ON a.user_id = b.user_id 
WHERE
	b.dates >= a.dates 
ORDER BY
	a.user_id,
	a.dates;

-- 计算以左表日期为首日的首日用户数，第二日用户数，第三日用户数，第四日用户数，第八日用户数
SELECT
	dates AS 日期,
	COUNT( DISTINCT user_id ) AS 首日,
	COUNT(
	DISTINCT
	IF
		(
			DATEDIFF( dates1, dates )= 1,
			user_id,
		NULL 
		)) AS 第二日用户数,
	COUNT(
	DISTINCT
	IF
		(
			DATEDIFF( dates1, dates )= 2,
			user_id,
		NULL 
		)) AS 第三日用户数,
	COUNT(
	DISTINCT
	IF
		(
			DATEDIFF( dates1, dates )= 3,
			user_id,
		NULL 
		)) AS 第四日用户数,
	COUNT(
	DISTINCT
	IF
		(
			DATEDIFF( dates1, dates )= 7,
			user_id,
		NULL 
		)) AS 第八日用户数 
FROM
	user_balance 
GROUP BY
	dates;
	

SELECT
	datetime1,	
	count( DISTINCT user1 ) user_num
FROM
	interview
GROUP BY
	datetime1;


SELECT
	a.datetime1,
	count( DISTINCT a.user1 ) one_day_growth
FROM
	interview a
	LEFT JOIN interview b ON a.user1 = b.user1 
	AND DATEDIFF( b.datetime1, a.datetime1 )= 1 
GROUP BY
	datetime1;
	
-- 计算用户留存(新增)
SELECT
	c.dates '日期',
	count( DISTINCT c.user_id ) '日新增用户',
	count( DISTINCT d.user_id ) '次日留存用户数',
	count( DISTINCT e.user_id ) '二日留存用户数',
	count( DISTINCT f.user_id ) '三日留存用户数',
	count( DISTINCT g.user_id ) '七日留存用户数' 
FROM
	(
	SELECT
		a.* 
	FROM
		temp_user_act a
		LEFT JOIN temp_user_act b ON b.user_id = a.user_id 
		AND b.dates < a.dates 
	WHERE
		b.dates IS NULL 
	) c
	LEFT JOIN temp_user_act d ON c.user_id = d.user_id 
	AND DATEDIFF( d.dates, c.dates )= 1
	LEFT JOIN temp_user_act e ON c.user_id = e.user_id 
	AND DATEDIFF( e.dates, c.dates )= 2
	LEFT JOIN temp_user_act f ON c.user_id = f.user_id 
	AND DATEDIFF( f.dates, c.dates )= 3
	LEFT JOIN temp_user_act g ON c.user_id = g.user_id 
	AND DATEDIFF( g.dates, c.dates )= 7 
GROUP BY
	c.dates;
	
-- 计算用户留存率
SELECT
	日期,
	首日,
	CONCAT(
		TRUNCATE ( ( 第二日用户数 / 首日 ) * 100, 2 ),
		"%" 
	) AS 次日留存率,
	CONCAT(
		TRUNCATE ( ( 第三日用户数 / 首日 ) * 100, 2 ),
		"%" 
	) AS 二日留存率,
	CONCAT(
		TRUNCATE ( ( 第四日用户数 / 首日 ) * 100, 2 ),
		"%" 
	) AS 三日留存率,
	CONCAT(
		TRUNCATE ( ( 第八日用户数 / 首日 ) * 100, 2 ),
		"%" 
	) AS 七日留存率 
FROM
	user_keep;
	
-- 周环比
SELECT 日期, concat( ROUND( 100 *(次日留存率- gvm_7 )/ gvm_7,
		2 
		),
	'%' 
) '周环比' 
FROM
	(
	SELECT
		日期,
		次日留存率,
		LEAD(次日留存率, 7 ) over ( ORDER BY 日期 DESC ) gvm_7 
	FROM
		keep_percent 
	) g

-- 计算用户留存率(新增)
SELECT
	日期,
	concat(round(100*次日留存用户数/日新增用户,2),'%') '次日留存率',
	concat(round(100*二日留存用户数/日新增用户,2),'%') '二日留存率',
	concat(round(100*三日留存用户数/日新增用户,2),'%') '三日留存率',
	concat(round(100*七日留存用户数/日新增用户,2),'%') '七日留存率'
FROM
	user_retention;
	
-- 周环比(新增)
SELECT 
	日期,
	concat(ROUND(100*(次日留存率-gvm_7)/ gvm_7,2),'%') '周环比'
FROM
	(
	SELECT
		日期,
		次日留存率,
		LEAD(次日留存率,7) over ( ORDER BY 日期 DESC ) gvm_7 
	FROM
		user_retention_percent 
	) k
	
-- 简书
SELECT
	日期,
	新增用户数,
	CONCAT(
		TRUNCATE ( ( 次日留存用户数 / 新增用户数 ) * 100, 2 ),
		"%" 
	) AS 次日留存率,
	CONCAT(
		TRUNCATE ( ( 第二日留存用户数 / 新增用户数 ) * 100, 2 ),
		"%" 
	) AS 第二日留存,
	CONCAT(
		TRUNCATE ( ( 第三日留存用户数 / 新增用户数 ) * 100, 2 ),
		"%" 
	) AS 第三日留存率,
	CONCAT(
		TRUNCATE ( ( 第七日留存用户数 / 新增用户数 ) * 100, 2 ),
		"%" 
	) AS 第七日留存率 
FROM
	(
	SELECT
		first_day AS 日期,
		COUNT( DISTINCT a.user_id ) AS 新增用户数,
		COUNT( DISTINCT b.user_id ) AS 次日留存用户数,
		COUNT( DISTINCT c.user_id ) AS 第二日留存用户数,
		COUNT( DISTINCT d.user_id ) AS 第三日留存用户数,
		COUNT( DISTINCT e.user_id ) AS 第七日留存用户数 
	FROM
		(
		SELECT
			user_id,
			min( dates ) AS first_day 
		FROM
			temp_user_act 
		GROUP BY
			user_id 
		) a
		LEFT JOIN temp_user_act b ON a.user_id = b.user_id 
		AND DATEDIFF( b.dates, a.first_day ) = 1
		LEFT JOIN temp_user_act c ON a.user_id = c.user_id 
		AND DATEDIFF( c.dates, a.first_day ) = 2
		LEFT JOIN temp_user_act d ON a.user_id = d.user_id 
		AND DATEDIFF( d.dates, a.first_day ) = 3
		LEFT JOIN temp_user_act e ON a.user_id = e.user_id 
		AND DATEDIFF( e.dates, a.first_day ) = 7 
	GROUP BY
	a.first_day 
	) P;