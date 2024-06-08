
/*
PRIMERA PARTE INDICES CLUSTERED
*/

SET STATISTICS IO, TIME ON;
SELECT *
INTO [Sales].[OrdersNO]
FROM [WideWorldImporters].[Sales].[Orders];

SELECT *
FROM [WideWorldImporters].[Sales].[OrdersNO] -- SIN INDICES

/*
- Veamos cu�l es la forma de obtener la Informaci�n.
- Cu�ntas veces utilizamos [SELECT *] En nuestra consulta?
- Entity Framework?
- ORM?
*/

/* Reducimos el tama�o de la consulta */
SELECT OrderId, CustomerId, OrderDate, ExpectedDeliveryDate
FROM [WideWorldImporters].[Sales].[OrdersNO]

SELECT OrderId
FROM [WideWorldImporters].[Sales].[OrdersNO]


/* Consultamos solo un Subconjunto */
SELECT OrderId
FROM [WideWorldImporters].[Sales].[OrdersNO]
WHERE OrderDate  = '2015-01-22'

/* EN RESUMEN */
SELECT *
FROM [WideWorldImporters].[Sales].[OrdersNO]

SELECT OrderId, CustomerId, OrderDate, ExpectedDeliveryDate
FROM [WideWorldImporters].[Sales].[OrdersNO]

SELECT OrderId
FROM [WideWorldImporters].[Sales].[OrdersNO]

SELECT OrderId
FROM [WideWorldImporters].[Sales].[OrdersNO]
WHERE OrderDate  = '2015-01-22'


/*
 2. Comparando con Tabla que s� tiene un ordenamiento.
*/
SET STATISTICS IO, TIME ON;
SELECT *
FROM [WideWorldImporters].[Sales].[Orders] -- CON INDICE


SELECT OrderId, CustomerId, OrderDate, ExpectedDeliveryDate
FROM [WideWorldImporters].[Sales].[Orders]

SELECT OrderId
FROM [WideWorldImporters].[Sales].[Orders]

-- Estudiamos el comportamiento con Filtro de Fecha
SELECT OrderId
FROM [WideWorldImporters].[Sales].[OrdersNO]
WHERE OrderDate  = '2015-01-22'

SELECT OrderId
FROM [WideWorldImporters].[Sales].[Orders]
WHERE OrderDate  = '2015-01-22'
-- Una tabla con �ndice clustered nos puede dar el siguiente tipo de sugerencia:
-- Vemos que nos recomienda "Agregar un �ndice NonCLusteres puede
-- mejorar un 99.38% la performance"
-- No siempre hay que aplicarlas, pero es positivo poder obtener
-- Este tipo de sugerencias gracias a tener un �ndice clustered

/*
 3. B�squeda de heaps, tablas sin ordenamiento 
*/
EXEC sp_ReportIndexDetails -- Reporte de los �ndices existenntes

-- B�squeda de Missing INdexes
EXEC [dbo].[sp_ReportMissingIndex] -- Busca todos los �ndices sugeridos o faltantes

EXEC [dbo].[sp_ReportUserDbTables]

/*
SEGUNDA PARTE INDICES NONCLUSTERED
*/
SET STATISTICS IO, TIME ON;

-- Estudiamos el comportamiento con Filtro de Fecha
SELECT OrderId
FROM [WideWorldImporters].[Sales].[OrdersNO]
WHERE OrderDate  = '2015-01-22'

SELECT OrderId
FROM [WideWorldImporters].[Sales].[Orders]
WHERE OrderDate  = '2015-01-22'


/* Creamos �ndice sugerido, adhesi�n de un �ndice Nonclustered */
CREATE INDEX IX_OrdersNO_OrderDate ON [WideWorldImporters].[Sales].[OrdersNO] (OrderDate)
CREATE INDEX IX_Orders_OrderDate ON [WideWorldImporters].[Sales].[Orders] (OrderDate)

SELECT OrderId
FROM [WideWorldImporters].[Sales].[OrdersNO]
WHERE OrderDate  = '2015-01-22'

SELECT OrderId
FROM [WideWorldImporters].[Sales].[Orders]
WHERE OrderDate  = '2015-01-22'

/*
La tabla que no ten�a un orden ha heho un seel del �ndice NonClustered
y la siguiente tambi�n. Si nos fijamos el costo la primera tiene un 99%
en comparaci�n con el 1% de la segunda.
Los mensajes nos dicen que la primera consulta lee 76 p�ginas contra
las 2 p�ginas de la segunda. De 76 a 2 hay una gran diferencia.
Observamos un Heap en la primera consulta, no ten�a un �ndice clustered
y por tanto no ten�a un ordenamiento definido. Le pedimos el OrderId pero 
el �ndice lo creamos para OrderDate, pero eso se basa en un RID (row id);
En la segunda tabla no necesitamos el RID lookup porque tenemos un ordenamiento
a trav�s del OrderID.
*/


/*
   DUIs
*/
-- Generamos dos tablas id�nticas para pruebas de modificaci�n

