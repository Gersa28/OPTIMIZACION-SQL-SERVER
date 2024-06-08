--  Optimización SQL SERVER

------------------------------------------------------
--3 Analizar un plan de ejecución
------------------------------------------------------

-- Ejecutaremos algunos querys de práctica

USE WideWorldImporters

GO

-- Activemos las estadísticas 
SET STATISTICS IO ON

GO

SELECT TOP 10000 * 
  FROM Application.People p INNER JOIN 
       Sales.InvoiceLines i ON p.PersonID = i.LastEditedBy INNER JOIN 
       Warehouse.StockItemTransactions s ON p.PersonID = s.LastEditedBy
 ORDER BY i.StockItemID

GO

SELECT *
  FROM Sales.Invoices
--WITH(INDEX([FK_Sales_Invoices_AccountsPersonID]))
 WHERE CustomerID = 191

GO

SELECT * FROM Warehouse.VehicleTemperatures

GO

SELECT * FROM Sales.InvoiceLines

GO

SELECT * FROM Sales.Invoices WHERE OrderID = 100

GO

SELECT * FROM Purchasing.PurchaseOrders


-- Para desplegar pantalla
-- TOOLS \ OPTIONS \ Query Results \ SQL Server \ Result to Grid


SET STATISTICS IO ON

SELECT (SELECT MAX([OrderDate])
FROM [Sales].[Orders]) mx,
(SELECT
MIN([BackorderOrderID])
FROM [Sales].[Orders]) mn;

GO

SELECT MAX([OrderDate]) mx,
MIN([BackorderOrderID]) mn
FROM [Sales].[Orders];

------------------------------------------------------
-- 04 - Indices: ¿Cómo nos pueden ayudar los índices?
------------------------------------------------------

USE WideWorldImporters

GO

SET STATISTICS IO ON
DROP INDEX [IX_prueba] ON [Warehouse].[StockItemTransactions];

-- Ejecutmos la siguiente consulta, y en mensajes observamos la cantidad de lecturas lógicas
SELECT TOP 10000 * 
  FROM Application.People p INNER JOIN 
       Sales.InvoiceLines i ON p.PersonID = i.LastEditedBy INNER JOIN 
       Warehouse.StockItemTransactions s ON p.PersonID = s.LastEditedBy
 ORDER BY i.StockItemID

 GO

-- Creamos el índice sugerido y volvemos a ejecutar el query-------
CREATE NONCLUSTERED INDEX [IX_prueba]
ON [Warehouse].[StockItemTransactions] ([LastEditedBy])
INCLUDE ([StockItemTransactionID],[StockItemID],[TransactionTypeID],[CustomerID],
		[InvoiceID],[SupplierID],[PurchaseOrderID],[TransactionOccurredWhen],
		[Quantity],[LastEditedWhen])
GO

SELECT TOP 10000 * 
  FROM Application.People p INNER JOIN 
       Sales.InvoiceLines i ON p.PersonID = i.LastEditedBy INNER JOIN 
       Warehouse.StockItemTransactions s ON p.PersonID = s.LastEditedBy
 ORDER BY i.StockItemID
-- -----------------------------------------

-- EJEMPLO SIGUINTE -----------------------
-- Activando las estadísticas nos va a mostrar el detalle de la carga de escritura y tamaño de paginación
SET STATISTICS IO ON

SELECT [OrderID],[ContactPersonID],
        [PickingCompletedWhen]
FROM [WideWorldImporters].[Sales].[Orders]
WHERE ContactPersonID = 3176;

-- Corregir el índice:
-- FK_Sales_Orders_ContactPersonID agregar [PickingCompletedWhen]

-- Aqui podemos ver la respuesta de las estadísticas.
-- Table 'Orders'. Scan count 1, logical reads 416,
-- En el plan de ejecucion podemos ver el Key Lookup y las columnas que estan fuera del índice.
-- Corregir el índice

-------------------------

SET STATISTICS IO ON
SELECT [InvoiceID]     
      ,[ContactPersonID]
      ,[AccountsPersonID]
  FROM [WideWorldImporters].[Sales].[Invoices]
  WHERE [ContactPersonID] >= 3032 AND
        [ContactPersonID] <= 3035;

