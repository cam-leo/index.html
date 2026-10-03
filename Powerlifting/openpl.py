"""
Powerlifting Data Analysis: Streamlit app.

Build the database first (see README):
    python build_db.py path/to/openpowerlifting-2024-01-06-4c732975.csv
then run:
    streamlit run openpl.py
"""
import sqlite3
from pathlib import Path

import altair as alt
import pandas as pd
import streamlit as st
from scipy import stats

DB_PATH = Path(__file__).parent / "powerlifting.sqlite"
LIFT_COLOURS = alt.Scale(domain=["Squat", "Bench", "Deadlift"], range=["#1f77b4", "#ff7f0e", "#2ca02c"])

# Raw Nationals entries where all nine attempts were recorded. Missed attempts are stored as
# negative weights; a blank attempt means the meet didn't record it, not that it was missed.
ALL_ATTEMPTS_RECORDED = " AND ".join(
    f"{lift}{n}Kg IS NOT NULL" for lift in ("Squat", "Bench", "Deadlift") for n in (1, 2, 3))
NINE_FOR_NINE = " AND ".join(
    f"{lift}{n}Kg > 0" for lift in ("Squat", "Bench", "Deadlift") for n in (1, 2, 3))


@st.cache_data
def fetch_data(query, params=()):
    with sqlite3.connect(DB_PATH) as conn:
        return pd.read_sql_query(query, conn, params=params)


# ---------------------------------------------------------------------------
# Overview
# ---------------------------------------------------------------------------
def display_overview():
    df = fetch_data("""
        SELECT
            (SELECT COUNT(*)             FROM openpowerlifting) AS entries,
            (SELECT COUNT(DISTINCT Name) FROM openpowerlifting) AS lifters,
            (SELECT COUNT(DISTINCT Name) FROM usapl)            AS usapl_lifters
    """)
    st.subheader("Overview")
    c1, c2, c3 = st.columns(3)
    # One lifter usually has many entries (one per meet and division), so entries != lifters.
    c1.metric("Competition entries (OpenPowerlifting)", f"{df.entries[0]:,}")
    c2.metric("Distinct lifters (OpenPowerlifting)", f"{df.lifters[0]:,}")
    c3.metric("Distinct USAPL lifters", f"{df.usapl_lifters[0]:,}")
    st.caption("USAPL figures only include entries with age, sex, age class and birth-year class "
               "recorded (the `data` table), so they understate the federation's full membership.")


def display_gender_breakdown():
    df = fetch_data("""
        SELECT Sex, COUNT(DISTINCT Name) AS lifters
        FROM usapl
        GROUP BY Sex
        ORDER BY lifters DESC
    """)
    st.subheader("USAPL Lifters by Sex")
    st.dataframe(df, hide_index=True)


def display_weight_class_breakdown():
    # Weight classes stay as text so "120+" (super-heavyweight) isn't merged into "120".
    df = fetch_data("""
        SELECT WeightClassKg, Sex, COUNT(DISTINCT Name) AS lifters
        FROM usapl
        WHERE WeightClassKg IS NOT NULL
        GROUP BY WeightClassKg, Sex
    """)
    order = sorted(df.WeightClassKg.unique(), key=lambda w: (float(w.rstrip("+")), w.endswith("+")))
    chart = alt.Chart(df).mark_bar().encode(
        x=alt.X("WeightClassKg:N", sort=order, title="Weight class (kg)"),
        y=alt.Y("lifters:Q", title="Distinct lifters"),
        color=alt.Color("Sex:N", scale=alt.Scale(domain=["M", "F", "Mx"], range=["#1f77b4", "#ff7f0e", "#2ca02c"])),
        xOffset="Sex:N",
        tooltip=["WeightClassKg", "Sex", "lifters"],
    ).properties(title="USAPL Lifters by Weight Class and Sex", height=400)
    st.subheader("Weight Classes")
    st.altair_chart(chart, width="stretch")
    st.caption("A lifter who competed in several weight classes is counted once in each. "
               "Classes changed over the years (e.g. 82.5 kg before 2011, 83 kg after), so old and new classes both appear.")


