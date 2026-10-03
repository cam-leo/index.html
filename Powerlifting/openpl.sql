
--Table of Contents
-- 1. Basic Queries
--      1.1 Number of lifters on openpowerlifting
--      1.2 Youngest/Oldest lifter registered on openpowerlifting
--      1.3 Filtering openpowerlifting dataset
-- 2. Creating usapl dataset
--      2.1 Number of lifters registered with usapl
--      2.2 Youngest/Oldest lifter registered with usapl
--      2.3 Number of times each lifter competed with usapl
--      2.4 Number of SBD competitions in the usapl
--      2.5 Highest DOTS score
--		2.6 Highest DOTS for both m/f/mx regardless of weightclass
--		2.7 Highest total for weightclasses over the years
--		2.8 Finding age at which each lifter hit their peak performance
--		2.9 Effectiveness of each training program for lifters
--		2.10 (removed) Competition vs in-training gym performance
--		2.11 Recovery time impact on performance
--		2.12 Lift ratio over time
--
-- NOTE: training_data is randomly generated practice data (lifts drawn independently each
-- week, programs assigned at random, anonymised lifter IDs). Results from sections 2.8-2.12
-- show how to write the queries; they say nothing about real training.
-- 3. Creating Raw Nationals Data
--		3.1 Number of times a person has won nationals
--		3.2 Number of lifters that got 1st place and went 9/9
--		3.3 Number of lifters that didn't get 1st place and did NOT go 9/9
--		3.4 Number of lifters that got 1st place and did NOT go 9/9
--		3.5 Improvement in total/DOTS for national lifters from 1st comp to latest




-- 1.1 The number of entries and lifters on openPL
-- Each row is one entry (one lifter at one meet in one division), so COUNT(name) counts
-- entries, not people. COUNT(DISTINCT name) counts lifters; OpenPowerlifting adds "#1", "#2"
-- to names shared by different people, so Name identifies a lifter.
SELECT
    COUNT(*)             AS entries,
    COUNT(DISTINCT name) AS lifters
FROM openpowerlifting;



-- 1.2 The youngest and oldest lifter registered
SELECT
    MIN(age) AS youngest,
    MAX(age) AS oldest
FROM openpowerlifting;

--Note that we have many lifters with unfulfilled records such as Age,Sex etc. Thus giving us anomalies such as the youngest age being 0.

SELECT
    COUNT(name),
    MIN(age),
    MAX(Age)
FROM openpowerlifting
WHERE age IS NOT NULL AND sex IS NOT NULL AND AgeClass IS NOT NULL AND BirthYearClass IS NOT NULL;

-- 1.3
--As we can see, this cut down the number of entries from 1423354 to 757527, we will use this as our main data source.
--Keep in mind that every result built on `data` (including all the USAPL results) only covers entries with a known age.

-- Create a new table with the filtered data
CREATE TABLE data AS
SELECT *
FROM openpowerlifting
WHERE age IS NOT NULL AND sex IS NOT NULL AND AgeClass IS NOT NULL AND BirthYearClass IS NOT NULL;

-- 2.
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
    WeightClassKg,  -- kept as text: CAST would turn the super-heavyweight class '120+' into 120 and merge it with the 120 kg class
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
    Place,  -- text: '1', '2', ... or 'DQ', 'G' (guest), etc.
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


-- 2.1
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


-- 2.2
-- The oldest and youngest USAPL members that competed

SELECT
    'Youngest Lifter' AS Age,
    MIN(age) AS Age_Value,
    name
FROM usapl
WHERE age = (SELECT MIN(age) FROM usapl)

UNION ALL

SELECT
    'Oldest Lifter' AS Age,
    MAX(age) AS Age_Value,
    name
FROM usapl
WHERE age = (SELECT MAX(age) FROM usapl);



-- 2.3
-- number of times each lifter competed
    SELECT
        Name,
        COUNT(Name) AS num_of_compete
    FROM usapl
    GROUP BY Name
    ORDER BY num_of_compete DESC;


-- 2.4
--# of SBD competitions
    SELECT
        COUNT(Name) AS total_sbd,
        COUNT(DISTINCT Name) AS sbd_lifters
    FROM usapl
    WHERE Event = 'SBD';


-- 2.5
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



-- 2.6
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


-- 2.7
--highest total for weight classes over the years
SELECT
    strftime('%Y', "date") AS year,
    WeightClassKg,
    MAX(CAST(TotalKg AS DECIMAL)) AS highest_total
FROM usapl
WHERE sex = 'M'
GROUP BY
    strftime('%Y', "date"), WeightClassKg
