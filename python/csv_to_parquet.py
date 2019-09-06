#!/usr/bin/env python3


import argparse
import linecache
import itertools
import io
from pyarrow import Table
import pandas as pd
from pyarrow.parquet import ParquetWriter


def parse_command_line():
    """
    Parse command line arguments. See the -h option.
    :param argv: arguments on the command line must include caller file name.
    """
    parser = argparse.ArgumentParser(
        description="""
        Convert a CSV file to parquet. May be larger than memory.

        Note that because pandas -> parquet cannot yet handle extentiontypes,
        numpy ints can't handle NA values, and we're not reading all the data
        in one go, all integers will be converted to floats until this issue is
        resolved: https://issues.apache.org/jira/browse/ARROW-5379
        """
    )
    parser.add_argument("input_csv")
    parser.add_argument("output_parquet")
    parser.add_argument(
        "--dtypes",
        help="""Specify CSV's data types. Overrides Pandas' type inference.
        Example:
        --dtypes "{'a': 'float64', 'b': 'Int64'}"
        """,
    )
    arguments = parser.parse_args()
    return arguments


def get_rows_to_skip(csv):
    """Figure out which rows to skip reading. For large CSVs this will be most of them.
    Return a list of rows to skip.

    Specifically, if `csv` has less than 20000 rows, the list will be empty.
    If more, the only rows read will be 100 batches of 100 rows spread throughout the CSV.
    We read the header (if present) and first 99-100 rows of data, the last 100 rows,
    and evenly spaced blocks between.
    (This strategy is borrowed from R's data.table::fread)
    """
    num_chunks = 100
    rows_per_chunk = 100
    row_count = get_row_count(csv)
    if row_count < 2 * (num_chunks * (rows_per_chunk + 1)):
        rows_to_skip = []
    else:
        # how many rows between the start of each chunk we're going to read?
        chunk_start_sep = round((row_count - 1) / (num_chunks - 1))
        # Where are the endpoints of the chunks we want to read?
        chunk_ends = range(rows_per_chunk - 1, row_count, chunk_start_sep)
        # Where are the start points of the chunks we want to read?
        chunk_starts = range(
            rows_per_chunk - 1 + chunk_start_sep, row_count, chunk_start_sep
        )
        # There's got to be a better way
        rows_to_skip = list(
            itertools.chain.from_iterable(
                range(chunk_end, chunk_start)
                for chunk_end, chunk_start in zip(chunk_ends, chunk_starts)
            )
        )
    return rows_to_skip


def get_csv_types(csv, dtypes=None):
    """Infer column types from `csv`

    Reads any type of file pd.read_csv can work with.
    """
    rows_to_skip = get_rows_to_skip(csv)
    sample_data = pd.read_csv(
        csv, dtype=dtypes, low_memory=False, skiprows=rows_to_skip
    )
    schema = Table.from_pandas(sample_data).schema

    dtypes = dict(make_dtypes_nullable(sample_data.dtypes))
    return schema, dtypes


def make_dtypes_nullable(dtypes):
    # dtypes[dtypes == "int64"] = "Int64"
    # dtypes[dtypes == "int32"] = "Int32"
    # Note: it'd be better to use pandas' nullable integers once this issue is
    # resolved: https://issues.apache.org/jira/browse/ARROW-5379
    dtypes[dtypes == "int64"] = "float64"
    dtypes[dtypes == "int32"] = "float32"
    return dtypes


def get_row_count(csv):
    """Get a count of the number of rows in the CSV without parsing every row

    Works for any CSV pandas can read.

    Returns the number of rows (int).
    """
    _, handles = pd.io.common._get_handle(csv, mode="r", compression="infer")
    for i, _ in enumerate(handles[0], 1):
        pass
    handles[0].close()
    return i


def convert_csv_to_parquet(csv, parquet, csv_dtypes):
    schema, dtype = get_csv_types(csv, dtypes=csv_dtypes)
    reader = pd.read_csv(csv, dtype=dtype, chunksize=10000)
    with ParquetWriter(parquet, schema) as pqwriter:
        for chunk in reader:
            table = Table.from_pandas(chunk, schema=schema)
            pqwriter.write_table(table)


if __name__ == "__main__":
    args = parse_command_line()
    convert_csv_to_parquet(args.input_csv, args.output_parquet, csv_dtypes=args.dtypes)