-- Corregir el índice
-- FK_Sales_Invoices_ContactPersonID agregar [AccountsPersonID]

------------------------------------------------------
-- Clase 05 - Crear índices, entender plan de ejecución, Analizar las consultas para crear índices
------------------------------------------------------

USE WideWorldImporters

GO

-- Activamos las estadísitcas
-- Analizamos los parámetros
-- * Number of Rows Read ( 1 Es lo ideal) (Compara con el número de filas que nos tiene que devolver)
-- * Actual Number of Rows ( 1 Es lo ideal)
-- * Estimated Operator Cost
-- * Estimated CPU cost

-- SIN ÍNDICE ------------------------------
DROP INDEX [IX_prueba] ON [Warehouse].[StockItemTransactions];

SET STATISTICS IO ON

SELECT TOP 10000 * 
  FROM Application.People p INNER JOIN 
       Sales.InvoiceLines i ON p.PersonID = i.LastEditedBy INNER JOIN 
       Warehouse.StockItemTransactions s ON p.PersonID = s.LastEditedBy
 ORDER BY i.StockItemID

SELECT [OrderID],[ContactPersonID],[PickingCompletedWhen]
FROM [Sales].[Orders]
WHERE ContactPersonID = 3176;


-- con INDICE -------------------------------
CREATE NONCLUSTERED INDEX [IX_prueba]
ON [Warehouse].[StockItemTransactions] ([LastEditedBy])
INCLUDE (
		[StockItemTransactionID],
		[StockItemID],
		[TransactionTypeID],
		[CustomerID],
		[InvoiceID],
		[SupplierID],
		[PurchaseOrderID],
		[TransactionOccurredWhen],
		[Quantity],
		[LastEditedWhen]
		)
GO

SELECT TOP 10000 * 
  FROM Application.People p INNER JOIN 
       Sales.InvoiceLines i ON p.PersonID = i.LastEditedBy INNER JOIN 
       Warehouse.StockItemTransactions s ON p.PersonID = s.LastEditedBy
 ORDER BY i.StockItemID

-- OBSERVAMOS EL DIGUIENTE EJEMPLO, 
SELECT [OrderID],[ContactPersonID],[PickingCompletedWhen]
FROM [Sales].[Orders]
WHERE ContactPersonID = 3176;



------------------------------------------------------
-- Clase 06 - Forzar Indices
------------------------------------------------------

USE WideWorldImporters

GO

SET STATISTICS IO ON

-- En este ejemplo indicamos que queremos utulizar el índice FK_Sales_Invoices_AccountsPersonID

SELECT *
FROM [WideWorldImporters].[Sales].[Invoices]
WITH(INDEX([FK_Sales_Invoices_AccountsPersonID]))
WHERE CustomerID = 191

SELECT *
FROM [WideWorldImporters].[Sales].[Invoices]
--WITH(INDEX([FK_Sales_Invoices_AccountsPersonID]))
WHERE CustomerID = 191
-- Reiterando que forzar el uso de un indice NO es una buena idea, exepto en casos aislados de uso temporal. 
-- Imaginemos una migracion o una carga especial de datos donde queremos que los datos se comporten de una forma en específico.
-- Siempre es recomendado reescribir una consulta para que se utilice el indice adecuado.


------------------------------------------------------
-- Clase 07 - Los Índices pueden perjudicar el rendimiento? ¿Siempre son buenos los índices?
------------------------------------------------------

USE AdventureWorks2019

GO 
-- Activamos las estadísticas
SET STATISTICS IO ON

GO

SELECT SalesOrderDetailID,
	   OrderQty
  FROM Sales.SalesOrderDetail S
 WHERE ProductID = (SELECT AVG(ProductID)
					 FROM Sales.SalesOrderDetail S2
					 WHERE S2.SalesOrderID = S.SalesOrderID
					 GROUP BY SalesOrderID)

-- Se pueden ver los datos y analizar la cantidad e información
-- una pagina pesa 8K. se multiplican los valores para ver el tamaño de la informacion que estamos procesando.

CREATE NONCLUSTERED INDEX IX_PRIMERO -- FUNCIONA BIEN
ON Sales.SalesOrderDetail
(SalesOrderID ASC, ProductID ASC)
INCLUDE (SalesOrderDetailID, OrderQty)


