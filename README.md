# About the Project 

- This project focused on performing **data exploration in SQL Server** with the supplementation of **Microsoft Power BI** to visualise patterns and trends.
- The project included intermediate/advanced SQL techniques such as **Stored Procedures, Views, Temp Tables, Nested CTE's** - **please note that some techniques were purely used in this project to gain compotency in the particular skill and thus their application in this project may be questionable to users with greater expertise in SQL **
- The dataset used was provided by [Kaggle]() - currently experience troubles sourcing the data link.

# Methodology

After an initial analysis of the dataset **5 questions** were created. It was then the job of SQL to efficiently query the data and Power BI to visualise the query results and obtain actionable insights. 

### Insight 1 - In which locations do you earn the most in certain sectors such as data engineering, ML etc?
- Simple groupby and aggregations.
- ROW_NUMBER() window function to rank the salaries in different sectors.

### Insight 2 - How does salary differ between locations for a given sector at a given experience level?
- Simple groupby's for the location, experience level and category columns and aggregations to average the salaries.

### Insight 3 - What is the average % salary increase as experience increases for a given job category?
- CASE WHEN to order data by a custom list of strings.
- LAG() window function to calculate % change.
- Nested CTE's to efficiently query subsets of data and overcome hinderences regarding the prohibition of the use of aggregate functions in window functions.

### Insight 4 - What is the association between company size and experienced professionals e.g. does a smaller company have less experienced positions?
- Temp table to perform complex calculations and store intermediate results.
- Stored Procedures to enhance query performance - calculate the total number of job positions for different company sizes whilst minimising repetitive code. 

### Insight 5 - What is the association between company size and work setting?
- Views to store intermediate results and further query the subset of data. 

# Conclusions
