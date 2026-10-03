# Powerlifting Data Analysis

SQL analysis of powerlifting competition results from [OpenPowerlifting](https://www.openpowerlifting.org/), focused on the USAPL federation and its Raw Nationals, presented in a Streamlit app.

## Data

**Competition results.** The OpenPowerlifting export from 2024-01-06 (`openpowerlifting-2024-01-06-4c732975.csv`) is too large for GitHub. Download it from [Kaggle](https://www.kaggle.com/datasets/open-powerlifting/powerlifting-database/data?select=openpowerlifting-2024-01-06-4c732975.csv). Each row is one *entry*: one lifter at one meet in one division. A lifter usually has many entries.

**Training log (synthetic).** `training_data.csv` is randomly generated practice data. Weekly lifts are drawn independently, programs are assigned at random, and lifters are anonymous IDs (`Lifter 01` to `Lifter 17`). It is useful for practising SQL (window functions, date arithmetic) and for showing how to test for an effect, but it contains no real training information.

## How to Run

```bash
pip install -r requirements.txt
python build_db.py path/to/openpowerlifting-2024-01-06-4c732975.csv   # creates powerlifting.sqlite
streamlit run openpl.py
```

`build_db.py` loads the CSV into SQLite and creates the tables the queries use:

| Table | Contents |
|---|---|
| `openpowerlifting` | every entry |
| `data` | entries with age, sex, age class and birth-year class recorded |
| `usapl` | USAPL entries from `data` |
| `raw_nats` | USAPL Raw Nationals / Mega Nationals entries, raw equipment |
| `training_data` | the synthetic training log |

## Files

- **openpl.sql**: the full set of SQL queries, with notes on each result.
- **openpl.py**: the Streamlit app.
- **build_db.py**: builds the SQLite database.
- **training_data.csv**: the synthetic training log.
- **2024-06-24T21-3x_export.csv**: saved results from the app (see below).

## What the App Shows

### Overview
Competition entries, distinct lifters and distinct USAPL lifters. Entries and lifters are reported separately: counting rows counts entries, which is several times the number of people.

[Entries in the full dataset](2024-06-24T21-35_export.csv) · [USAPL lifters](2024-06-24T21-38_export.csv)

### USAPL lifters by sex and weight class
Distinct lifters per weight class and sex. Weight classes are kept as text so super-heavyweight classes such as `120+` aren't merged into `120`.

### Age range
Youngest and oldest ages recorded ([saved result](2024-06-24T21-37_export.csv)).

### Raw Nationals
- **Most titles:** top 5 per sex, counting distinct meets won. A lifter who wins two divisions at the same meet counts once.
- **Going 9/9:** how often winners and everyone else make all nine attempts, with a chi-squared test. Only entries with all nine attempts recorded are used, because a blank attempt means "not recorded", not "missed".
- **Biggest improvements:** first vs latest Raw Nationals full-power (SBD) result for lifters with at least two, ranked by DOTS gain. DOTS adjusts for bodyweight.

### Training log (synthetic)
- **Programs:** average weekly lifts per program, with an ANOVA per lift adjusted for testing three lifts. Since the data are random, no real program effect is expected.
- **Days between sessions vs squat:** scatter plot and Spearman correlation.

## Notes on Earlier Versions

These issues were fixed:

- "Total lifters" counted entries (`SELECT DISTINCT COUNT(name)` applies `DISTINCT` to the result, not to names).
- The weight-class chart counted entries and merged super-heavyweight classes into the class below.
- "Top Raw Nationals winners" only showed women (sorted by sex, then cut to 10 rows) and counted division wins rather than meets.
- The 9/9 comparison treated unrecorded attempts as misses, and the SQL for 3.3 and 3.4 didn't match their descriptions.
- "Performance improvement" mixed bench-only and full-power totals.
- "Program effectiveness" measured max minus min, which isn't progress.
- "Gym PRs vs competition PRs" compared the random training log with real competition results under real athletes' names. It has been removed, and the training log now uses anonymous IDs.

The saved results for winners, improvements, programs and gym vs competition came from the earlier queries, so they were removed. Run the app and use the download button on any table to save new ones.
