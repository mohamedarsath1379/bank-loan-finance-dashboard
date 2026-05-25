-- Query 1: Total Loan Applications and Amount
SELECT 
    COUNT(*) as Total_Applications,
    ROUND(SUM(loan_amnt), 2) as Total_Loan_Amount,
    ROUND(AVG(loan_amnt), 2) as Avg_Loan_Amount,
    ROUND(MAX(loan_amnt), 2) as Max_Loan_Amount,
    ROUND(MIN(loan_amnt), 2) as Min_Loan_Amount
FROM loans;

-- Query 2: Good Loan vs Bad Loan Summary
select 
count(*) as Total_loans ,
ROUND(SUM(loan_amnt), 2) as Total_Loan_Amount,
ROUND(AVG(loan_amnt), 2) as Avg_Loan_Amount,
ROUND(AVG(int_rate),2)AS Avg_int_rate

from loans
group by loan_category 
order by Total_loans desc;

-- Query 3: Monthly Loan Trend
select 
issue_month_name as Month,
issue_month as Month_Number,
count(*) as Total_Applications,
round(sum(loan_amnt),2) as Total_Amount
from loans
where issue_month_name is NOT NULL
GROUP BY issue_month_name, issue_month
ORDER BY Month_Number;

-- Query 4: Loan Purpose Analysis
select 
purpose,
count(*) as total_loan,
round(sum(loan_amnt),2) as Total_Amount,
ROUND(AVG(int_rate), 2) as Avg_Interest_Rate,
round(count(*) * 100.0 /(select count(*)from loans),2) as percentage
from loans
group by purpose
order by total_loan desc
limit 10;

-- Query 5: Loan Grade Analysis
select 
grade,
count(*)as total_loans,
round(avg(int_rate),2) as Avg_Interest_Rate,
round(avg(loan_amnt),2) as Avg_Loan_Amount,
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM loans), 2) as Percentage
from loans
group by grade
order by grade ;

-- Advanced Query 1: Running Total of Loan Amount by Month
SELECT 
    issue_month_name as Month,
    issue_month as Month_Number,
    COUNT(*) as Monthly_Applications,
    ROUND(SUM(loan_amnt), 2) as Monthly_Amount,
    ROUND(SUM(SUM(loan_amnt)) OVER (
        ORDER BY issue_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) as Running_Total
FROM loans
WHERE issue_month IS NOT NULL
GROUP BY issue_month_name, issue_month
ORDER BY Month_Number;

-- Advanced Query 2: Month over Month Growth Rate
WITH monthly_data AS (
    SELECT 
        issue_month as Month_Number,
        issue_month_name as Month,
        COUNT(*) as Applications,
        SUM(loan_amnt) as Total_Amount
    FROM loans
    WHERE issue_month IS NOT NULL
    GROUP BY issue_month, issue_month_name
)
SELECT 
    Month,
    Applications,
    ROUND(Total_Amount, 2) as Total_Amount,
    LAG(Applications) OVER (ORDER BY Month_Number) as Prev_Month_Apps,
    ROUND(
        (Applications - LAG(Applications) OVER (ORDER BY Month_Number)) * 100.0 /
        LAG(Applications) OVER (ORDER BY Month_Number), 2
    ) as MoM_Growth_Pct
FROM monthly_data
ORDER BY Month_Number;

-- Advanced Query 3: Default Rate by Purpose using CASE
SELECT 
    purpose,
    COUNT(*) as Total_Loans,
    SUM(CASE WHEN loan_category = 'Bad Loan' THEN 1 ELSE 0 END) as Bad_Loans,
    SUM(CASE WHEN loan_category = 'Good Loan' THEN 1 ELSE 0 END) as Good_Loans,
    ROUND(
        SUM(CASE WHEN loan_category = 'Bad Loan' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) as Default_Rate_Pct
FROM loans
GROUP BY purpose
ORDER BY Default_Rate_Pct DESC
LIMIT 10;

-- Advanced Query 4: Rank States by Total Loan Amount
SELECT 
    addr_state as State,
    COUNT(*) as Total_Loans,
    ROUND(SUM(loan_amnt), 2) as Total_Amount,
    RANK() OVER (ORDER BY SUM(loan_amnt) DESC) as State_Rank
FROM loans
WHERE addr_state IS NOT NULL
    AND addr_state != 'Unknown'
GROUP BY addr_state
ORDER BY State_Rank
LIMIT 15;

-- Advanced Query 5: CTE — High Risk Borrower Analysis
WITH borrower_risk AS (
    SELECT 
        emp_length,
        home_ownership,
        COUNT(*) as Total_Borrowers,
        ROUND(AVG(annual_inc), 2) as Avg_Income,
        ROUND(AVG(dti), 2) as Avg_DTI,
        ROUND(AVG(int_rate), 2) as Avg_Interest,
        SUM(CASE WHEN loan_category = 'Bad Loan' THEN 1 ELSE 0 END) as Defaults
    FROM loans
    GROUP BY emp_length, home_ownership
)
SELECT 
    emp_length,
    home_ownership,
    Total_Borrowers,
    Avg_Income,
    Avg_DTI,
    Avg_Interest,
    Defaults,
    ROUND(Defaults * 100.0 / Total_Borrowers, 2) as Default_Rate
FROM borrower_risk
WHERE Total_Borrowers > 100
ORDER BY Default_Rate DESC
LIMIT 10;

-- Advanced Query 6: Income Group Analysis using CASE
select
      case 
      when annual_inc < 30000 then 'Low Income (<30K)'
      when annual_inc between 30000 and 60000 then 'Mid Income (30K-60K)'
      WHEN annual_inc BETWEEN 60000 AND 100000 THEN 'Upper Mid (60K-100K)'
      ELSE 'High Income (>100K)'
      end as Income_Group ,
      count(*) as total_loans,
      round(avg(loan_amnt),2) as Avg_Loan,
      round(avg(int_rate),2) as Avg_Interest,
      round(
            sum(case when loan_category = 'Bad Loan' then 1 else 0 end) *100.0/count(*),2 
      )  as default_rate
      from loans
      group by Income_Group 
      order by default_rate desc;