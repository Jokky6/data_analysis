## sql语句错误分析


### 问题一
> 错误
``` sql
SELECT
	a.store_id,
	IFNULL( sum( sales_volume ), 0 ) AS sales_volumes 
FROM
	area_table a
	LEFT JOIN store_table b ON a.store_id = b.store_id 
WHERE
	a.area = 'alpha' 
	AND b.salesdate = DATE_SUB( curdate(), INTERVAL 1 DAY ) 
GROUP BY
	a.store_id 
ORDER BY
	a.store_id;
```

> 正确
```sql
SELECT
	a.store_id,
	IFNULL( sum( sales_volume ), 0 ) AS sales_volumes 
FROM
	area_table a
	LEFT JOIN store_table b ON a.store_id = b.store_id 
	AND b.salesdate = DATE_SUB( curdate(), INTERVAL 1 DAY ) 
WHERE
	a.area = 'alpha' 
GROUP BY
	a.store_id 
ORDER BY
	a.store_id;
```

> 我一开始关注 Right -- `GROUP BY`和`ORDER BY`同时存在的情况是，`ORDER　BY`对`GROUP BY`后的结果再进行排序，所以`ORDER BY`后面的排序字段需要在SELECT里出现，`ORDER BY` 子句中的列必须包含在聚合函数或 `GROUP BY` 子句中。

> 真正错误原因关注sql语句执行顺序,where是在join之前执行,这时候还没有左连接
>所以 `b.salesdate = DATE_SUB( curdate(), INTERVAL 1 DAY )`不能正确执行

```shell
from -> where -> join
```

### 问题二

```sql
WITH temp_active_hour_table_kps AS (
	SELECT
		a0.dt,
		product_id,
		mkey,
		substr( FROM_UNIXTIME( st_time ), 12, 2 ) AS HOUR,
		a0.device_id 
	FROM
		(
		SELECT
			dt,
			product_id,
			st_time,
			device_id 
		FROM
			kps_dwd.kps_dwd_dd_view_user_active 
		WHERE
			dt = '${dt_1}' 
		) a0
		LEFT JOIN (
		SELECT
			dt,
			mkey,
			device_id 
		FROM
			kps_dwd.kps_dwd_dd_user_channels 
		WHERE
			dt = '${dt_1}' 
		) a1 ON a0.device_id = a1.device_id;
) 
	
SELECT
	dt,
	product,
	product_id,
	a1.mkey,
	name_cn,
	HOUR,
	STATUS,
	dau,
	new 
FROM
	(
	SELECT
		dt,
		'K-pop' AS product,
		product_id,
		mkey,
		HOUR,
		STATUS,
		count( DISTINCT a.device_id ) AS dau,
		count(
		DISTINCT
		IF
			(
				b.device_id IS NOT NULL,
				a.device_id,
			NULL 
			)) AS new 
	FROM
		(
		SELECT
			dt,
			product_id,
			mkey,
			HOUR,
			device_id,
			'active' AS STATUS 
		FROM
			temp_active_hour_table_kps 
		GROUP BY
			dt,
			mkey,
			product_id,
			device_id,
		HOUR UNION ALL
		SELECT
			dt,
			product_id,
			mkey,
			min( HOUR ) AS HOUR,
			device_id,
			'first' AS STATUS 
		FROM
			temp_active_hour_table_kps 
		GROUP BY
			dt,
			mkey,
			product_id,
			device_id 
		) a
		LEFT JOIN (
		SELECT
			dt,
			device_id 
		FROM
			kps_dwd.kps_dwd_dd_fact_view_new_user 
		WHERE
			dt = '${dt_1}' 
		GROUP BY
			dt,
			device_id 
		) b ON a.dt = b.dt 
		AND a.device_id = b.device_id 
	GROUP BY
		dt,
		product_id,
		mkey,
		HOUR,
	STATUS 
	) a1
	LEFT JOIN asian_channel.dict_lcmas_channel b1 ON a1.mkey = b1.mkey;

```

> `WITH AS部分`

#### 拆解 `WITH AS`部分SQL

```sql
SELECT
	a0.dt,
	product_id,
	mkey,
	substr( FROM_UNIXTIME( st_time ), 12, 2 ) AS HOUR,
	a0.device_id 
FROM
	(
	SELECT
		dt,
		product_id,
		st_time,
		device_id 
	FROM
		kps_dwd.kps_dwd_dd_view_user_active 
	WHERE
		dt = '${dt_1}' 
	) a0
	LEFT JOIN (
	SELECT
		dt,
		mkey,
		device_id 
	FROM
		kps_dwd.kps_dwd_dd_user_channels 
	WHERE
		dt = '${dt_1}' 
	) a1 ON a0.device_id = a1.device_id;

```

>1.关注`line 177` 先拆解 `FROM`中的子句的`FROM`,  

