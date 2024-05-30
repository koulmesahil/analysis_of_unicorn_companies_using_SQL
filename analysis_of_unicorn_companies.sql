/* 
--------------------------------------------------------------------------------------------------------
Data Cleaning for Unicorn Companies Analytics Project
--------------------------------------------------------------------------------------------------------
*/


USE UnicornCompanies

SELECT *
FROM UnicornCompanies.dbo.unicorn_info
ORDER BY 1 ASC

SELECT *
FROM UnicornCompanies.dbo.unicorn_finance
ORDER BY 1 ASC


--------------------------------------------------------------------------------------------------------

-- Check duplicate company name

SELECT Company, COUNT(Company)
FROM UnicornCompanies.dbo.unicorn_info
GROUP BY Company
HAVING COUNT(Company) > 1

SELECT Company, COUNT(Company)
FROM UnicornCompanies.dbo.unicorn_finance
GROUP BY Company
HAVING COUNT(Company) > 1
-- > Bolt and Fabric appear twice in both data sets. Anyway, they are in different cities / countries. 
-- > Therefore, we will keep those data.


--------------------------------------------------------------------------------------------------------

-- Rename columns
EXEC sp_rename 'dbo.unicorn_info.[Year Founded]', 'YearFounded', 'COLUMN';
EXEC sp_rename 'dbo.unicorn_finance.[Date Joined]', 'DateJoined', 'COLUMN';
EXEC sp_rename 'dbo.unicorn_finance.[Select Investors]', 'SelectInvestors', 'COLUMN';

SELECT *
FROM UnicornCompanies.dbo.unicorn_finance


--------------------------------------------------------------------------------------------------------

-- Standardize date joined format & break out date joined into individual columns (Year, Month, Day)

ALTER TABLE UnicornCompanies.dbo.unicorn_finance
ADD DateJoinedConverted DATE
UPDATE UnicornCompanies.dbo.unicorn_finance
SET DateJoinedConverted = CONVERT(DATE, DateJoined)

ALTER TABLE UnicornCompanies.dbo.unicorn_finance
ADD Year INT
UPDATE UnicornCompanies.dbo.unicorn_finance
SET Year = DATEPART(YEAR, DateJoinedConverted)

ALTER TABLE UnicornCompanies.dbo.unicorn_finance
ADD Month INT
UPDATE UnicornCompanies.dbo.unicorn_finance
SET Month = DATEPART(MONTH, DateJoinedConverted)

ALTER TABLE UnicornCompanies.dbo.unicorn_finance
ADD Day INT
UPDATE UnicornCompanies.dbo.unicorn_finance
SET Day = DATEPART(DAY, DateJoinedConverted)

SELECT *
FROM UnicornCompanies.dbo.unicorn_finance


--------------------------------------------------------------------------------------------------------

-- Drop rows where Funding column contain 0 or Unknown

DELETE FROM UnicornCompanies.dbo.unicorn_finance 
WHERE Funding IN ('$0M', 'Unknown')

SELECT DISTINCT Funding
FROM UnicornCompanies.dbo.unicorn_finance
ORDER BY Funding DESC


--------------------------------------------------------------------------------------------------------

-- Reformat currency value

-- "Valuation" and "Funding" columns

UPDATE UnicornCompanies.dbo.unicorn_finance
SET Valuation = RIGHT(Valuation, LEN(Valuation) - 1)

UPDATE UnicornCompanies.dbo.unicorn_finance
SET Valuation = REPLACE(REPLACE(Valuation, 'B','000000000'), 'M', '000000')

UPDATE UnicornCompanies.dbo.unicorn_finance
SET Funding = RIGHT(Funding, LEN(Funding) - 1)

UPDATE UnicornCompanies.dbo.unicorn_finance
SET Funding = REPLACE(REPLACE(Funding, 'B','000000000'), 'M', '000000')