SELECT *
INTO [WideWorldImporters].[Sales].[OrdersTest1]
FROM [WideWorldImporters].[Sales].[OrdersNO]
CREATE CLUSTERED INDEX OrdersTest1_IX ON [WideWorldImporters].[Sales].[OrdersTest1] (OrderID) 
-- CON INDICE CLUSTERED

SELECT *
INTO [WideWorldImporters].[Sales].[OrdersTest2]
FROM [WideWorldImporters].[Sales].[OrdersNO]
-- SIN CLUSTERED

-- VERIFICAMOS DATOS PARA DETERMINAR CONSULTAS
SELECT TOP 100 *
FROM [WideWorldImporters].[Sales].[OrdersTest1]

-- TIPOS DE CONSULTAS QUE REVISAREMOS
SELECT OrderId, CustomerID, ContactPersonID
FROM [WideWorldImporters].[Sales].[OrdersTest1]
WHERE CustomerID = 47

SELECT OrderId, CustomerID, ContactPersonID
FROM [WideWorldImporters].[Sales].[OrdersTest2]
WHERE CustomerID = 47

-- Cuando tenemos pocos registros parece que no hay diferencias
-- Pareciera ser que sin INDICE la operaci�n es menos costosa

-- CREAMOS UN INDICE EN CUSTOMER ID??
CREATE INDEX IXOrdersTest1_CustomerID ON [WideWorldImporters].[Sales].[OrdersTest1] (CustomerID) -- NO ES CLUSTERED

-- VEAMOS AHORA QUE SUCEDE
SELECT OrderId, CustomerID, ContactPersonID
FROM [WideWorldImporters].[Sales].[OrdersTest1]
WHERE CustomerID = 47

SELECT OrderId, CustomerID, ContactPersonID
FROM [WideWorldImporters].[Sales].[OrdersTest2]
WHERE CustomerID = 47


-- CREAMOS UN INDICE SOBRE LA TABLA QUE ERA HEAP y CONSULTAMOS
CREATE INDEX IXOrdersTest2_CustomerID ON [WideWorldImporters].[Sales].[OrdersTest2] (CustomerID)

SELECT OrderId, CustomerID, ContactPersonID
FROM [WideWorldImporters].[Sales].[OrdersTest1]
WHERE CustomerID = 47

SELECT OrderId, CustomerID, ContactPersonID
FROM [WideWorldImporters].[Sales].[OrdersTest2]
WHERE CustomerID = 47
-- Oberservamos las diferencias al buscar los datos sin �ndice
-- Cuando tengo un �ndice cluster va a buscar a trav�s de la llave Key Lookup
-- Cuando no tengo ning�n ordenamiento se utilizar� un RID lookup (lookup a trav�s de un ID creado internamente)
-- Hay que evaluar que sucede, porque en el sgunda caso tenemos tres veces menos lecturas 110 vs 338
-- NO es posible establece una regla general re aplicaci�n


-- CREAMOS INDICES PARA CADA CASO PAR VER QUE PASA
CREATE INDEX IXOrdersTest1_ContactPersonID              ON [WideWorldImporters].[Sales].[OrdersTest1] (ContactPersonID)
CREATE INDEX IXOrdersTest1_OrderDate                    ON [WideWorldImporters].[Sales].[OrdersTest1] (OrderDate)
CREATE INDEX IXOrdersTest1_ExpectedDeliveryDate         ON [WideWorldImporters].[Sales].[OrdersTest1] (ExpectedDeliveryDate)
CREATE INDEX IXOrdersTest1_CustomerPurchaseOrderNumber  ON [WideWorldImporters].[Sales].[OrdersTest1] (CustomerPurchaseOrderNumber)
CREATE INDEX IXOrdersTest1_PickingCompletedWhen         ON [WideWorldImporters].[Sales].[OrdersTest1] (PickingCompletedWhen)
CREATE INDEX IXOrdersTest1_LastEditedWhen               ON [WideWorldImporters].[Sales].[OrdersTest1] (LastEditedWhen)

DROP INDEX IXOrdersTest2_CustomerID ON [WideWorldImporters].[Sales].[OrdersTest2]

sp_ReportUserDbTables; -- Analisis para ver cuales de mis tablas tienen qu� cantidad de espacio utilizado





-- Qu� pasa con las Modificaciones
INSERT INTO [Sales].[OrdersTest1]
       ([OrderID], [CustomerID], [SalespersonPersonID], [PickedByPersonID], [ContactPersonID],
        [BackorderOrderID], [OrderDate], [ExpectedDeliveryDate], [CustomerPurchaseOrderNumber],
        [IsUndersupplyBackordered], [Comments], [DeliveryInstructions], [InternalComments],
        [PickingCompletedWhen], [LastEditedBy], [LastEditedWhen])
VALUES
       (ABS(CHECKSUM(NewId())) % 1000, 832, 2, NULL, 3032, 45, CAST(N'2013-01-01' AS Date), CAST(N'2013-01-02' AS Date),
        N'12126', 1, N'Comentario', N'Instrucciones de entrega', N'Comentarios internos',
        NULL, 1, GETDATE());