def display_age_range():
    df = fetch_data("SELECT MIN(Age) AS youngest, MAX(Age) AS oldest FROM data")
    st.subheader("Youngest and Oldest Lifters")
    st.dataframe(df, hide_index=True)


# ---------------------------------------------------------------------------
# Raw Nationals
# ---------------------------------------------------------------------------
def display_raw_nationals_winners():
    # Count national titles as distinct meets won: one lifter can place 1st in several
    # divisions (e.g. Open and Masters) at the same meet. Show the top 5 for each sex;
    # sorting by sex and then taking 10 rows only ever showed women.
    df = fetch_data("""
        WITH titles AS (
            SELECT Name, Sex, COUNT(DISTINCT Date || MeetName) AS national_titles
            FROM raw_nats
            WHERE Place = '1'
            GROUP BY Name, Sex
        ),
        ranked AS (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY Sex ORDER BY national_titles DESC, Name) AS rank_in_sex
            FROM titles
        )
        SELECT Sex, Name, national_titles
        FROM ranked
        WHERE rank_in_sex <= 5
        ORDER BY Sex, national_titles DESC
    """)
    st.subheader("Most Raw Nationals Titles (top 5 per sex)")
    st.dataframe(df, hide_index=True)


def display_nine_for_nine():
    # Compare how often winners and non-winners go 9/9, using only entries where all nine
    # attempts were recorded. Treating unrecorded attempts as misses would be wrong.
    df = fetch_data(f"""
        SELECT
            CASE WHEN Place = '1' THEN 'Winners' ELSE 'Everyone else' END AS grp,
            COUNT(*) AS entries,
            SUM(CASE WHEN {NINE_FOR_NINE} THEN 1 ELSE 0 END) AS went_9_for_9
        FROM raw_nats
        WHERE Event = 'SBD' AND {ALL_ATTEMPTS_RECORDED}
        GROUP BY grp
    """)
    df["share_9_for_9"] = (df.went_9_for_9 / df.entries).round(3)
    st.subheader("Do Winners Go 9/9 More Often?")
    st.dataframe(df.rename(columns={"grp": "group"}), hide_index=True)
    if len(df) == 2:
        table = df[["went_9_for_9"]].assign(missed=df.entries - df.went_9_for_9).to_numpy()
        chi2, p, _, _ = stats.chi2_contingency(table)
        st.caption(f"Chi-squared test of independence: p = {p:.3g}. "
                   "Raw Nationals full-power (SBD) entries with all nine attempts recorded.")


def display_performance_improvement():
    # First vs latest Raw Nationals full-power (SBD) result for lifters with at least two.
    # Without the SBD filter, a bench-only total at a first meet looked like a huge
    # "improvement" when the lifter later did all three lifts.
    df = fetch_data("""
        WITH sbd AS (
            SELECT Name, Date, TotalKg, Dots,
                   ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Date, TotalKg DESC) AS first_rank,
                   ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Date DESC, TotalKg DESC) AS last_rank
            FROM raw_nats
            WHERE Event = 'SBD' AND TotalKg IS NOT NULL AND Dots IS NOT NULL
        ),
        meet_counts AS (
            SELECT Name, COUNT(DISTINCT Date) AS meets FROM sbd GROUP BY Name
        ),
        paired AS (
            SELECT f.Name,
                   f.Date AS first_date, l.Date AS latest_date,
                   f.TotalKg AS first_total, l.TotalKg AS latest_total,
                   f.Dots AS first_dots, l.Dots AS latest_dots
            FROM sbd f
            JOIN sbd l ON l.Name = f.Name AND l.last_rank = 1
            JOIN meet_counts m ON m.Name = f.Name
            WHERE f.first_rank = 1 AND m.meets >= 2
        )
        SELECT Name, first_date, latest_date, first_total, latest_total,
               latest_total - first_total AS total_gain_kg,
               ROUND(latest_dots - first_dots, 2) AS dots_gain
        FROM paired
        ORDER BY dots_gain DESC
        LIMIT 10
    """)
    st.subheader("Biggest Improvements Between Raw Nationals (full power)")
    st.dataframe(df, hide_index=True)
    st.caption("Ranked by DOTS gain, which adjusts for bodyweight, so moving up a weight class "
               "doesn't count as improvement on its own. Lifters with at least two Raw Nationals.")


