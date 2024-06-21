# LeoCam
# Powerlifting Data Analysis

This repository contains data and SQL queries for analyzing powerlifting competition results.

## Files Included

- **openpowerlifting.csv**: CSV file containing data on powerlifting competition results.
- **openpowerlifting-2024-01-06-4c732975.csv**: CSV file containing data on powerlifting competition results, more recently updated on January 6.
- **usapl.csv**: CSV file containing data only on members associated with USAPL federation.
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
