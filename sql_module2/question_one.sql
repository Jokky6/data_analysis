SELECT
	t.user_id user1,
	t.dates dateime1,
	u.user_id user2,
	u.dates dateime2 
FROM
	temp_user_act t
	LEFT JOIN temp_user_act u ON t.user_id = u.user_id
	AND t.dates<u.dates;

SELECT
	user1 user,
	datetime1,
	datetime2 
FROM
	interview 
WHERE
	datetime2 >= datetime1;

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


SELECT
	日期,
	concat(round(100*次日留存用户数/日新增用户,2),'%') '次日留存率',
	concat(round(100*二日留存用户数/日新增用户,2),'%') '二日留存率',
	concat(round(100*三日留存用户数/日新增用户,2),'%') '三日留存率',
	concat(round(100*七日留存用户数/日新增用户,2),'%') '七日留存率'
FROM
	user_retention;
	

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

