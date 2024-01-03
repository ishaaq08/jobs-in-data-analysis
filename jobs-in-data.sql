CREATE TABLE job(
work_year INT,
job_title VARCHAR(100),
job_category VARCHAR(100),
salary_currency VARCHAR(10),
salary INT,
salary_in_usd INT,
employee_residence VARCHAR(50),
experience_level VARCHAR(50),
employment_type VARCHAR(50),
work_setting VARCHAR(50),
company_location VARCHAR(50),
company_size VARCHAR(10)
)

GO

BULK INSERT job
FROM 'C:\Users\mibai\SQL\portfolio-projects\jobs-in-data-analysis/data-file.csv'
WITH
(
        FORMAT='CSV',
        FIRSTROW=2
)


-- 1) Where (location) do you earn the most in certain sectors e.g. do you earn more in data engineering in the US?
	
	-- The count column allows us to understand how many entries we have for a certain country.
	-- Countries with fewer entries for a given category may have a higher average salary. 

SELECT 
	job_category,
	company_location,
	AVG(salary_in_usd) as 'avg_salary_usd',
	COUNT(*) AS jobs_recorded,
	ROW_NUMBER() OVER (PARTITION BY job_category ORDER BY job_category, AVG(salary_in_usd) DESC) as 'rank'
FROM 
	job
GROUP BY 
	job_category,
	company_location

	-- INSIGHT > Of the 10 categories, how many times is US in the top 3
	-- CONCLUSION > 100%

		-- v1) CTE

		-- WHY ? We need to use ROW_NUMBER() to rank each entry in the group and need filter by this value in the WHERE clause.
				-- but you can't use window functions in the WHERE clause so we have to make a CTE or an equivalent. 

GO 

WITH cte_sal_by_loc (job_category, company_location, avg_salary_usd, jobs_rec, ranking)
AS (
SELECT 
	job_category,
	company_location,
	AVG(salary_in_usd),
	COUNT(*) AS jobs_recorded,
	ROW_NUMBER() OVER (PARTITION BY job_category ORDER BY job_category, AVG(salary_in_usd) DESC)
FROM 
	job
GROUP BY 
	job_category,
	company_location)

SELECT 
	COUNT(*) AS usa_top10_count
FROM 
	cte_sal_by_loc
WHERE
	ranking between 1 and 3 and 
	company_location like '%United States'

	-- v2) Using a subquery 

GO

SELECT 
	COUNT(*) as usa_top10_count 
FROM 
	(SELECT 
		job_category,
		company_location,
		AVG(salary_in_usd) as 'avg_salary_usd',
		COUNT(*) AS jobs_recorded,
		ROW_NUMBER() OVER (PARTITION BY job_category ORDER BY job_category, AVG(salary_in_usd) DESC) as ranking
	FROM 
		job
	GROUP BY 
		job_category,
		company_location) AS derived_tbl
WHERE 
	ranking between 1 and 3 and 
	company_location like 'United States'

-- 2) How pay differs between locations for a given sector at a given exp level

SELECT 
	job_category,
	experience_level,
	company_location,
	AVG(salary_in_usd) as avg_salary_usd
FROM 
	job
GROUP BY 
	job_category,
	experience_level,
	company_location
ORDER BY 
	job_category,
	experience_level,
	company_location,
	avg_salary_usd DESC

-- 3) Average % salary increase as experience increases for a given job category 

	-- Key tasks:
		-- CASE WHEN THEN nested in order by to do a custom order by a list of strings
		-- LAG() to calculate % change 
		-- Nested CTE's > Can't use an aggregate function in a windows function. Windows function = Individual rows, Agg function = multiple rows


SELECT
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
	(SELECT
		job_category,
		experience_level,
		AVG(salary_in_usd) as avg_sal_usd
	FROM 
		job
	GROUP BY 
		job_category,
		experience_level) AS derived_tbl

GO

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
	*,
	CAST(((CAST(avg_sal_usd - prev_row AS DECIMAL))/NULLIF(prev_row, 0))*100 AS DECIMAL(8,2)) as '%_change'
FROM 
	cte_sal_by_exp_with_lag


-- 4) What is the association between company size and experienced professionals e.g. does a smaller company have less experienced positions?



-- 5) What is the association between company size and employment type?