# ---------------------------------------------------------------------------
# Training data (synthetic)
# ---------------------------------------------------------------------------
SYNTHETIC_NOTE = ("**Note:** `training_data.csv` is randomly generated for practice. Lifts are drawn "
                  "independently each week and programs are assigned at random, so no real "
                  "training effect can be found in it. The sections below show how to test for one.")


def display_program_comparison():
    df = fetch_data("SELECT Program, Squat, BenchPress AS Bench, Deadlift FROM training_data")
    st.subheader("Training Programs (synthetic data)")
    st.markdown(SYNTHETIC_NOTE)

    long = df.melt("Program", var_name="Lift", value_name="kg")
    means = long.groupby(["Program", "Lift"], as_index=False).kg.mean().round(1)
    chart = alt.Chart(means).mark_bar().encode(
        x=alt.X("Program:N", title=None),
        y=alt.Y("kg:Q", title="Average weekly lift (kg)"),
        color=alt.Color("Lift:N", scale=LIFT_COLOURS),
        column=alt.Column("Lift:N", sort=["Squat", "Bench", "Deadlift"], title=None),
    ).properties(width=180, height=300)
    st.altair_chart(chart)

    # One-way ANOVA per lift: does the average differ by program more than chance would explain?
    # Three lifts means three tests, so p-values are Bonferroni-adjusted (x3): with pure noise,
    # at least one of three unadjusted p-values falls below 0.05 about 12% of the time.
    rows = []
    for lift in ["Squat", "Bench", "Deadlift"]:
        groups = [g[lift].to_numpy() for _, g in df.groupby("Program")]
        f, p = stats.f_oneway(*groups)
        rows.append({"Lift": lift, "F statistic": round(f, 2), "p-value": round(p, 3),
                     "adjusted p (x3 tests)": round(min(1.0, 3 * p), 3)})
    results = pd.DataFrame(rows)
    st.dataframe(results, hide_index=True)
    n_sig = int((results["adjusted p (x3 tests)"] < 0.05).sum())
    st.caption(f"{n_sig} of 3 lifts show a significant difference between programs after adjusting for "
               "testing three lifts. Because the data are random by construction, any borderline result "
               "here is chance, which is why a single borderline test isn't evidence that a program works. "
               "An earlier version measured 'gain' as max minus min, which grows with noise and the number "
               "of weeks, not with progress.")


def display_recovery_impact():
    df = fetch_data("""
        SELECT LifterID, TrainingDate, Squat,
               JULIANDAY(TrainingDate)
                 - JULIANDAY(LAG(TrainingDate) OVER (PARTITION BY LifterID ORDER BY TrainingDate)) AS RecoveryDays
        FROM training_data
    """).dropna()
    r, p = stats.spearmanr(df.RecoveryDays, df.Squat)
    st.subheader("Days Between Sessions vs Squat (synthetic data)")
    chart = alt.Chart(df).mark_circle(opacity=0.4).encode(
        x=alt.X("RecoveryDays:Q", title="Days since previous session"),
        y=alt.Y("Squat:Q", title="Squat (kg)"),
        tooltip=["LifterID", "TrainingDate", "RecoveryDays", "Squat"],
    ).properties(height=350)
    st.altair_chart(chart, width="stretch")
    st.caption(f"Spearman correlation = {r:.2f} (p = {p:.2f}). Sessions are mostly a week apart, "
               "so there is little variation in recovery time to learn from.")


# ---------------------------------------------------------------------------
# App layout
# ---------------------------------------------------------------------------
st.set_page_config(page_title="Powerlifting Data Analysis", layout="wide")
st.title("Powerlifting Data Analysis")

if not DB_PATH.exists():
    st.error("powerlifting.sqlite not found. Run `python build_db.py <openpowerlifting csv>` first.")
    st.stop()

display_overview()
display_gender_breakdown()
display_weight_class_breakdown()
display_age_range()

st.header("USAPL Raw Nationals")
display_raw_nationals_winners()
display_nine_for_nine()
display_performance_improvement()

st.header("Training Log")
display_program_comparison()
display_recovery_impact()
