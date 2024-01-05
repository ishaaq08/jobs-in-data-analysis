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