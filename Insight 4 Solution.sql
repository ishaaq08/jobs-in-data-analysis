-- 4) What is the association between company size and experienced professionals e.g. does a smaller company have less experienced positions?

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


GO 

-- Check if the stored procedure exists before creating

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[sp_job_proc]') AND type in (N'P', N'PC'))
DROP PROCEDURE [sp_job_proc]

GO

-- Creating the stored procedure

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