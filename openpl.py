import streamlit as st
import sqlite3
import pandas as pd
import altair as alt

# Function to fetch data from SQLite database
def fetch_data(query):
    conn = sqlite3.connect('identifier.sqlite')
    df = pd.read_sql_query(query, conn)
    conn.close()
    return df

# Function to display total lifters
def display_total_lifters():
    query = "SELECT DISTINCT COUNT(name) AS TotalLifters FROM openpowerlifting;"
    df = fetch_data(query)
    st.subheader('Total Lifters')
    st.write(df)

# Displaying gender disparity of the lifters
def gender_disparity():
    query = "SELECT COUNT (DISTINCT Name), Sex  FROM usapl GROUP BY sex;"
    df = fetch_data(query)
    st.subheader('Gender Disparity')
    st.write(df)


# Displaying count of usapl members

def display_usapl_members():
    query = "SELECT COUNT(DISTINCT Name) AS USAPL_Members FROM usapl;"
    df = fetch_data(query)
    st.subheader('USAPL Members')
    st.write(df)

# Displaying multi bar graph of weight class and gender disparity
def weight_and_gender_disparity():
    query = """
    SELECT
        WeightClassKg,
        SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN Sex = 'Mx' THEN 1 ELSE 0 END) AS mx_count
    FROM usapl
    GROUP BY
        WeightClassKg
    ORDER BY WeightClassKg
    """
    df = fetch_data(query)
    df_melted = df.melt(id_vars=['WeightClassKg'],
                        var_name='Sex',
                        value_name='count')

    chart = alt.Chart(df_melted).mark_bar().encode(
        x=alt.X('WeightClassKg:N', title='Weight Class (kg)'),
        y=alt.Y('count:Q', title='Number of Lifters'),
        color=alt.Color('Sex:N', scale=alt.Scale(domain=['male_count', 'female_count', 'mx_count'],
                                                 range=['#1f77b4', '#ff7f0e', '#2ca02c'])),
        xOffset='Sex:N'
    ).properties(
        title='Powerlifters by Weight Class and Gender',
        width=600,
        height=400
    )


    st.altair_chart(chart, use_container_width=True)



# Function to display youngest and oldest lifters
def display_age_range():
    query = "SELECT MIN(age) AS YoungestAge, MAX(age) AS OldestAge FROM openpowerlifting WHERE age IS NOT NULL AND sex IS NOT NULL AND ageclass IS NOT NULL AND birthyearclass IS NOT NULL;"
    df = fetch_data(query)
    st.subheader('Youngest and Oldest Lifters')
    st.write(df)

# Function to display USAPL members
def display_usapl_members():
    query = "SELECT COUNT(DISTINCT Name) AS USAPL_Members FROM usapl;"
    df = fetch_data(query)
    st.subheader('USAPL Members')
    st.write(df)

def display_raw_nationals_winners():
    query = """
    SELECT
        Name,
        Sex,
        Count(Name) AS num_times_won
    FROM raw_nats
    WHERE place = 1
    GROUP BY Name, Sex
    ORDER BY Sex, num_times_won DESC
    LIMIT 10;
    """
    df = fetch_data(query)
    st.subheader('Top Raw Nationals Winners')
    st.write(df)



# Function to display performance improvement for Raw Nationals lifters
def display_performance_improvement():
    query = """
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
        performance_improvement DESC, dots_improvement DESC
    LIMIT 10;
    """
    df = fetch_data(query)
    st.subheader('Top Performance Improvements in Raw Nationals')
    st.write(df)





# Function to display effectiveness of training programs
def display_program_effectiveness():
    query = """
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
    """
    df = fetch_data(query)
    st.subheader('Effectiveness of Training Programs')
    st.write(df)

    # Visualization
    chart = alt.Chart(df.melt('Program', var_name='Lift', value_name='Average Gain')).mark_bar().encode(
        x='Program',
        y='Average Gain',
        color='Lift',
        column='Lift'
    ).properties(
        width=200,
        title='Average Gains by Training Program and Lift Type'
    )
    st.altair_chart(chart, use_container_width=True)

