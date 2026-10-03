"""
Build powerlifting.sqlite, the database that openpl.py reads.

Usage:
    python build_db.py path/to/openpowerlifting-2024-01-06-4c732975.csv

Creates these tables:
    openpowerlifting  every competition entry (one row per lifter per meet per division)
    data              entries with age, sex, age class and birth-year class recorded
    usapl             the USAPL entries from `data`
    raw_nats          USAPL Raw Nationals / Mega Nationals entries, raw equipment
    training_data     the synthetic training log (training_data.csv)
"""
import sqlite3
import sys
from pathlib import Path

import pandas as pd

HERE = Path(__file__).parent
DB_PATH = HERE / "powerlifting.sqlite"

# Columns used by the analysis. Weight classes and places stay text:
# "120+" and "84+" are classes of their own, and places include "DQ", "G", etc.
TEXT_COLS = ["Name", "Sex", "Event", "Equipment", "AgeClass", "BirthYearClass", "Division",
             "WeightClassKg", "Place", "Tested", "Country", "State", "Federation",
             "ParentFederation", "Date", "MeetCountry", "MeetState", "MeetTown", "MeetName"]
NUM_COLS = ["Age", "BodyweightKg",
            "Squat1Kg", "Squat2Kg", "Squat3Kg", "Best3SquatKg",
            "Bench1Kg", "Bench2Kg", "Bench3Kg", "Best3BenchKg",
            "Deadlift1Kg", "Deadlift2Kg", "Deadlift3Kg", "Best3DeadliftKg",
            "TotalKg", "Dots", "Wilks"]


def load_openpowerlifting(csv_path, conn):
    header = pd.read_csv(csv_path, nrows=0).columns
    usecols = [c for c in TEXT_COLS + NUM_COLS if c in header]
    dtypes = {c: "string" for c in TEXT_COLS if c in header}
    first = True
    for chunk in pd.read_csv(csv_path, usecols=usecols, dtype=dtypes, chunksize=200_000, low_memory=False):
        for c in NUM_COLS:
            if c in chunk:
                chunk[c] = pd.to_numeric(chunk[c], errors="coerce")
        chunk.to_sql("openpowerlifting", conn, if_exists="replace" if first else "append", index=False)
        first = False


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    csv_path = Path(sys.argv[1])
    if DB_PATH.exists():
        DB_PATH.unlink()
    conn = sqlite3.connect(DB_PATH)

    print("Loading OpenPowerlifting CSV (this takes a few minutes)...")
    load_openpowerlifting(csv_path, conn)

    conn.executescript("""
        CREATE TABLE data AS
        SELECT * FROM openpowerlifting
        WHERE Age IS NOT NULL AND Sex IS NOT NULL AND AgeClass IS NOT NULL AND BirthYearClass IS NOT NULL;

        CREATE TABLE usapl AS
        SELECT * FROM data WHERE Federation = 'USAPL';

        CREATE TABLE raw_nats AS
        SELECT * FROM usapl
        WHERE MeetName IN ('Raw Nationals', 'Mega Nationals') AND Equipment = 'Raw';

        CREATE INDEX idx_usapl_name ON usapl(Name);
        CREATE INDEX idx_raw_nats_name ON raw_nats(Name, Date);
    """)

    print("Loading training_data.csv...")
    pd.read_csv(HERE / "training_data.csv").to_sql("training_data", conn, index=False)

    for table in ["openpowerlifting", "data", "usapl", "raw_nats", "training_data"]:
        n = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"  {table:17s} {n:>10,} rows")
    conn.close()
    print(f"Done: {DB_PATH}")


if __name__ == "__main__":
    main()
