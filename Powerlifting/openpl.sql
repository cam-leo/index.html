
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
--		2.10 Competition vs In-training Gym performance
--		2.11 Recovery time impact on performance
--		2.12 Lift ratio over time
-- 3. Creating Raw Nationals Data
--		3.1 Number of times a person has won nationals
--		3.2 Number of lifters that got 1st place and went 9/9
--		3.3 Number of lifters that didn't get 1st place and did NOT go 9/9
--		3.4 Number of lifters that got 1st place and did NOT go 9/9
--		3.5 Improvement in total/DOTS for national lifters from 1st comp to latest




-- 1.1 The number of lifters registered on openPL
SELECT
    COUNT(name)
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
--As we can see, this cut down the number of lifters from 1423354 to 757527, we will use this as our main data source

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














--Training Data of each lifter in the USAPL


-- 2.8
--Finding the age at which each lifter hit their peak performance in each lift (S,B,D)


--Postgres Version

WITH peak_performance AS (
    SELECT
        LifterID,
        'Squat' AS LiftType,
        MAX(Squat) AS PeakLift,
        DATE_PART('year', AGE(TrainingDate, 'DateOfBirth')) AS AgeAtPeak
    FROM training_data
    GROUP BY LifterID

    UNION ALL

    SELECT
        LifterID,
        'BenchPress' AS LiftType,
        MAX(BenchPress) AS PeakLift,
        DATE_PART('year', AGE(TrainingDate, 'DateOfBirth')) AS AgeAtPeak
    FROM training_data
    GROUP BY LifterID

    UNION ALL

    SELECT
        LifterID,
        'Deadlift' AS LiftType,
        MAX(Deadlift) AS PeakLift,
        DATE_PART('year', AGE(TrainingDate, 'DateOfBirth')) AS AgeAtPeak
    FROM training_data
    GROUP BY LifterID
)

SELECT
    LifterID,
    LiftType,
    PeakLift,
    AgeAtPeak
FROM peak_performance
ORDER BY LifterID, LiftType;


--SQlite version

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
--Calculating the effectiveness of each training program for each lifter

WITH program_gains AS (
    SELECT
        LifterID,
        Program,
        MAX(Squat) - MIN(Squat) AS SquatGain,
        MAX(BenchPress) - MIN(BenchPress) AS BenchGain,
        MAX(Deadlift) - MIN(Deadlift) AS DeadliftGain
    FROM training_data
    GROUP BY LifterID, Program
)

SELECT
    Program,
    AVG(SquatGain) AS AvgSquatGain,
    AVG(BenchGain) AS AvgBenchGain,
    AVG(DeadliftGain) AS AvgDeadliftGain
FROM program_gains
GROUP BY Program;




-- Calculate the gym PRs from training_data
CREATE TEMPORARY TABLE gym_prs AS
SELECT
    LifterID,
    MAX(Squat) AS GymSquatPR,
    MAX(BenchPress) AS GymBenchPR,
    MAX(Deadlift) AS GymDeadliftPR
FROM training_data
GROUP BY LifterID;

-- Join gym_prs with usapl to compare with competition PRs
SELECT
    t.LifterID,
    t.GymSquatPR,
    u.Best3SquatKg AS CompetitionSquatPR,
    t.GymBenchPR,
    u.Best3BenchKg AS CompetitionBenchPR,
    t.GymDeadliftPR,
    u.Best3DeadliftKg AS CompetitionDeadliftPR,
    (t.GymSquatPR - u.Best3SquatKg) AS SquatPRDifference,
    (t.GymBenchPR - u.Best3BenchKg) AS BenchPRDifference,
    (t.GymDeadliftPR - u.Best3DeadliftKg) AS DeadliftPRDifference
FROM gym_prs t
JOIN usapl u ON t.LifterID = u.Name
ORDER BY t.LifterID;






