-- VERIFICAMOS EL TAMAÑO DE LAS TABLAS
SELECT 
	t.NAME AS TableName,
	s.Name AS SchemaName, 
	t.create_date, 
	t.modify_date,
	p.rows AS RowCounts,
	SUM(a.total_pages) * 8 AS TotalSpaceKB, 
	SUM(a.used_pages)  * 8 AS UsedSapaceKB, 
	(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM
	sys.tables t
INNER JOIN
	sys.indexes i ON t.object_id = i.object_id
INNER JOIN
	sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN
	sys.allocation_units a ON p.partition_id = a.container_id	
LEFT OUTER JOIN
	sys.schemas s ON t.schema_id = s.schema_id
WHERE
	t.NAME IN ('OrdersTest3','OrdersTest4') -----------------------NOMBRE DE LAS TABLAS
	AND t.is_ms_shipped = 0
	AND i.object_ID > 255
GROUP BY
	t.Name, s.Name, t.create_date, t.modify_date, p.Rows
ORDER BY
	t.Name