# Function to display gym vs competition PRs
def display_gym_vs_comp_prs():
    query = """
    WITH lifter_prs_before_comp AS (
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
    ),
    competition_prs AS (
        SELECT
            name AS lifterid,
            date AS competition_date,
            best3squatkg AS comp_pr_squat,
            best3benchkg AS comp_pr_bench,
            best3deadliftkg AS comp_pr_deadlift
        FROM
            usapl
    ),
    improvements AS (
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
    )
    SELECT
        lifterid,
        competition_date,
        pr_squat,
        comp_pr_squat,
        squat_improvement,
        pr_bench,
        comp_pr_bench,
        bench_improvement,
        pr_deadlift,
        comp_pr_deadlift,
        deadlift_improvement
    FROM
        improvements
    ORDER BY
        lifterid, competition_date
    LIMIT 1000;
    """
    df = fetch_data(query)
    st.subheader('Gym PRs vs Competition PRs')
    st.write(df.head())

    # Prepare data for visualization
    melted_df = pd.melt(df,
                        id_vars=['lifterid', 'competition_date'],
                        value_vars=['squat_improvement', 'bench_improvement', 'deadlift_improvement'],
                        var_name='lift_type',
                        value_name='improvement')

    # Create scatter plot
    scatter = alt.Chart(melted_df).mark_circle().encode(
        x=alt.X('competition_date:T', title='Competition Date'),
        y=alt.Y('improvement:Q', title='Improvement (kg)'),
        color=alt.Color('lift_type:N',
                        scale=alt.Scale(domain=['squat_improvement', 'bench_improvement', 'deadlift_improvement'],
                                        range=['#1f77b4', '#ff7f0e', '#2ca02c']),
                        legend=alt.Legend(title="Lift Type")),
        tooltip=['lifterid', 'competition_date', 'lift_type', 'improvement']
    ).properties(
        width=600,
        height=400,
        title='Improvement from Gym PR to Competition PR'
    )

    # Add a horizontal line at y=0
    hline = alt.Chart(pd.DataFrame({'y': [0]})).mark_rule().encode(y='y')

    # Combine scatter plot and horizontal line
    chart = (scatter + hline).interactive()

    st.altair_chart(chart, use_container_width=True)

    # Summary statistics
    st.subheader('Summary Statistics')
    summary = df[['squat_improvement', 'bench_improvement', 'deadlift_improvement']].describe()
    st.write(summary)

    # Distribution of improvements
    hist = alt.Chart(melted_df).mark_bar().encode(
        x=alt.X('improvement:Q', bin=alt.Bin(maxbins=30), title='Improvement (kg)'),
        y=alt.Y('count()', title='Frequency'),
        color=alt.Color('lift_type:N',
                        scale=alt.Scale(domain=['squat_improvement', 'bench_improvement', 'deadlift_improvement'],
                                        range=['#1f77b4', '#ff7f0e', '#2ca02c']),
                        legend=alt.Legend(title="Lift Type"))
    ).properties(
        width=600,
        height=300,
        title='Distribution of Improvements'
    )

    st.altair_chart(hist, use_container_width=True)



# Function to display recovery time impact on performance
def display_recovery_impact():
    query = """
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
    ORDER BY LifterID, TrainingDate
    LIMIT 1000;
    """
    df = fetch_data(query)
    st.subheader('Recovery Time Impact on Performance')
    st.write(df.head())

    # Visualization
    chart = alt.Chart(df).mark_point().encode(
        x='RecoveryDays',
        y=alt.Y('Squat', title='Lift Weight'),
        color=alt.Color('LifterID:N', legend=None)
    ).properties(
        width=600,
        height=400,
        title='Recovery Days vs Squat Performance'
    )
    st.altair_chart(chart, use_container_width=True)

# Function to display Raw Nationals statistics
def display_raw_nationals_stats():
    query1 = """
    SELECT COUNT(name) AS count_9_for_9_winners
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
    """
    df1 = fetch_data(query1)

    query2 = """
    SELECT COUNT(name) AS count_not_9_for_9_not_winners
    FROM usapl
    WHERE
        (Squat1Kg IS NULL OR Squat1Kg <= 0 OR
        Squat2Kg IS NULL OR Squat2Kg <= 0 OR
        Squat3Kg IS NULL OR Squat3Kg <= 0 OR
        Bench1Kg IS NULL OR Bench1Kg <= 0 OR
        Bench2Kg IS NULL OR Bench2Kg <= 0 OR
        Bench3Kg IS NULL OR Bench3Kg <= 0 OR
        Deadlift1Kg IS NULL OR Deadlift1Kg <= 0 OR
        Deadlift2Kg IS NULL OR Deadlift2Kg <= 0 OR
        Deadlift3Kg IS NULL OR Deadlift3Kg <= 0) AND
        Event = 'SBD' AND
        Equipment = 'Raw' AND
        Place != 1 AND
        (MeetName = 'Raw Nationals' OR MeetName = 'Mega Nationals');
    """
    df2 = fetch_data(query2)

    st.subheader('Raw Nationals Statistics')
    col1, col2 = st.columns(2)
    col1.metric("Winners with 9/9 Lifts", df1['count_9_for_9_winners'][0])
    col2.metric("Non-Winners without 9/9 Lifts", df2['count_not_9_for_9_not_winners'][0])








# Streamlit app layout
st.title('Powerlifting Data Analysis')




# Display total lifters
display_total_lifters()


weight_and_gender_disparity()

# Display youngest and oldest lifters
display_age_range()

# Display USAPL members
display_usapl_members()

display_total_lifters()
display_usapl_members()
gender_disparity()
weight_and_gender_disparity()
display_age_range()
display_raw_nationals_winners()
display_performance_improvement()
display_program_effectiveness()
display_gym_vs_comp_prs()
display_recovery_impact()
display_raw_nationals_stats()
display_gym_vs_comp_prs()