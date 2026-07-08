SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'https://osltdatastorage.dfs.core.windows.net/olistdata/silver/',
    FORMAT = 'PARQUET'
) AS rows;

