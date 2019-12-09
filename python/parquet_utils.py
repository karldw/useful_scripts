import pandas as pd
import pyarrow
import pyarrow.parquet


def compute_schema(df, date_cols=None):
    """
    Create a pyarrow schema for the pandas dataframe `df`.

    This is worth doing, rather than letting pyarrow automatically calculate the
    schema, for two reasons:
    - Convert extension int columns to parquet integer columns
    - Convert date cols to parquet `date32` columns.
    """
    schema = []
    type_conversion = {
        "Int64": pyarrow.int64(),
        "Int32": pyarrow.int32(),
        "int64": pyarrow.int64(),
        "int32": pyarrow.int32(),
        "int": pyarrow.int32(),
        "float64": pyarrow.float64(),
        "float32": pyarrow.float32(),
        "float": pyarrow.float32(),
        "str": pyarrow.string(),
        "object": pyarrow.string(),
        # Note that the arguments to pyarrow.dictionary changed between v0.13.0
        # and v0.14.1
        "category": pyarrow.dictionary(
            pyarrow.int32(), pyarrow.string(), ordered=False
        ),
        "date32": pyarrow.date32(),  # Note: date32 isn't a python type
    }
    dtypes = {k: str(v) for k, v in dict(df.dtypes).items()}
    if date_cols is not None:
        for col in date_cols:
            if col not in dtypes:
                raise KeyError(f"Specified date_col '{col}' not in df columns")
            dtypes[col] = "date32"
    for col, dtype in dtypes.items():
        try:
            type = type_conversion[dtype]
        except KeyError:
            raise NotImplementedError(
                f"Conversion not implemented for type {dtype} (column {col})"
            )
        schema.append(pyarrow.field(col, type, nullable=True))
    return pyarrow.schema(schema)


def extension_int_to_float(df, exclude=[]):
    """
    You can delete this function once this issue is resolved:
    https://issues.apache.org/jira/browse/ARROW-5379

    This function should be run *after* `compute_schema`.

    Note integers above 2^53 could lose information in the conversion to float.
    """
    extension_int_types = {
        pd.Int8Dtype(),
        pd.Int16Dtype(),
        pd.Int32Dtype(),
        pd.Int64Dtype(),
    }
    new_types = {
        col: "float64"
        for col in df.columns
        if df[col].dtypes in extension_int_types and col not in exclude
    }
    return df.astype(new_types)


def write_parquet(df, filename, date_cols=None, preserve_index=False):
    if preserve_index:
        df = df.reset_index()
    schema = compute_schema(df, date_cols=date_cols)
    df = extension_int_to_float(df)
    table = pyarrow.Table.from_pandas(df, preserve_index=False, schema=schema)
    pyarrow.parquet.write_table(table, filename, version="2.0")
