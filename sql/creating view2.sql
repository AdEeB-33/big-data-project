create view gold.final2
AS
SELECT  *
FROM OPENROWSET(
    BULK 'https://osltdatastorage.dfs.core.windows.net/olistdata/silver/',
    FORMAT = 'PARQUET'
) 
AS result2
where order_status='delivered';

SELECT * FROM gold.final2;



