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