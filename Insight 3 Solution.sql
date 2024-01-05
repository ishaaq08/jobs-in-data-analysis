-- 3) Average % salary increase as experience increases for a given job category 

	-- Key tasks:
		-- CASE WHEN THEN nested in order by to do a custom order by a list of strings
		-- LAG() to calculate % change 
		-- Nested CTE's > Can't use an aggregate function in a windows function. Windows function = Individual rows, Agg function = multiple rows

-- CTE 1
WITH cte_sal_by_exp (job_category, experience_level, avg_sal_usd)
AS
(SELECT
	job_category,
	experience_level,
	AVG(salary_in_usd)
FROM 
	job
GROUP BY 
	job_category,
	experience_level),

-- CTE 2 (NESTED)
cte_sal_by_exp_with_lag 
AS
(SELECT
	*,
	COALESCE(LAG(avg_sal_usd) 
	OVER (PARTITION BY job_category ORDER BY job_category, 
		CASE experience_level 
		WHEN 'Entry-level' THEN 1
		WHEN 'Mid-level' THEN 2
		WHEN 'Senior' THEN 3
		WHEN 'Executive' THEN 4
	END,
	avg_sal_usd ASC), 0) as prev_row
FROM 
	cte_sal_by_exp)

-- SELECT statement
SELECT 
	job_category,
	experience_level,
	avg_sal_usd,
	CAST(((CAST(avg_sal_usd - prev_row AS DECIMAL))/NULLIF(prev_row, 0))*100 AS DECIMAL(8,2)) as '%_change'
FROM 
	cte_sal_by_exp_with_lag