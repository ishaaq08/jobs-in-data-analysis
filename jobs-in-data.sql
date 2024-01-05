USE JobData

GO

IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'job'))
BEGIN
    DROP table [job]
END

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

GO

	-- Creating temporary table


IF OBJECT_ID(N'tempdb..#job_temp_table') IS NOT NULL
BEGIN
DROP TABLE #job_temp_table
END 

GO 

CREATE TABLE #job_temp_table(
company_size VARCHAR(1),
experience_level VARCHAR(20),
num_of_pos INT
)

	-- Inserting data into the temporary table

INSERT INTO 
	#job_temp_table
SELECT 
	company_size,
	experience_level,
	COUNT(*) AS num_of_pos
FROM 
	job
GROUP BY 
	company_size,
	experience_level

	-- Viewing and ordering the data in the temporary table

SELECT 
	* 
FROM 
	#job_temp_table
ORDER BY 
	CASE company_size
		WHEN 'S' THEN 0
		WHEN 'M' THEN 1
		WHEN 'L' THEN 2
	END,
	CASE experience_level 
		WHEN 'Entry-level' THEN 1
		WHEN 'Mid-level' THEN 2
		WHEN 'Senior' THEN 3
		WHEN 'Executive' THEN 4
	END

	-- Filter by 'S' company

SELECT 
	*,
	SUM(num_of_pos)
FROM 
	#job_temp_table
WHERE 
	company_size = 'S'

	-- Filter by 'M' company 

SELECT 
	*,
	SUM(num_of_pos)
FROM 
	#job_temp_table
WHERE 
	company_size = 'M'

	-- Filter by 'L' company

SELECT 
	SUM(num_of_pos)
FROM 
	#job_temp_table
WHERE 
	company_size = 'L'

	-- Simplifying this entire process with a Stored Procedure

GO 

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[sp_job_proc]') AND type in (N'P', N'PC'))
DROP PROCEDURE [sp_job_proc]

GO

CREATE PROC sp_job_proc 
	(
	@comp_size VARCHAR(1),
	@result INT OUTPUT
	)
AS 
BEGIN 
	SELECT 
		@result = SUM(num_of_pos)
	FROM 
		#job_temp_table
	WHERE 
		company_size = @comp_size
END

GO 

	-- Assigning Stored Procedure outputs to corresponding variables 

DECLARE @sum_comp_s INT
EXEC 
	sp_job_proc 
	@comp_size = 'S',
	@result = @sum_comp_s OUTPUT

DECLARE @sum_comp_m INT
EXEC 
	sp_job_proc 
	@comp_size = 'M',
	@result = @sum_comp_m OUTPUT

DECLARE @sum_comp_l INT
EXEC 
	sp_job_proc 
	@comp_size = 'L',
	@result = @sum_comp_l OUTPUT


	-- Creating the new column 

SELECT 
	*,
	CASE company_size
		WHEN 'S' THEN CAST((CAST(num_of_pos AS DECIMAL(5,2))/@sum_comp_s)*100 AS DECIMAL(5,2))
		WHEN 'M' THEN CAST((CAST(num_of_pos AS DECIMAL)/@sum_comp_m)*100 AS DECIMAL (5,2))
		WHEN 'L' THEN CAST((CAST(num_of_pos AS DECIMAL)/@sum_comp_l)*100 AS DECIMAL (5,2))
	END as ratio
FROM 
	#job_temp_table
ORDER BY 
	CASE company_size
		WHEN 'S' THEN 0
		WHEN 'M' THEN 1
		WHEN 'L' THEN 2
	END,
	CASE experience_level 
		WHEN 'Entry-level' THEN 1
		WHEN 'Mid-level' THEN 2
		WHEN 'Senior' THEN 3
		WHEN 'Executive' THEN 4
	END

-- 5) What is the association between company size and employment type?

-- a) Checking if the view exists > Deleting if so

IF EXISTS(select * FROM sys.views where name = 'vw_job_insight_5')
BEGIN 
	DROP VIEW vw_job_insight_5
END 

GO

-- b) Creating a view to store the subset

CREATE VIEW vw_job_insight_5
AS
(SELECT 
	company_size,
	work_setting,
	COUNT(*) AS num_of_pos
FROM 
	job
GROUP BY 
	company_size, 
	work_setting)

GO

-- c) Selecting the contents of the view 

--SELECT 
--	* 
--FROM 
--	vw_job_insight_5
--ORDER BY 
--	CASE company_size
--		WHEN 'S' THEN 0
--		WHEN 'M' THEN 1
--		WHEN 'L' THEN 2
--	END,
--	work_setting

-- d) Stored Procedure > Store the total number of positions for each 

	-- d1) Check if the stored procedure exists (dropping if so)

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[sp_job_insight_5]') AND type in (N'P', N'PC'))
DROP PROCEDURE [sp_job_insight_5]

GO

	-- d2) Creating the stored procedure

CREATE PROC sp_job_insight_5
	(
		@company_size VARCHAR(1),
		@result INT OUTPUT
	)
AS 
BEGIN 
	SELECT 
		@result = SUM(num_of_pos)
	FROM 
		vw_job_insight_5
	WHERE 
		company_size = @company_size
END 

GO

	-- d3) Storing the output of the stored procedure

DECLARE @sum_comp_s INT
EXEC 
	sp_job_insight_5
	@company_size = 'S',
	@result = @sum_comp_s OUTPUT

DECLARE @sum_comp_m INT
EXEC 
	sp_job_insight_5
	@company_size = 'M',
	@result = @sum_comp_m OUTPUT

DECLARE @sum_comp_l INT
EXEC 
	sp_job_insight_5
	@company_size = 'L',
	@result = @sum_comp_l OUTPUT


-- e) Creating the new 'ratio' column

	-- Creating the new column 

SELECT 
	company_size,
	work_setting,
	CASE company_size
		WHEN 'S' THEN CAST((CAST(num_of_pos AS DECIMAL(5,2))/@sum_comp_s)*100 AS DECIMAL(5,2))
		WHEN 'M' THEN CAST((CAST(num_of_pos AS DECIMAL)/@sum_comp_m)*100 AS DECIMAL (5,2))
		WHEN 'L' THEN CAST((CAST(num_of_pos AS DECIMAL)/@sum_comp_l)*100 AS DECIMAL (5,2))
	END as ratio
FROM 
	vw_job_insight_5
ORDER BY 
	CASE company_size
		WHEN 'S' THEN 0
		WHEN 'M' THEN 1
		WHEN 'L' THEN 2
	END,
	work_setting


-- This solution has been validated by cross-checking it with the actual results