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
