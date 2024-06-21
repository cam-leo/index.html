




--The number of lifters registered on openPL
SELECT
    COUNT(name)
FROM openpowerlifting;



--The youngest and oldest lifter registered
SELECT
    MIN(age) AS youngest,
    MAX(age) AS oldest
FROM openpowerlifting;

--Note that we have many lifters with unfulfilled records such as Age,Sex etc. Thus giving us anomalies such as the youngest age being 0.

SELECT
    COUNT(name)
FROM openpowerlifting
WHERE age IS NOT NULL AND sex IS NOT NULL;

--As we can see, this cut down the number of lifters from 1423354 to 757527, we will use this as our main data source

-- Create a new table with the filtered data
CREATE TABLE data AS
SELECT *
FROM openpowerlifting
WHERE age IS NOT NULL AND sex IS NOT NULL;

-- We are gonna focus only on the USAPL federation for now.

CREATE TABLE usapl AS
SELECT
    Name,
    Sex,
    Event,
    Equipment,
    CAST(Age AS DECIMAL) AS Age,
    AgeClass,
    BirthYearClass,
    Division,
    CAST(WeightClassKg AS DECIMAL) AS WeightClassKg,
    CAST(Squat1Kg AS DECIMAL) AS Squat1Kg,
    CAST(Squat2Kg AS DECIMAL) AS Squat2Kg,
    CAST(Squat3Kg AS DECIMAL) AS Squat3Kg,
    CAST(Best3SquatKg AS DECIMAL) AS Best3SquatKg,
    CAST(Bench1Kg AS DECIMAL) AS Bench1Kg,
    CAST(Bench2Kg AS DECIMAL) AS Bench2Kg,
    CAST(Bench3Kg AS DECIMAL) AS Bench3Kg,
    CAST(Best3BenchKg AS DECIMAL) AS Best3BenchKg,
    CAST(Deadlift1Kg AS DECIMAL) AS Deadlift1Kg,
    CAST(Deadlift2Kg AS DECIMAL) AS Deadlift2Kg,
    CAST(Deadlift3Kg AS DECIMAL) AS Deadlift3Kg,
    CAST(Best3DeadliftKg AS DECIMAL) AS Best3DeadliftKg,
    CAST(TotalKg AS DECIMAL) AS TotalKg,
    Place,
    CAST(Dots AS DECIMAL) AS Dots,
    CAST(Wilks AS DECIMAL) AS Wilks,
    Tested,
    Country,
    State,
    Federation,
    ParentFederation,
    Date,
    MeetCountry,
    MeetState,
    MeetTown,
    MeetName
FROM data
WHERE federation = 'USAPL';

-- Number of registered USAPL members
    SELECT
        COUNT(DISTINCT name)
    FROM usapl;

--We have 90477 USAPL lifters
    SELECT
        COUNT (DISTINCT Name),
        Sex
    FROM usapl
    GROUP BY sex;
--We have 29252 female lifters, 61212 male lifters and 17 Mx lifters

-- number of times each lifter competed
    SELECT
        Name,
        COUNT(Name) AS num_of_compete
    FROM usapl
    GROUP BY Name
    ORDER BY num_of_compete DESC;

--# of SBD competitions
    SELECT
        COUNT(Name) AS total_sbd,
        COUNT(DISTINCT Name) AS sbd_lifters
    FROM usapl
    WHERE Event = 'SBD';


--Highest Dots Score for Raw SBD
    SELECT
        Sex,
        MIN(CAST(Dots AS DECIMAL)) AS lowest_dots,
        MAX(CAST(Dots AS DECIMAL)) AS highest_dots
    FROM usapl
    WHERE Event = 'SBD' AND Equipment = 'Raw'
    GROUP BY sex;
--The lowest dots could be explained due to a lifter bombing out and refusing to particpate in the rest of the competition, or registering only 1 lift.
--So we must filter those lifters out


SELECT
    Sex,
        MIN(CAST(Dots AS DECIMAL)) AS lowest_dots,
        MAX(CAST(Dots AS DECIMAL)) AS highest_dots
FROM usapl
WHERE
    Event = 'SBD' AND Equipment = 'Raw'
    AND
    Best3SquatKg IS NOT NULL
    AND
    Best3BenchKg IS NOT NULL
    AND
    Best3DeadliftKg IS NOT NULL
