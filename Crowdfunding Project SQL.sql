show databases;

CREATE DATABASE Crowdfunding;
USE Crowdfunding;

CREATE TABLE Crowdfunding_projects_1 (
    id INT PRIMARY KEY,
    state VARCHAR(50),
    name VARCHAR(255),
    country VARCHAR(50),
    creator_id INT,
    location_id INT,
    category_id INT,
    created_at BIGINT,
    deadline BIGINT,
    updated_at BIGINT,
    state_changed_at BIGINT,
    successful_at BIGINT,
    launched_at BIGINT,
    goal FLOAT,
    pledged FLOAT,
    currency VARCHAR(10),
    usd_pledged FLOAT,
    static_usd_rate FLOAT,
    backers_count INT,
    spotlight BOOLEAN,
    staff_pick BOOLEAN,
    blurb TEXT,
    currency_trailing_code BOOLEAN,
    disable_communication BOOLEAN
);

LOAD DATA LOCAL INFILE 'C:\\Users\\hp pc\\OneDrive\\Desktop\\SQL CSV Files\\Crowdfunding_projects_1.csv'
INTO TABLE Crowdfunding_projects_1
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, state, name, country, creator_id, location_id, category_id, created_at, deadline, updated_at, state_changed_at, successful_at, launched_at, goal, pledged, currency, usd_pledged, static_usd_rate, backers_count, spotlight, staff_pick, blurb, currency_trailing_code, disable_communication);

CREATE TABLE Crowdfunding_Location (
    id INT PRIMARY KEY,
    displayable_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    type VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    state VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    is_root VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    country VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    localized_name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
);

LOAD DATA LOCAL INFILE 'C:\\Users\\hp pc\\OneDrive\\Desktop\\SQL CSV Files\\Crowdfunding_Location.csv'
INTO TABLE Crowdfunding_Location
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, displayable_name, type, name, state, is_root, country, localized_name);

SHOW WARNINGS LIMIT 10;

CREATE TABLE crowdfunding_Category (
    id INT PRIMARY KEY,
    name VARCHAR(255),
    parent_id INT,
    position INT
);

LOAD DATA LOCAL INFILE 'C:\\Users\\hp pc\\OneDrive\\Desktop\\SQL CSV Files\\crowdfunding_Category.csv'
INTO TABLE Crowdfunding_Category
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, name, parent_id, position);

CREATE TABLE Crowdfunding_Creator (
    id INT PRIMARY KEY,
    name VARCHAR(255),
    chosen_currency VARCHAR(100)
);

LOAD DATA LOCAL INFILE 'C:\\Users\\hp pc\\OneDrive\\Desktop\\SQL CSV Files\\Crowdfunding_Creator.csv'
INTO TABLE Crowdfunding_Creator
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, name, chosen_currency);

CREATE TABLE Calendar (
    ID INT PRIMARY KEY,
    Created_Date DATE,
    Date DATE,
    Year INT,
    MonthNo INT,
    MonthName VARCHAR(20),
    Quarter INT,
    YearMonth VARCHAR(7),
    WeekdayNo INT,
    WeekdayName VARCHAR(20),
    Financial_Month VARCHAR(20),
    Financial_Quarter INT
);

LOAD DATA LOCAL INFILE 'C:\\Users\\hp pc\\OneDrive\\Desktop\\SQL CSV Files\\Calendar.csv'
INTO TABLE calendar
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(ID, Created_Date, Date, Year, MonthNo, MonthName, Quarter, YearMonth, WeekdayNo, WeekdayName, Financial_Month, Financial_Quarter);

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

SELECT
    id, 
    name,
    FROM_UNIXTIME(created_at) AS created_date,
    FROM_UNIXTIME(deadline) AS deadline_date,
    FROM_UNIXTIME(updated_at) AS updated_date,
    FROM_UNIXTIME(state_changed_at) AS state_changed_date,
    FROM_UNIXTIME(successful_at) AS successful_date,
    FROM_UNIXTIME(launched_at) AS launched_date,
     goal, 
     pledged
FROM Crowdfunding_projects_1 LIMIT 10;

SET @start_date = (SELECT MIN(FROM_UNIXTIME(created_at)) FROM Crowdfunding_projects_1);
SET @end_date = (SELECT MAX(FROM_UNIXTIME(deadline)) FROM Crowdfunding_projects_1);


SET SQL_SAFE_UPDATES = 1;

##--- Build the Data Model using the attached Excel Files.(used joins)--##

SELECT 
    p.id AS ProjectID,
    p.name AS ProjectName,
    p.country AS Country,
    p.state AS ProjectState,
    p.goal AS GoalAmount,
    p.pledged AS PledgedAmount,
    p.currency AS Currency,
    p.usd_pledged AS PledgedAmountInUSD,
    p.backers_count AS BackersCount,
    c.name AS CreatorName,
    c.chosen_currency AS CreatorCurrency,
    l.displayable_name AS LocationDisplayableName,
    l.state AS LocationState,
    l.country AS LocationCountry,
    cat.name AS CategoryName,
    cat.parent_id AS ParentCategoryID,
    cat.position AS CategoryPosition
FROM 
    Crowdfunding_projects_1 p
LEFT JOIN 
    Crowdfunding_Creator c ON p.creator_id = c.id