SELECT *
FROM UnicornCompanies.dbo.unicorn_finance


--------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE UnicornCompanies.dbo.unicorn_finance
DROP COLUMN DateJoined

EXEC sp_rename 'dbo.unicorn_finance.DateJoinedConverted', 'DateJoined', 'COLUMN'

SELECT *
FROM UnicornCompanies.dbo.unicorn_finance


--------------------------------------------------------------------------------------------------------


/* 
--------------------------------------------------------------------------------------------------------
Data Exploration for Unicorn Companies Analytics Project
--------------------------------------------------------------------------------------------------------


Reesearch Questions
=======================================================================================================
- Which unicorn companies have had the biggest return on investment?
- How long does it usually take for a company to become a unicorn?
- Which industries have the most unicorns? 
- Which countries have the most unicorns? 
- Which investors have funded the most unicorns?
=======================================================================================================
*/


USE UnicornCompanies

SELECT *
FROM UnicornCompanies.dbo.unicorn_info
ORDER BY 1 ASC

SELECT *
FROM UnicornCompanies.dbo.unicorn_finance
ORDER BY 1 ASC

-- Total Unicorn Companies
WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin 
		ON inf.ID = fin.ID)
SELECT COUNT(1) AS Unicorn
FROM UnicornCom
WHERE (Year - YearFounded) >= 0


-- Total Countries
WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin 
		ON inf.ID = fin.ID)
SELECT COUNT(DISTINCT Country) AS Country
FROM UnicornCom
WHERE (Year - YearFounded) >= 0


--------------------------------------------------------------------------------------------------------

/*
- Which unicorn companies have had the biggest return on investment?
*/


SELECT TOP 10 Company, (CONVERT(BIGINT, Valuation)-CONVERT(BIGINT, Funding))/CONVERT(BIGINT, Funding) AS Roi
FROM UnicornCompanies.dbo.unicorn_finance
ORDER BY Roi DESC
-- > 1.Zapier 2.Dunamu 3.Workhuman 4.CFGI 5.Manner 6.DJI Innovations 7.GalaxySpace 8.Canva 9.II Makiage 10.Revolution Precrafted


--------------------------------------------------------------------------------------------------------

/*
- How long does it usually take for a company to become a unicorn?
*/


-- Find average years to become a unicorn

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin 
		ON inf.ID = fin.ID)
SELECT CAST(AVG(Year - YearFounded) AS INT) AS AverageYear
FROM UnicornCom

-- > On average it takes 6 years to become a unicorn company


-- Details on how long it takes for the companies to become a unicorn

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin 
		ON inf.ID = fin.ID)
SELECT TOP 10 (Year - YearFounded) AS UnicornYear, COUNT(1) AS Frequency
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY (Year - YearFounded)
ORDER BY COUNT(1) DESC

-- Mostly take from 4 to 7 years to become a unicorn


--------------------------------------------------------------------------------------------------------

/*
- Which industries have the most unicorns? 
*/


-- Number of unicorn companies within each industry

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin
		ON inf.ID = fin.ID)
SELECT Industry, COUNT(1) as Frequency
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY Industry
ORDER BY COUNT(1) DESC

-- > Fintech followed by Internet software and services and e-commerce.


-- Number of unicorn companies within each industry and their shares

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin
		ON inf.ID = fin.ID
)
SELECT Industry, Count(1) AS Frequency, CAST(COUNT(1) * 100.0 / (SELECT COUNT(*) FROM UnicornCom) AS INT) AS 'Percentage'
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY Industry
ORDER BY Count(1) DESC


--------------------------------------------------------------------------------------------------------

/*
- Which countries have the most unicorns? 
*/


-- Number of unicorn companies within each country

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin
		ON inf.ID = fin.ID
)
SELECT Country, COUNT(1) AS Frequency
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY Country
ORDER BY Count(1) DESC

-- United States followed by China and India.