-- Qu� pasa con las Modificaciones
INSERT INTO [Sales].[OrdersTest2]
       ([OrderID], [CustomerID], [SalespersonPersonID], [PickedByPersonID], [ContactPersonID],
        [BackorderOrderID], [OrderDate], [ExpectedDeliveryDate], [CustomerPurchaseOrderNumber],
        [IsUndersupplyBackordered], [Comments], [DeliveryInstructions], [InternalComments],
        [PickingCompletedWhen], [LastEditedBy], [LastEditedWhen])
VALUES
       (ABS(CHECKSUM(NewId())) % 1000, 832, 2, NULL, 3032, 45, CAST(N'2013-01-01' AS Date), CAST(N'2013-01-02' AS Date),
        N'12126', 1, N'Comentario', N'Instrucciones de entrega', N'Comentarios internos',
        NULL, 1, GETDATE());

--CASO UPDATE
BEGIN TRAN 
UPDATE [Sales].[OrdersTest1] -- TABLA ORDENADA
SET [CustomerID] = 100, [OrderDate] = getdate(), [ExpectedDeliveryDate] = getdate() , [PickingCompletedWhen] = NUll
WHERE OrderID = ABS(CHECKSUM(NewId())) % 1000


UPDATE [Sales].[OrdersTest2] -- TABLA SIN ORDENAMIENTO
SET [CustomerID] = 100, [OrderDate] = getdate(), [ExpectedDeliveryDate] = getdate(), [PickingCompletedWhen] = NUll
WHERE OrderID = ABS(CHECKSUM(NewId())) % 1000
ROLLBACK
/* En este caso vemos como es necesario recorrer toda la tabla
para el caso de la tabla sin orden prestablecido
*/

--
-- CASO DELETEs (No deber�a haber DELETES en trablas transaccionales!)
--
SELECT *
INTO [WideWorldImporters].[Sales].[OrdersTest3]
FROM [WideWorldImporters].[Sales].[OrdersNO]
CREATE CLUSTERED INDEX OrdersTest3_IX ON  [WideWorldImporters].[Sales].[OrdersTest3](OrderID)

SELECT *
INTO [WideWorldImporters].[Sales].[OrdersTest4]
FROM [WideWorldImporters].[Sales].[OrdersNO]

-- VERIFICAMOS EL TAMA�O DE LAS TABLAS
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
	t.NAME IN ('OrdersTest3','OrdersTest4')
	AND t.is_ms_shipped = 0
	AND i.object_ID > 255
GROUP BY
	t.Name, s.Name, t.create_date, t.modify_date, p.Rows
ORDER BY
	t.Name


DELETE FROM [WideWorldImporters].[Sales].[OrdersTest3]
DELETE FROM [WideWorldImporters].[Sales].[OrdersTest4]

-- SI NUEVAMENTE QUEREMOS OBSERVAR EL TAMA�O
/*
LA tabla indexada ocupa menos tama�o luego de los DELETE,
en una tabla HEAP todo queda "tirado" en cualquier lugar
sin embargo en la tabla con �ndice cluster se puede borrar ordenadamente,
por eso la segunda tabla sigue ocupando m�s espacio luego del delete.
*/

/*
Caso 6: Indexes Fundamentals
*/

SELECT TOP(1000) [RowId]
	,[Name]
	,[MiddleName]
	,[Office]
	,[Gender]
	,[DayOfBirth]
	,[DescriptionText]
FROM [MillionsDB].[dbo].[FakeTable]

CREATE CLUSTERED INDEX IX_FAKETABLE_ROWID ON [MillionsDB].[dbo].[FakeTable] (RowId) 

SET STATISTICS IO, TIME ON

SELECT [RowId],[Name],[Office]
FROM  [MillionsDB].[dbo].[FakeTable]
WHERE 
	Name = 'Emera' 
	AND Office = 200

-- Si me query dice busca primero nombre y despu�s Oficina, Cu�l de los siguientes ser� mejor?? M
CREATE INDEX IX_FakeTable_Office_Name ON [MillionsDB].[dbo].[FakeTable] (Office, Name)
CREATE INDEX IX_FakeTable_Name_Office ON [MillionsDB].[dbo].[FakeTable] (Name, Office)


SELECT [RowId],[Name],[Office]
FROM  [MillionsDB].[dbo].[FakeTable] WITH (INDEX=1) -- Utiliza el �ndice Cl�ster
WHERE 
	Name = 'Emera' 
	AND Office = 200

SELECT [RowId],[Name],[Office]
FROM  [MillionsDB].[dbo].[FakeTable] WITH (INDEX=IX_FakeTable_Office_Name)
WHERE 
	Name = 'Emera' 
	AND Office = 200

SELECT [RowId],[Name],[Office]
FROM  [MillionsDB].[dbo].[FakeTable] WITH (INDEX=IX_FakeTable_Name_Office)
WHERE 
	Name = 'Emera' 
	AND Office = 200
