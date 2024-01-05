-- 5) What is the association between company size and work setting?

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