>`FROM kps_dwd.kps_dwd_dd_view_user_active `

> 2.关注`line 177` 先拆解 `FROM`中的子句的`LEFT JOIN`

```sql
1 FROM kps_dwd.kps_dwd_dd_user_channels 
2 WHERE
		dt = '${dt_1}' 
	) a1 ON a0.device_id = a1.device_id
3 SELECT
		dt,
		mkey,
		device_id 
```

3 .关注`line 177` 先拆解 `FROM`中的子句的`WHERE` 

>`WHERE
		dt = '${dt_1}' 
	) a0`
4. `FROM`子句
> SELECT
		dt,
		product_id,
		st_time,
		device_id 

5.`FROM` 拆解完成 
>`SELECT
	a0.dt,
	product_id,
	mkey,
	substr( FROM_UNIXTIME( st_time ), 12, 2 ) AS HOUR,
	a0.device_id `

至此 `WITH AS`拆解完成,以后拆解过程中用`temp_active_hour_table_kp`替代


```sql
SELECT
	dt,
	product,
	product_id,
	a1.mkey,
	name_cn,
	HOUR,
	STATUS,
	dau,
	new 
-- TAG 1
FROM
	(
	-- TAG 11
	SELECT
		dt,
		'K-pop' AS product,
		product_id,
		mkey,
		HOUR,
		STATUS,
		count( DISTINCT a.device_id ) AS dau,
		count(
		DISTINCT
		IF
			(
				b.device_id IS NOT NULL,
				a.device_id,
			NULL 
			)) AS new 
	-- TAG 2
	FROM
		(
		SELECT
			dt,
			product_id,
			mkey,
			HOUR,
			device_id,
			'active' AS STATUS 
		-- TAG 3
		FROM
			temp_active_hour_table_kps 
		GROUP BY
			dt,
			mkey,
			product_id,
			device_id,	
			HOUR 
		-- TAG 4
		UNION ALL
		SELECT
			dt,
			product_id,
			mkey,
			min( HOUR ) AS HOUR,
			device_id,
			'first' AS STATUS 
			-- TAG 5
		FROM
			temp_active_hour_table_kps 
			-- TAG 8
		GROUP BY
			dt,
			mkey,
			product_id,
			device_id 
		) a
		LEFT JOIN (
			-- TAG 6
		SELECT
			dt,
			device_id 
			-- TAG 7
		FROM
			kps_dwd.kps_dwd_dd_fact_view_new_user 
		WHERE
			dt = '${dt_1}' 
		GROUP BY
			dt,
			device_id 
		) b ON a.dt = b.dt 
		AND a.device_id = b.device_id 
	-- TAG 10
	GROUP BY
		dt,
		product_id,
		mkey,
		HOUR,
		STATUS ) a1
	-- TAG 9
LEFT JOIN asian_channel.dict_lcmas_channel b1 ON a1.mkey = b1.mkey;
```

> 首先，对语句进行备注 TAG 分层

1.从`TAG1`开始分层->`UNION ALL`即`TAG4`作为分水岭  
2.从`TAG4`继续逐层-> `TGA 5`
> `FROM temp_active_hour_table_kps `

3.`TAG 6`处左连接
```
1 `FROM kps_dwd.kps_dwd_dd_fact_view_new_user `  
2  `WHERE dt = '${dt_1}'`
3  `GROUP BY
			dt,
			device_id 
		) b ON a.dt = b.dt 
		AND a.device_id = b.device_id`
4.`SELECT
			dt,
			device_id `
```
5.`TAG 8`处
 > `GROUP BY
			dt,
			mkey,
			product_id,
			device_id 
		) a`  

> `SELECT
			dt,
			product_id,
			mkey,
			min( HOUR ) AS HOUR,
			device_id,
			'first' AS STATUS `

6. `TAG 3`处

> `FROM
			temp_active_hour_table_kps`

>`GROUP BY
			dt,
			mkey,
			product_id,
			device_id,	
			HOUR`

> `SELECT
			dt,
			product_id,
			mkey,
			HOUR,
			device_id,
			'active' AS STATUS `

7.`TAG 10`处
> `GROUP BY
		dt,
		product_id,
		mkey,
		HOUR,
	STATUS 
	)`

8. `TAG 11`
> `SELECT
		dt,
		'K-pop' AS product,
		product_id,
		mkey,
		HOUR,
		STATUS,
		count( DISTINCT a.device_id ) AS dau,
		count(
		DISTINCT
		IF
			(
				b.device_id IS NOT NULL,
				a.device_id,
			NULL 
			)) AS new `

9. `TAG 9`、

>`LEFT JOIN asian_channel.dict_lcmas_channel b1 ON a1.mkey = b1.mkey;``

10. Lastest

>`SELECT
	dt,
	product,
	product_id,
	a1.mkey,
	name_cn,
	HOUR,
	STATUS,
	dau,
	new `