ORDER BY year ASC, CAST(REPLACE(WeightClassKg, '+', '') AS REAL), WeightClassKg LIKE '%+';



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
ORDER BY CAST(REPLACE(WeightClassKg, '+', '') AS REAL), WeightClassKg LIKE '%+';














--Training Data of each lifter in the USAPL


-- 2.8
--Finding the age at which each lifter hit their peak performance in each lift (S,B,D)


--SQLite version
--(An earlier Postgres version is removed: it called AGE() on a 'DateOfBirth' column that
-- training_data doesn't have, and passed it as a quoted string, so it couldn't run.)
--In SQLite, a bare column next to MAX() takes its value from the row holding the maximum,
--so PeakDate is the date of the peak lift.

-- Create table to store peak lifts
CREATE TABLE peak_performance AS
SELECT
    LifterID,
    'Squat' AS LiftType,
    MAX(Squat) AS PeakLift,
    TrainingDate AS PeakDate
FROM training_data
GROUP BY LifterID

UNION ALL

SELECT
    LifterID,
    'BenchPress' AS LiftType,
    MAX(BenchPress) AS PeakLift,
    TrainingDate AS PeakDate
FROM training_data
GROUP BY LifterID

UNION ALL

SELECT
    LifterID,
    'Deadlift' AS LiftType,
    MAX(Deadlift) AS PeakLift,
    TrainingDate AS PeakDate
FROM training_data
GROUP BY LifterID;

-- Retrieve peak performance
SELECT
    LifterID,
    LiftType,
    PeakLift,
    PeakDate
FROM peak_performance
ORDER BY LifterID, LiftType;



-- 2.9
--Comparing training programs
--An earlier version used MAX - MIN of each lift as the "gain" from a program. That isn't a gain:
--it ignores the order of sessions (a drop counts the same as an increase) and it grows with the
--number of sessions and with noise. Programs here also switch from week to week, so there is no
--program "block" to measure progress over. Instead we compare average weekly lifts per program;
--openpl.py tests whether the differences are larger than chance (ANOVA).
SELECT
    Program,
    COUNT(*)              AS sessions,
    ROUND(AVG(Squat), 1)      AS avg_squat,
    ROUND(AVG(BenchPress), 1) AS avg_bench,
    ROUND(AVG(Deadlift), 1)   AS avg_deadlift
FROM training_data
GROUP BY Program;