-- Number of unicorn companies within each country and their shares

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin
		ON inf.ID = fin.ID
)
SELECT TOP 10 Country, COUNT(1) AS Frequency, CAST(COUNT(1) * 100.0 / (SELECT COUNT(*) FROM UnicornCom) AS INT) AS 'Percentage'
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY Country
ORDER BY Count(1) DESC


--------------------------------------------------------------------------------------------------------

/*
- Which investors have funded the most unicorns?
*/


SELECT *
FROM UnicornCompanies.dbo.unicorn_finance
ORDER BY 1 ASC


-- Replace ', ' with ',' before doing the split

UPDATE UnicornCompanies.dbo.unicorn_finance
SET SelectInvestors = REPLACE(SelectInvestors, ', ', ',')


-- Get investor name list with their count

SELECT TOP 10 value AS Investors, COUNT(*) AS UnicornsInvested 
FROM UnicornCompanies.dbo.unicorn_finance
    CROSS APPLY STRING_SPLIT(SelectInvestors, ',')  
GROUP BY value  
ORDER BY COUNT(*) DESC 

-- > Accel followed  by Tiger Glabal Management and Andreessen Horowitz


--------------------------------------------------------------------------------------------------------


/* 
--------------------------------------------------------------------------------------------------------
Queries for Data Visualization
--------------------------------------------------------------------------------------------------------
*/


USE UnicornCompanies


-- Table 1
-- Total Unicorn Companies

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin 
		ON inf.ID = fin.ID)
SELECT COUNT(1) AS Unicorn
FROM UnicornCom
WHERE (Year - YearFounded) >= 0


-- Total Countries

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin 
		ON inf.ID = fin.ID)
SELECT COUNT(DISTINCT Country) AS Country
FROM UnicornCom
WHERE (Year - YearFounded) >= 0


-- Table 2 

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin 
		ON inf.ID = fin.ID)
SELECT Company, Country
FROM UnicornCom
WHERE (Year - YearFounded) >= 0



-- Table 3

SELECT Company, (CONVERT(BIGINT, Valuation)-CONVERT(BIGINT, Funding))/CONVERT(BIGINT, Funding) AS Roi
FROM UnicornCompanies.dbo.unicorn_finance
ORDER BY Roi DESC


-- Table 4

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin 
		ON inf.ID = fin.ID)
SELECT Company, (Year - YearFounded) AS UnicornYear
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
-- GROUP BY (Year - YearFounded)
-- ORDER BY COUNT(1) DESC


WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin 
		ON inf.ID = fin.ID)
SELECT (Year - YearFounded) AS UnicornYear, COUNT(1) AS Frequency
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY (Year - YearFounded)
ORDER BY COUNT(1) DESC



-- Table 5

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin
		ON inf.ID = fin.ID
)
SELECT Industry, Count(1) AS Frequency, CAST(COUNT(1) * 100.0 / (SELECT COUNT(*) FROM UnicornCom) AS INT) AS 'Percentage'
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY Industry
ORDER BY Count(1) DESC


-- Table 6

WITH UnicornCom (ID, Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
	(SELECT inf.ID, inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
			fin.Year, fin.SelectInvestors
	FROM UnicornCompanies.dbo.unicorn_info AS inf
	INNER JOIN UnicornCompanies.dbo.unicorn_finance AS fin
		ON inf.ID = fin.ID
)
SELECT Country, COUNT(1) AS Frequency, CAST(COUNT(1) * 100.0 / (SELECT COUNT(*) FROM UnicornCom) AS INT) AS 'Percentage'
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY Country
ORDER BY Count(1) DESC


-- Table 7

SELECT value AS Investors, COUNT(*) AS UnicornsInvested 
FROM UnicornCompanies.dbo.unicorn_finance
    CROSS APPLY STRING_SPLIT(SelectInvestors, ',')  
GROUP BY value  
ORDER BY COUNT(*) DESC 

