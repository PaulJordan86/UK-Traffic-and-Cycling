USE UK_Traffic

SELECT * FROM traffic_count
/* Data has been imported from UK government traffic surveys as traffic_count, containing 21 years of aggregated traffic count data

We will create a table with central government funding data, including TeamGB olympic cycling funding, to explore whether there is a direct
between government funding for the promotion of cycling, and uptake of cycling as a means of transport
*/
CREATE TABLE olympic_funding
(Year int, olympic_cycle nvarchar(30), funding_amount int);

INSERT INTO olympic_funding
VALUES 
(2000,'Sydney',3993317), 
(2004,'Athens',6920582), 
(2008, 'Beijing', 19785347), 
(2012, 'London', 20613900), 
(2016, 'Rio', 23966916), 
(2020,'Tokyo',24559306);

select * from olympic_funding;

CREATE TABLE Central_Government_Funding
(Year int, funding_amount int);

INSERT INTO Central_government_funding
VALUES
(2000,0), (2001,0), (2002,0), (2003,0),
(2004,0), (2005, 5000000), (2006, 10000000), 
(2007, 10000000), (2008, 20000000), (2009, 60000000), 
(2010, 60000000), (2011, 100000000), (2012, 100000000),
(2013, 100000000), (2014, 100000000), (2015, 100000000), 
(2016, 632000000), (2017,63200000), (2018,63200000), (2019, 63200000),
(2020, 63200000), (2021,63200000);

-- Now to add some more metrics to this table, which we can use to look for correlation with cycling uptake

-- After validating data on Tableau, it is clear we have a mistake on data input

UPDATE central_government_funding
SET funding_amount = 63200000
WHERE year = 2016;

-- A couple of extra metrics to look at other factors which may affect people using their bikes instead of 
-- Is it the carrot, the stick, or just nature?

ALTER TABLE central_government_funding
ADD rain_days int;

ALTER TABLE central_government_funding
ADD Avg_temp decimal (5,2);

ALTER TABLE central_government_funding
ADD Avg_Fuel_Price decimal (5,2);


-- Add in some temperature data to see if this correlates to cycling growth

UPDATE central_government_funding
SET Avg_temp = 8.96
WHERE Year =2001;

-- Check for missed values

SELECT * FROM Central_Government_Funding
WHERE Avg_temp IS NULL;

-- And Rain days

UPDATE central_government_funding
SET rain_days =174
WHERE Year = 2014;

-- Check nulls

SELECT * FROM Central_Government_Funding
WHERE rain_days IS NULL;

-- now the stick


UPDATE central_government_funding
SET Avg_fuel_price = 123.9
WHERE Year = 2021;

SELECT * FROM Central_Government_Funding
WHERE avg_fuel_price IS NULL;

/* With these all added and values checked, we can write a query, to create a view for Tableau, to present this 
data clearly and assess any potential correlation between external factors, and cycling uptake in the UK
*/
WITH totals AS
(
SELECT Year, SUM(Pedal_Cycles) AS cycle_count, SUM(All_Motor_Vehicles) AS total_vehicles,
CAST(100.0*SUM(Pedal_Cycles)/SUM(All_Motor_Vehicles) AS DECIMAL (5,2)) AS percent_of_total
FROM traffic_count
GROUP BY Year
), funding AS
(
SELECT c.year, 
CASE WHEN o.funding_amount IS NULL THEN 0 ELSE o.funding_amount END as olympics,
c.funding_amount AS government,
CASE WHEN o.funding_amount IS NULL THEN 0 ELSE o.funding_amount END+c.funding_amount as total_funding, 
CASE WHEN o.funding_amount IS NULL THEN 0 ELSE o.funding_amount END+c.funding_amount-
LAG(CASE WHEN o.funding_amount IS NULL THEN 0 ELSE o.funding_amount END+c.funding_amount,1, 3993317) OVER(order by c.year) as funding_change from central_government_funding c
LEFT JOIN olympic_funding o
ON c.year = o.year
)
SELECT t.year, cycle_count, total_vehicles, percent_of_total,cycle_count - LAG(cycle_count,1,1754959) OVER (ORDER BY t.year) AS change_in_cycle_count,olympics, total_funding, funding_change,
  Avg_Fuel_Price, Avg_temp, rain_days
FROM totals t
JOIN funding f
ON t.Year = f.Year
JOIN Central_Government_Funding c
ON t.year = c.year;