-- 2.10 (removed)
--Gym PRs vs competition results. This compared the synthetic training log with real competition
--results by joining on lifter name. Since the training numbers are random, the comparison was
--meaningless, and it put made-up training numbers next to real athletes' names. The training log
--now uses anonymous IDs, so it no longer joins to competition data.
--(The "future_competitions" view that followed was also always empty: its HAVING clause asked
-- for a meet date later than that lifter's latest meet date.)














-- 2.11
--recovery time impact on performance

WITH recovery_time AS (
    SELECT
        LifterID,
        TrainingDate,
        Squat,
        BenchPress,
        Deadlift,
        LAG(TrainingDate, 1) OVER (PARTITION BY LifterID ORDER BY TrainingDate) AS PrevTrainingDate
    FROM training_data
)

SELECT
    LifterID,
    TrainingDate,
    (JULIANDAY(TrainingDate) - JULIANDAY(PrevTrainingDate)) AS RecoveryDays,
    Squat,
    BenchPress,
    Deadlift
FROM recovery_time
WHERE PrevTrainingDate IS NOT NULL
ORDER BY LifterID, TrainingDate;

-- 2.12
--lift ratio over time

WITH cumulative_lifts AS (
    SELECT
        LifterID,
        TrainingDate,
        SUM(Squat) OVER (PARTITION BY LifterID ORDER BY TrainingDate) AS CumulativeSquat,
        SUM(Deadlift) OVER (PARTITION BY LifterID ORDER BY TrainingDate) AS CumulativeDeadlift
    FROM training_data
)

SELECT
    LifterID,
    TrainingDate,
    CumulativeSquat,
    CumulativeDeadlift,
    (CumulativeSquat * 1.0 / CumulativeDeadlift) AS SquatToDeadliftRatio
FROM cumulative_lifts
WHERE CumulativeDeadlift > 0
ORDER BY LifterID, TrainingDate;






-- 3.
-- Create Raw Nationals Data
CREATE TABLE raw_nats AS
SELECT *
FROM usapl
WHERE (MeetName = 'Raw Nationals' OR MeetName = 'Mega Nationals') AND Equipment = 'Raw';


-- 3.1
-- Number of Raw Nationals each person has won
-- A lifter can place 1st in several divisions (e.g. Open and Masters) at the same meet, so we
-- count distinct meets rather than first-place rows.
SELECT
    Name,
    Sex,
    COUNT(DISTINCT Date || MeetName) AS national_titles
FROM raw_nats
WHERE Place = '1'
GROUP BY Name, Sex
ORDER BY Sex, national_titles DESC;



-- 3.2 - 3.4
-- Going 9/9 (all nine attempts good) for winners vs everyone else.
-- Missed attempts are stored as negative weights. A blank (NULL) attempt means the meet didn't
-- record it, not that it was missed, so we only use entries with all nine attempts recorded.
-- (Earlier versions of 3.3 and 3.4 didn't match their descriptions: 3.3 required all nine
-- attempts to be good while describing lifters who did NOT go 9/9, and 3.4 had no attempt
-- condition at all, so it counted every winner.)
SELECT
    CASE WHEN Place = '1' THEN 'Winners' ELSE 'Everyone else' END AS grp,
    COUNT(*) AS entries,
    SUM(CASE WHEN Squat1Kg > 0 AND Squat2Kg > 0 AND Squat3Kg > 0
              AND Bench1Kg > 0 AND Bench2Kg > 0 AND Bench3Kg > 0
              AND Deadlift1Kg > 0 AND Deadlift2Kg > 0 AND Deadlift3Kg > 0
             THEN 1 ELSE 0 END) AS went_9_for_9,
    SUM(CASE WHEN Squat1Kg > 0 AND Squat2Kg > 0 AND Squat3Kg > 0
              AND Bench1Kg > 0 AND Bench2Kg > 0 AND Bench3Kg > 0
              AND Deadlift1Kg > 0 AND Deadlift2Kg > 0 AND Deadlift3Kg > 0
             THEN 0 ELSE 1 END) AS missed_at_least_one
FROM raw_nats
WHERE Event = 'SBD'
  AND Squat1Kg IS NOT NULL AND Squat2Kg IS NOT NULL AND Squat3Kg IS NOT NULL
  AND Bench1Kg IS NOT NULL AND Bench2Kg IS NOT NULL AND Bench3Kg IS NOT NULL
  AND Deadlift1Kg IS NOT NULL AND Deadlift2Kg IS NOT NULL AND Deadlift3Kg IS NOT NULL
GROUP BY grp;
-- 3.2 = Winners / went_9_for_9, 3.3 = Everyone else / missed_at_least_one,
-- 3.4 = Winners / missed_at_least_one




-- 3.5
-- The improvement in both total and dots for raw national lifters from their first national competition to their latest
-- Full-power (SBD) entries only: raw_nats also contains bench-only events, and a bench-only
-- "total" at a first meet followed by a full-power total later looked like a huge improvement.
-- Ranked by DOTS gain, which adjusts for bodyweight.
WITH sbd AS (
    SELECT Name, Date, TotalKg, Dots,
           ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Date, TotalKg DESC)      AS first_rank,
           ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Date DESC, TotalKg DESC) AS last_rank
    FROM raw_nats
    WHERE Event = 'SBD' AND TotalKg IS NOT NULL AND Dots IS NOT NULL
),
meet_counts AS (
    SELECT Name, COUNT(DISTINCT Date) AS meets FROM sbd GROUP BY Name
)
SELECT
    f.Name,
    f.Date AS first_date,
    l.Date AS latest_date,
    f.TotalKg AS first_total,
    l.TotalKg AS latest_total,
    l.TotalKg - f.TotalKg AS total_gain_kg,
    ROUND(l.Dots - f.Dots, 2) AS dots_gain
FROM sbd f
JOIN sbd l ON l.Name = f.Name AND l.last_rank = 1
JOIN meet_counts m ON m.Name = f.Name
WHERE f.first_rank = 1 AND m.meets >= 2
ORDER BY dots_gain DESC;









--Let's compare raw Bench-only lifters with SBD lifters

--First we create a new table from openpowerlifting consisting only lifters that have competed in Bench only events
CREATE TABLE bench_only AS
SELECT *,
       CAST(Best3BenchKg AS DECIMAL) AS best_bench
FROM openpowerlifting
WHERE event = 'B' AND Federation = 'IPF' AND Equipment = 'Raw';

--Find the max Bench for each weightclass and sex
SELECT
    Sex,
    WeightClassKg,
    MAX(best_bench) as max_bench_kg
FROM bench_only
GROUP BY sex, weightclassKg
ORDER BY Sex, WeightClassKg ASC, max_bench_kg DESC;


SELECT
    name
FROM bench_only
WHERE Sex = 'M' AND WeightClassKg = '125+' AND Best3BenchKg = 320;

SELECT *
FROM bench_only
WHERE Name = 'James Henderson #1';