GROUP BY sex;

--the highest dots for both female and male regardless of weightclass or equipment
WITH RankedLifters AS (
    SELECT
        name,
        dots,
        sex,
        ROW_NUMBER() OVER (PARTITION BY sex ORDER BY CAST(Dots AS DECIMAL) DESC) AS rank_order
    FROM
        usapl
    WHERE Event = 'SBD'
)
SELECT
    name,
    dots,
    Sex
FROM
    RankedLifters
WHERE
    rank_order = 1;


--highest dots for both male,female for raw SBD
WITH RankedLifters AS (
    SELECT
        name,
        dots,
        sex,
        ROW_NUMBER() OVER (PARTITION BY sex ORDER BY CAST(Dots AS DECIMAL) DESC) AS rank_order
    FROM
        usapl
    WHERE Event = 'SBD' AND Equipment = 'Raw'
)
SELECT
    name,
    dots,
    Sex
FROM
    RankedLifters
WHERE
    rank_order = 1;
--for female, Amanda Lawrence
--for male, Austin Perkins
--for MX, Angle Flores


--highest total for weight classes over the years
SELECT
    strftime('%Y', "date") AS year,
    WeightClassKg,
    MAX(CAST(TotalKg AS DECIMAL)) AS highest_total
FROM usapl
WHERE sex = 'M'
GROUP BY
    strftime('%Y', "date"), WeightClassKg
ORDER BY year ASC, WeightClassKg ASC;



CREATE VIEW usapl_year AS
SELECT *,
       strftime('%Y', date) AS year
FROM usapl;

SELECT DISTINCT strftime('%Y', date) AS year
FROM usapl
ORDER BY year;