LEFT JOIN 
    Crowdfunding_Location l ON p.location_id = l.id
LEFT JOIN 
    Crowdfunding_Category cat ON p.category_id = cat.id;
    
  ##--Convert the Goal amount into USD using the Static USD Rate.--##
  
ALTER TABLE Crowdfunding_projects_1 ADD COLUMN GoalAmount int;
UPDATE Crowdfunding_projects_1
SET GoalAmount = Goal*static_usd_rate;

SET SQL_SAFE_UPDATES = 0;
SET SQL_SAFE_UPDATES = 1;

##---Projects Overview KPI :   Total Number of Projects based on outcome---#


select state as Outcome ,count(ID) as No_of_Projects 
from Crowdfunding_projects_1 
group by state;

##---Total Number of Projects based on Locations---#

select country as Location,count(id) 
from Crowdfunding_projects_1
group by country;

##---Total Number of Projects based on  Category---##

select cat.name AS Category,
count(*) as No_of_projects
FROM crowdfunding_Category cat LEFT JOIN Crowdfunding_projects_1 p ON cat.id = p.category_id
GROUP BY cat.name
ORDER BY  No_of_projects desc;

##---Total Number of Projects created by Year , Quarter , Month---#

SELECT 
    YEAR(created_at) AS Year,  
    QUARTER(created_at) AS Quarter,
    MONTHNAME(created_at) AS Month_Name,  
    COUNT(*) AS No_of_Projects 
FROM Crowdfunding_projects_1
GROUP BY YEAR(created_at), QUARTER(created_at), MONTHNAME(created_at)
ORDER BY YEAR(created_at), QUARTER(created_at), MONTHNAME(created_at);

##---Successful Projects based on Amount Raised---##

select state,concat(round(sum(Goal)/1000000),'M') as Amount_Raised 
from Crowdfunding_projects_1 
where state="successful";

##---Successful Projects based on No of Backers--##

select state,concat(round(sum(backers_count)/1000000),'M') as No_of_Backers 
from Crowdfunding_projects_1
where state="successful";

##---Average no of days for Successful Projects ---##

SELECT 
    ROUND(AVG(DATEDIFF(successful_at, created_at))) AS Average_Days
FROM Crowdfunding_projects_1
WHERE state = 'successful';

SELECT COUNT(*) AS NullValues 
FROM Crowdfunding_projects_1 
WHERE successful_at IS NULL AND state = 'successful';

SELECT id, created_at, successful_at, state 
FROM Crowdfunding_projects_1 
WHERE state = 'successful' 
LIMIT 10;

SELECT 
    ROUND(AVG(DATEDIFF(IFNULL(successful_at, state_changed_at), created_at))) AS Average_Days
FROM Crowdfunding_projects_1
WHERE state = 'successful';




##---Top Successful Projects :Based on Number of Backers---##

select name,concat(round(Backers_count/1000),'K') as No_of_Backers 
from Crowdfunding_projects_1 
where state="successful" 
order by Backers_count 
desc limit 10;

##---Top Successful Projects :Based on Amount Raised---#

select name,concat(round(GoalAmount/1000000),'M') as Amount_Raised 
from Crowdfunding_projects_1
where state="successful" 
order by GoalAmount 
desc limit 10 ;

##---Percentage of Successful Projects overall---##

SELECT 
    concat(round(COUNT(CASE WHEN state = 'successful' THEN 1 END) * 100.0 / COUNT(*),2),"%") AS percentage_successful_projects
FROM Crowdfunding_projects_1;

 ##---Percentage of Successful Projects  by Category---##
 
 SELECT 
    c.name AS Category,
    CONCAT(ROUND(COUNT(CASE WHEN p.state = 'successful' THEN 1 END) * 100 / COUNT(*), 2), "%") AS percentage_successful_projects
FROM Crowdfunding_Category c
LEFT JOIN Crowdfunding_projects_1 p ON c.id = p.category_id
GROUP BY c.name
ORDER BY c.name;

##---Percentage of Successful Projects by Year ,Quarter, Month---##

select Year,Quarter,Month_name,percentage_successful_projects
from (SELECT YEAR(created_at) AS Year, 
             MONTH(created_at) AS Month,
		     QUARTER(created_at) AS quarter,
             MONTHname(created_at) AS Month_Name, 
             concat(round(COUNT(CASE WHEN state = 'successful' THEN 1 END) * 100 / COUNT(*),2),"%") AS percentage_successful_projects
FROM Crowdfunding_projects_1
GROUP BY year,month,Quarter,month_name
order by year, quarter,month) as P;

##-----Percentage of Successful projects by Goal Range ( decide the range as per your need )-----##

SELECT 
  CASE WHEN GoalAmount < 1000 THEN 'Low'
    WHEN GoalAmount >= 1000 AND GoalAmount < 10000 THEN 'Medium'
    ELSE 'High'
    END AS GoalAmount,
  concat(round(COUNT(CASE WHEN state = 'successful' THEN 1 END) * 100 / COUNT(*),2),"%") AS percentage_successful_projects
FROM Crowdfunding_projects_1
GROUP BY GoalAmount
ORDER BY FIELD(GoalAmount, 'High', 'Medium', 'Low');