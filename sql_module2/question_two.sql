SELECT
	author_id,
	dates day,
	LEAD( dates, 1, null ) over ( PARTITION BY author_id ORDER BY dates ) next_day 
FROM
	temp_author_act 
WHERE
	dates > DATE_SUB( CURDATE(), INTERVAL 3 MONTH ) 
ORDER BY
	author_id,
	dates;
	
SELECT
	author_id,
	DAY,
	next_day 
FROM
	video_update_time 
WHERE
	next_day IS NOT NULL;

SELECT
	author_id,
	day,
	next_day,
	DATEDIFF( next_day, DAY ) off_days 
FROM
	video_update_time 
WHERE
	next_day IS NOT NULL;
	
SELECT
	author_id,
	MAX(DATEDIFF( next_day, day )) max_off_days
FROM
	video_update_time 
WHERE
	next_day IS NOT NULL
GROUP BY author_id;

-- 最大断更天数 、平均断更天数
SELECT
	author_id,
	MAX( off_days ) max_off_days,
	AVG( off_days ) avg_off_days
FROM
	off_days 
WHERE
	off_days > 1 
GROUP BY
	author_id;
	

SELECT
	author_id,
	day,
	next_day,
	LEAD(day,1,null) over( PARTITION BY author_id ORDER BY day ) second_day,
	off_days
FROM
	off_days 
WHERE
	off_days > 1;

-- 最大连续更新天数
SELECT
	author_id,
	max(
	DATEDIFF( second_day, next_day )) max_serial_days 
FROM
	serial_days 
WHERE
	second_day IS NOT NULL 
GROUP BY
	author_id;
	
	-- 最近三个月内的最大断更天数、平均断更天数和最大持续更新天数
SELECT
	a.author_id author_id,
	a.max_off_days max_off_days,
	a.avg_off_days avg_off_days,
	b.max_serial_days max_serial_days
FROM
	(
	SELECT
		author_id,
		MAX( off_days ) max_off_days,
		AVG( off_days ) avg_off_days 
	FROM
		off_days 
	WHERE
		off_days > 1 
	GROUP BY
		author_id 
	) a
	LEFT JOIN (
	SELECT
		author_id,
		max(
		DATEDIFF( second_day, next_day )) max_serial_days 
	FROM
		serial_days 
	WHERE
		second_day IS NOT NULL 
	GROUP BY
		author_id 
	) b ON b.author_id = a.author_id;