CREATE NONCLUSTERED INDEX IX_SEGUNDO -- NO MEJORA LA SITUACIÓN
ON Sales.SalesOrderDetail
(ProductID ASC, SalesOrderID ASC)
INCLUDE (SalesOrderDetailID, OrderQty)

-- Ejecutamos los dos indices y vemos que el segundo, donde aparentemente tienen los mismos datos solo que en orden distinto,
-- afecta el rendimiento de la consulta

DROP INDEX IX_PRIMERO ON Sales.SalesOrderDetail
DROP INDEX IX_SEGUNDO ON Sales.SalesOrderDetail



------------------------------------------------------
-- Clase 08 - Merge 01
------------------------------------------------------

USE Prueba_Merge

GO

CREATE TABLE UsuarioTarget
(
Codigo INT PRIMARY KEY,
Nombre VARCHAR(100),
Puntos INT
) 
GO

INSERT INTO UsuarioTarget VALUES
(1,'Juan Perez',10),
(2,'Marco Salgado',5),
(3,'Carlos Soto',9),
(4,'Alberto Ruiz',12),
(5,'Alejandro Castro',5)
GO

CREATE TABLE UsuarioSource
(
Codigo INT PRIMARY KEY,
Nombre VARCHAR(100),
Puntos INT
) 
GO

INSERT INTO UsuarioSource VALUES
(1,'Juan Perez',12),
(2,'Marco Salgado',11),
(4,'Alberto Ruiz Castro',4),
(5,'Alejandro Castro',5),
(6,'Pablo Ramos',8)
 
GO

SELECT * FROM UsuarioTarget
SELECT * FROM UsuarioSource

GO

--Sincronizar la tabla TARGET con
--los datos actuales de la tabla SOURCE
MERGE UsuarioTarget AS TARGET
USING UsuarioSource AS SOURCE 
   ON (TARGET.Codigo = SOURCE.Codigo) 
--Cuandos los registros concuerdan por la llave
--se actualizan los registros si tienen alguna variación
 WHEN MATCHED AND (TARGET.Nombre <> SOURCE.Nombre 
			    OR TARGET.Puntos <> SOURCE.Puntos) THEN 
   UPDATE SET TARGET.Nombre = SOURCE.Nombre, 
              TARGET.Puntos = SOURCE.Puntos
--Cuando los registros no concuerdan por la llave
--indica que es un dato nuevo, se inserta el registro
--en la tabla TARGET proveniente de la tabla SOURCE
 WHEN NOT MATCHED BY TARGET THEN 
   INSERT (Codigo, Nombre, Puntos) 
   VALUES (SOURCE.Codigo, SOURCE.Nombre, SOURCE.Puntos)
--Cuando el registro existe en TARGET y no existe en SOURCE
--se borra el registro en TARGET
 WHEN NOT MATCHED BY SOURCE THEN 
   DELETE
--Seccion opcional e informativa
--$action indica el tipo de accion
--en OUTPUT retorna cualquiera de las 3 acciones 
--'INSERT', 'UPDATE', or 'DELETE', 
OUTPUT $action, 
DELETED.Codigo AS TargetCodigo, 
DELETED.Nombre AS TargetNombre, 
DELETED.Puntos AS TargetPuntos, 
INSERTED.Codigo AS SourceCodigo, 
INSERTED.Nombre AS SourceNombre, 
INSERTED.Puntos AS SourcePuntos; 
SELECT @@ROWCOUNT;
GO
 
SELECT * FROM UsuarioTarget
SELECT * FROM UsuarioSource


--------------------
--------------------
-- Sintaxis del MERGE
--------------------

-- SQL Server and Azure SQL Database -- PROPIEDADES DEL MERGE
[ WITH <common_table_expression> [,...n] ]  
MERGE
    [ TOP ( expression ) [ PERCENT ] ]
    [ INTO ] <target_table> [ WITH ( <merge_hint> ) ] [ [ AS ] table_alias ]  
    USING <table_source> [ [ AS ] table_alias ]
    ON <merge_search_condition>  
    [ WHEN MATCHED [ AND <clause_search_condition> ]  
        THEN <merge_matched> ] [ ...n ]  
    [ WHEN NOT MATCHED [ BY TARGET ] [ AND <clause_search_condition> ]  
        THEN <merge_not_matched> ]  
    [ WHEN NOT MATCHED BY SOURCE [ AND <clause_search_condition> ]  
        THEN <merge_matched> ] [ ...n ]  
    [ <output_clause> ]  
    [ OPTION ( <query_hint> [ ,...n ] ) ]
