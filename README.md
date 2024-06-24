[2024-06-24T21-37_export.csv](https://github.com/user-attachments/files/15961614/2024-06-24T21-37_export.csv)[2024-06-24T21-35_export.csv](https://github.com/user-attachments/files/15961603/2024-06-24T21-35_export.csv)# LeoCam
# Powerlifting Data Analysis

This repository contains data and SQL queries for analyzing powerlifting competition results.

## Data File (Large)

Due to size limitations on GitHub, the `openpowerlifting-20204-01-06-4c732975.csv` file is hosted externally.

### Download Instructions

To access the powerlifting data, please download it from https://www.kaggle.com/datasets/open-powerlifting/powerlifting-database/data?select=openpowerlifting-2024-01-06-4c732975.csv.
The training_data csv is provided.

## Files Included

- **openpl.sql**: SQL queries for analyzing the powerlifting data.

## Overview

The `powerlifting_data.csv` file includes detailed information about powerlifting competition results, including lift types, weights lifted, and competition details. The `powerlifting_analysis.sql` file provides SQL queries to analyze this dataset, such as aggregating results, calculating averages, and filtering data based on various criteria.

## How to Use

1. **CSV File**: Download or clone the `openpowerlifting.csv` file to access the raw data.
   
2. **SQL Queries**: Use the `openpl.sql` file to run SQL queries against the CSV data to derive insights and perform analysis tasks.

## Example SQL Queries

```sql
-- Example: Calculate average squat weight lifted by male lifters
SELECT
    AVG(Squat_Weight) AS Avg_Squat_Weight
FROM
    powerlifting_data
WHERE
    Sex = 'M';
```

# Powerlifting Data Analysis

This project analyzes powerlifting competition data using SQL queries and visualizes the results using Streamlit.

## Functions and Their Outputs

### 1. display_total_lifters()
**Purpose:** Displays the total number of lifters in the database.
**Output:** A single number representing the total count of lifters.

[View CSV data](2024-06-24T21-35_export.csv)


### 3. weight_and_gender_disparity()
**Purpose:** Visualizes the distribution of lifters across weight classes and genders.
**Output:** A multi-bar graph showing the count of male, female, and mx lifters for each weight class.

![visualization](https://github.com/cam-leo/Powerlifting/assets/172936155/eb6dfaba-be44-44b1-8ed0-ba001f177fd8)


### 4. display_age_range()
**Purpose:** Shows the age range of lifters in the database.
**Output:** A table with the youngest and oldest ages recorded.

[View CSV data](2024-06-24T21-37_export.csv)


### 5. display_usapl_members()
**Purpose:** Displays the number of USAPL members.
**Output:** A single number representing the count of USAPL members.

[View CSV data](2024-06-24T21-38_export.csv)

### 6. display_raw_nationals_winners()
**Purpose:** Lists the top winners of Raw Nationals competitions.
**Output:** A table showing the names, gender, and number of wins for top performers.

[View CSV data](2024-06-24T21-39_export.csv)

### 7. display_performance_improvement()
**Purpose:** Shows the lifters with the most significant improvements in their performance.
**Output:** A table listing lifters, their first and latest competition dates, totals, and improvements in both total weight and DOTS score.

[View CSV data](2024-06-24T21-40_export.csv)

### 8. display_program_effectiveness()
**Purpose:** Analyzes the effectiveness of different training programs.
**Output:** A table and bar chart showing average gains for squat, bench press, and deadlift across different programs.

[View CSV data](2024-06-24T21-41_export.csv)

### 9. display_gym_vs_comp_prs()
**Purpose:** Compares gym personal records (PRs) with competition PRs.
**Output:** A scatter plot showing the relationship between recovery days and lift performance, and histograms showing the distribution of improvements.

[View CSV data](2024-06-24T21-42_export.csv)

