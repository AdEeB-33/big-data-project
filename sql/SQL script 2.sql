-- sql on olist dataset
-- creating view
create schema gold
create view gold.final
AS
SELECT  *
FROM OPENROWSET(
    BULK 'https://osltdatastorage.dfs.core.windows.net/olistdata/silver/',
    FORMAT = 'PARQUET'
) 
select * from gold.final