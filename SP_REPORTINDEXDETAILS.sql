CREATE PROCEDURE sp_ReportIndexDetails
AS

BEGIN

SELECT 
	'INDEX DETAILS' AS [REPORT],
    @@SERVERNAME AS [ServerName], 
    DB_NAME() AS [DatabaseName], 
    SCHEMA_NAME([obj].[schema_id]) AS [SchemaName], 
    [obj].[name] AS [ObjectName], 
    CASE 
        WHEN [obj].[type] = 'U' THEN 'Table' 
        WHEN [obj].[type] = 'V' THEN 'View' 
    END AS [ObjectType], 
    [ind].[index_id] AS [IndexID], 
    ISNULL([ind].[name], '-- Here is no index') AS [IndexName], 
    CASE 
        WHEN [ind].[type] = 0 THEN 'Heap' 
        WHEN [ind].[type] = 1 THEN 'Clustered' 
        WHEN [ind].[type] = 2 THEN 'NonClustered' 
        WHEN [ind].[type] = 3 THEN 'XML' 
        WHEN [ind].[type] = 4 THEN 'Spatial' 
        WHEN [ind].[type] = 5 THEN 'Clustered Columnstore Index'        /* Applies to: SQL Server 2014 (12.x) through SQL Server 2017. */ 
        WHEN [ind].[type] = 6 THEN 'Nonclustered Columnstore Index'     /* Applies to: SQL Server 2012 (11.x) through SQL Server 2017. */ 
        WHEN [ind].[type] = 7 THEN 'Nonclustered Hash Index'            /* Applies to: SQL Server 2014 (12.x) through SQL Server 2017. */ 
    END AS [IndexType], 
    STATS_DATE([ind].OBJECT_ID, [ind].index_id) AS [LastStatsUpdated], 
    [ddius].[user_seeks] AS [UserSeeks], 
    [ddius].[user_scans] AS [UserScans], 
    [ddius].[user_lookups] AS [UserLookups], 
    [ddius].[user_updates] AS [UserUpdates], 
    [ddius].[last_user_seek] AS [LastUserSeek], 
    [ddius].[last_user_scan] AS [LastUserScan], 
    [ddius].[last_user_lookup] AS [LastUserLookup], 
    [ddius].[last_user_update] AS [LastUserUpdate],                        /* Includes Inserts, Deletes. Counts operations, not rows*/ 
    [ddios].[leaf_insert_count] AS [LeafLevelInsertCount], 
    [ddios].[leaf_update_count] AS [LeafLevelUpdateCount], 
    [ddios].[leaf_delete_count] AS [LeafLevelDeleteCount] 
FROM 
    [sys].[indexes] AS [ind] 
    INNER JOIN [sys].[objects] AS [obj] 
        ON [ind].[object_id] = [obj].[object_id] 
    LEFT JOIN [sys].[dm_db_index_usage_stats] AS [ddius] 
        ON [ind].[object_id] = [ddius].[object_id] 
        AND [ind].[index_id] = [ddius].[index_id] 
        AND [ddius].[database_id] = DB_ID() 
    LEFT JOIN [sys].[dm_db_index_operational_stats] (DB_ID(),NULL,NULL,NULL) AS [ddios] 
        ON [ind].[object_id] = [ddios].[object_id] 
        AND [ind].[index_id] = [ddios].[index_id] 
WHERE 
    1 = 1 
    AND [obj].[is_ms_shipped] = 0 
    /* AND [obj].[name]  IN ('TBL1','TBL2', 'TBLn') */					/* Uncomment and add TableNames if necessary */ 
    /* AND [ind].[is_disabled] = 0 */                                   /* Uncomment to list only enabled indexes*/     
ORDER BY 2, 3, 4, 5, 7 

END