;  
  
<target_table> ::=  
{
    [ database_name . schema_name . | schema_name . ]  
  target_table  
}  
  
<merge_hint>::=  
{  
    { [ <table_hint_limited> [ ,...n ] ]  
    [ [ , ] INDEX ( index_val [ ,...n ] ) ] }  
}  

<merge_search_condition> ::=  
    <search_condition>  
  
<merge_matched>::=  
    { UPDATE SET <set_clause> | DELETE }  
  
<merge_not_matched>::=  
{  
    INSERT [ ( column_list ) ]
        { VALUES ( values_list )  
        | DEFAULT VALUES }  
}  
  
<clause_search_condition> ::=  
    <search_condition>

------------------------------------------------------
-- 09 - Mege, otras formas de utilizar
------------------------------------------------------

USE Prueba_Merge

GO

CREATE OR ALTER PROCEDURE MerceUsuarioTarget
    @Codigo integer,
    @Nombre varchar(100),
    @Puntos integer
AS
BEGIN
    MERGE UsuarioTarget AS T
        USING (SELECT @Codigo, @Nombre, @Puntos) AS S 
					   (Codigo, Nombre, Puntos)
		ON (T.Codigo = S.Codigo)
    WHEN MATCHED THEN
        UPDATE SET T.Nombre = S.Nombre,
				   T.Puntos = S.Puntos
    WHEN NOT MATCHED THEN
        INSERT (Codigo, Nombre, Puntos)
        VALUES (S.Codigo, S.Nombre, S.Puntos) ;
END

GO 

select * from UsuarioTarget
exec MerceUsuarioTarget 3,'Roy Rojas', 9
select * from UsuarioTarget


-----------------------
-- Practica


USE AdventureWorks2019

BEGIN TRANSACTION
ROLLBACK

DROP PROCEDURE usp_UpdateInventory

SELECT * FROM  Production.ProductInventory WHERE ProductID = 707

go

CREATE OR ALTER PROCEDURE msp_ActualizaInventario
    @OrderDate datetime  
AS  
MERGE Production.ProductInventory AS target  
USING (SELECT ProductID, SUM(OrderQty) FROM Sales.SalesOrderDetail AS sod  
    JOIN Sales.SalesOrderHeader AS soh  
    ON sod.SalesOrderID = soh.SalesOrderID  
    AND soh.OrderDate = @OrderDate  
    GROUP BY ProductID) AS source (ProductID, OrderQty)  
ON (target.ProductID = source.ProductID)  
WHEN MATCHED AND target.Quantity - source.OrderQty <= 0  
    THEN DELETE  
WHEN MATCHED
    THEN UPDATE SET target.Quantity = target.Quantity - source.OrderQty,
                    target.ModifiedDate = GETDATE()  

OUTPUT $action,source.ProductID, source.OrderQty,
	Inserted.ProductID, Inserted.Quantity,
    Inserted.ModifiedDate, Deleted.ProductID,  
    Deleted.Quantity, Deleted.ModifiedDate;  
GO  
  
select * from Production.ProductInventory WHERE ProductID = 707
select * from Production.ProductInventory WHERE ProductID = 747

EXECUTE Production.msp_UpdateInventory '2011-05-31 00:00:00.000'  

select * from Production.ProductInventory WHERE ProductID = 707
select * from Production.ProductInventory WHERE ProductID = 747


SELECT ProductID, SUM(OrderQty) FROM Sales.SalesOrderDetail AS sod  
    JOIN Sales.SalesOrderHeader AS soh  
    ON sod.SalesOrderID = soh.SalesOrderID  
    AND soh.OrderDate = '2011-05-31 00:00:00.000'  
	GROUP BY ProductID
	ORDER BY ProductID


-------