# LeoCam
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