SELECT
    WeightClassKg,
    MAX(CASE WHEN year = '1997' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '1997',
    MAX(CASE WHEN year = '1998' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '1998',
    MAX(CASE WHEN year = '1999' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '1999',
    MAX(CASE WHEN year = '2000' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2000',
    MAX(CASE WHEN year = '2001' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2001',
    MAX(CASE WHEN year = '2002' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2002',
    MAX(CASE WHEN year = '2003' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2003',
    MAX(CASE WHEN year = '2004' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2004',
    MAX(CASE WHEN year = '2005' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2005',
    MAX(CASE WHEN year = '2006' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2006',
    MAX(CASE WHEN year = '2007' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2007',
    MAX(CASE WHEN year = '2008' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2008',
    MAX(CASE WHEN year = '2009' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2009',
    MAX(CASE WHEN year = '2010' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2010',
    MAX(CASE WHEN year = '2011' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2011',
    MAX(CASE WHEN year = '2012' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2012',
    MAX(CASE WHEN year = '2013' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2013',
    MAX(CASE WHEN year = '2014' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2014',
    MAX(CASE WHEN year = '2015' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2015',
    MAX(CASE WHEN year = '2016' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2016',
    MAX(CASE WHEN year = '2017' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2017',
    MAX(CASE WHEN year = '2018' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2018',
    MAX(CASE WHEN year = '2019' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2019',
    MAX(CASE WHEN year = '2020' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2020',
    MAX(CASE WHEN year = '2021' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2021',
    MAX(CASE WHEN year = '2022' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2022',
    MAX(CASE WHEN year = '2023' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2023',
    MAX(CASE WHEN year = '2024' THEN CAST(TotalKg AS DECIMAL) ELSE NULL END) AS '2024'
FROM
    usapl_year
WHERE Sex = 'M' AND Event = 'SBD' AND Equipment = 'Raw'
GROUP BY
    WeightClassKg
ORDER BY WeightClassKg;



--Create Raw Nationals Data
CREATE TABLE raw_nats AS
SELECT *
FROM usapl
WHERE (MeetName = 'Raw Nationals' OR MeetName = 'Mega Nationals') AND Equipment = 'Raw';

--Number of times each person has won Raw Nats
SELECT
    Name,
    Sex,
    Count(Name) AS num_times_won
FROM raw_nats
WHERE place = 1
GROUP BY Name, Sex
ORDER BY Sex, num_times_won DESC;









--Number of lifters that got 1st place and went 9/9
SELECT COUNT(name)
FROM usapl
WHERE
    Squat1Kg IS NOT NULL AND Squat1Kg > 0 AND
    Squat2Kg IS NOT NULL AND Squat2Kg > 0 AND
    Squat3Kg IS NOT NULL AND Squat3Kg > 0 AND
    Bench1Kg IS NOT NULL AND Bench1Kg > 0 AND
    Bench2Kg IS NOT NULL AND Bench2Kg > 0 AND
    Bench3Kg IS NOT NULL AND Bench3Kg > 0 AND
    Deadlift1Kg IS NOT NULL AND Deadlift1Kg > 0 AND
    Deadlift2Kg IS NOT NULL AND Deadlift2Kg > 0 AND
    Deadlift3Kg IS NOT NULL AND Deadlift3Kg > 0 AND
    Event = 'SBD' AND
    Equipment = 'Raw' AND
    Place = 1 AND
    (MeetName = 'Raw Nationals' OR MeetName = 'Mega Nationals');
--Number of lifters that did NOT get 1st place and did NOT go 9/9
SELECT COUNT(name)
FROM usapl
WHERE
    Squat1Kg IS NOT NULL AND Squat1Kg > 0 AND
    Squat2Kg IS NOT NULL AND Squat2Kg > 0 AND
    Squat3Kg IS NOT NULL AND Squat3Kg > 0 AND
    Bench1Kg IS NOT NULL AND Bench1Kg > 0 AND
    Bench2Kg IS NOT NULL AND Bench2Kg > 0 AND
    Bench3Kg IS NOT NULL AND Bench3Kg > 0 AND
    Deadlift1Kg IS NOT NULL AND Deadlift1Kg > 0 AND
    Deadlift2Kg IS NOT NULL AND Deadlift2Kg > 0 AND
    Deadlift3Kg IS NOT NULL AND Deadlift3Kg > 0 AND
    Event = 'SBD' AND
    Equipment = 'Raw' AND
    Place IS NOT 1 AND
    (MeetName = 'Raw Nationals' OR MeetName = 'Mega Nationals');



--Number of lifters taht got 1st place and did NOT go 9/9
SELECT COUNT(name)
FROM usapl
WHERE
    Event = 'SBD' AND
    Equipment = 'Raw' AND
    Place = 1 AND
    (MeetName = 'Raw Nationals' OR MeetName = 'Mega Nationals');




--The improvement in both total and dots for raw national lifters from their first national competition to their latest
WITH lifter_competitions AS (
    SELECT
        name,
        date,
        TotalKg,
        Dots,
        WeightClassKg,

        ROW_NUMBER() OVER (PARTITION BY name ORDER BY date) AS competition_order
    FROM
        raw_nats
),

first_latest_competitions AS (
    SELECT
        lc.name,
        MIN(lc.date) AS first_competition_date,
        MAX(lc.date) AS latest_competition_date,
        MIN(lc.WeightClassKg) AS first_weight,
        
        MAX(CASE WHEN lc.competition_order = 1
                THEN lc.TotalKg END) AS first_competition_total,
        MAX(CASE WHEN lc.competition_order = (
            SELECT MAX(competition_order)
            FROM lifter_competitions lc2
            WHERE lc2.name = lc.name)
                THEN lc.TotalKg END
        ) AS latest_competition_total,
        MAX(CASE WHEN lc.competition_order = 1
                THEN lc.dots END) AS first_dots,
        MAX(CASE WHEN lc.competition_order = (
            SELECT MAX(competition_order)
            FROM lifter_competitions lc2
            WHERE lc2.name = lc.name)
                THEN lc.dots END
        ) AS latest_dots

    FROM
        lifter_competitions lc
    GROUP BY
        lc.name
)

SELECT
    flc.name,
    flc.first_competition_date,
    flc.latest_competition_date,
    flc.first_competition_total,
    flc.latest_competition_total,
    (flc.latest_competition_total - flc.first_competition_total) AS performance_improvement,
    ROUND((flc.latest_dots - flc.first_dots),2) AS dots_improvement
FROM
    first_latest_competitions flc
WHERE
    flc.first_competition_total IS NOT NULL
    AND flc.latest_competition_total IS NOT NULL
    AND flc.latest_competition_total > flc.first_competition_total
    AND flc.first_dots IS NOT NULL
    AND flc.latest_dots IS NOT NULL
    AND flc.latest_dots > flc.first_dots
ORDER BY
    performance_improvement DESC, dots_improvement DESC;





