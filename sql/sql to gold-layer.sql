--CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'mohammedadeeb@#1';
--CREATE DATABASE SCOPED CREDENTIAL mohammedadeeb 
--WITH IDENTITY = 'Managed Identity';
--select * from sys.database_credentials

-- Create external file format
CREATE EXTERNAL DATA SOURCE goldlayer
WITH (
    LOCATION = 'https://osltdatastorage.dfs.core.windows.net/olistdata/gold/',
    CREDENTIAL = mohammedadeeb
);
CREATE EXTERNAL FILE FORMAT extfileformat
WITH (
    FORMAT_TYPE = PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
);

CREATE EXTERNAL TABLE gold.finaltable
WITH (
    LOCATION = 'Serving',
    DATA_SOURCE = goldlayer,
    FILE_FORMAT = extfileformat
)
AS
SELECT * FROM gold.final2;