-- 2.10
CREATE VIEW lifter_prs_before_comp AS
SELECT
    t.lifterid,
    u.date AS competition_date,
    MAX(t.squat) AS pr_squat,
    MAX(t.benchpress) AS pr_bench,
    MAX(t.deadlift) AS pr_deadlift
FROM
    training_data t
JOIN
    usapl u ON t.lifterid = u.name
WHERE
    t.trainingdate < u.date
GROUP BY
    t.lifterid, u.date
ORDER BY t.LifterID ASC, u.Date ASC;

CREATE VIEW competition_prs AS
SELECT
    name AS lifterid,
    date AS competition_date,
    best3squatkg AS comp_pr_squat,
    best3benchkg AS comp_pr_bench,
    best3deadliftkg AS comp_pr_deadlift
FROM
    usapl
ORDER BY lifterid ASC, competition_date ASC;

CREATE VIEW improvements AS
SELECT
    b.lifterid,
    b.competition_date,
    b.pr_squat,
    c.comp_pr_squat,
    c.comp_pr_squat - b.pr_squat AS squat_improvement,
    b.pr_bench,
    c.comp_pr_bench,
    c.comp_pr_bench - b.pr_bench AS bench_improvement,
    b.pr_deadlift,
    c.comp_pr_deadlift,
    c.comp_pr_deadlift - b.pr_deadlift AS deadlift_improvement
FROM
    lifter_prs_before_comp b
JOIN
    competition_prs c ON b.lifterid = c.lifterid AND b.competition_date = c.competition_date
ORDER BY b.lifterid, b.competition_date;

SELECT
    i.lifterid,
    i.competition_date,
    i.pr_squat,
    i.comp_pr_squat,
    i.squat_improvement,
    i.pr_bench,
    i.comp_pr_bench,
    i.bench_improvement,
    i.pr_deadlift,
    i.comp_pr_deadlift,
    i.deadlift_improvement
FROM
    improvements i
ORDER BY
    i.lifterid, i.competition_date;



--future

CREATE VIEW future_competitions AS
SELECT
    t.lifterid,
    u.date AS competition_date,
    MAX(t.squat) AS pr_squat,
    MAX(t.benchpress) AS pr_bench,
    MAX(t.deadlift) AS pr_deadlift
FROM
    training_data t
JOIN
    usapl u ON t.lifterid = u.name
WHERE
    t.trainingdate < u.date
GROUP BY
    t.lifterid, u.date
HAVING
    u.date > (
        SELECT MAX(u2.date)
        FROM usapl u2
        WHERE u2.name = u.name
    );

SELECT
    i.lifterid,
    i.competition_date,
    i.pr_squat,
    i.comp_pr_squat,
    i.squat_improvement,
    i.pr_bench,
    i.comp_pr_bench,
    i.bench_improvement,
    i.pr_deadlift,
    i.comp_pr_deadlift,
    i.deadlift_improvement
FROM
    improvements i
JOIN
    future_competitions f ON i.lifterid = f.lifterid AND i.competition_date = f.competition_date
ORDER BY
    i.lifterid, i.competition_date;













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
-- Number of times each person has won Raw Nats
SELECT
    Name,
    Sex,
    Count(Name) AS num_times_won
FROM raw_nats
WHERE place = 1
GROUP BY Name, Sex
ORDER BY Sex, num_times_won DESC;



-- 3.2
-- Number of lifters that got 1st place and went 9/9
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



-- 3.3
-- Number of lifters that did NOT get 1st place and did NOT go 9/9
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



-- 3.4
-- Number of lifters that got 1st place and did NOT go 9/9
SELECT COUNT(name)
FROM usapl
WHERE
    Event = 'SBD' AND
    Equipment = 'Raw' AND
    Place = 1 AND
    (MeetName = 'Raw Nationals' OR MeetName = 'Mega Nationals');




-- 3.5
-- The improvement in both total and dots for raw national lifters from their first national competition to their latest
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