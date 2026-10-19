SET NOCOUNT ON;
DECLARE @loads TABLE (Position int,RunId uniqueidentifier,RowsCopied bigint,UpperWatermark datetime2(7));
INSERT @loads
SELECT ROW_NUMBER() OVER(ORDER BY CompletedAt),RunId,RowsCopied,UpperWatermark
FROM etl.LoadHistory WHERE SchemaName='retail' AND TableName='Sales';
IF (SELECT COUNT(*) FROM @loads)<>3 THROW 50010,'Se esperan tres ejecuciones de ventas en este laboratorio nuevo.',1;
IF EXISTS(SELECT 1 FROM @loads WHERE RowsCopied<>CASE Position WHEN 1 THEN 3 WHEN 2 THEN 2 ELSE 0 END)
    THROW 50011,'La secuencia esperada de filas copiadas es 3,2,0.',1;
IF (SELECT UpperWatermark FROM @loads WHERE Position=2)<>(SELECT UpperWatermark FROM @loads WHERE Position=3)
    THROW 50012,'Sin cambios, el checkpoint debe conservarse.',1;
IF (SELECT COUNT(*) FROM retail.Sales)<>4 THROW 50013,'Se esperan cuatro ventas finales.',1;

-- Repetir Commit para el primer run no debe duplicar historia ni retroceder checkpoint.
DECLARE @Run uniqueidentifier,@Lower datetime2(7),@Upper datetime2(7),@Rows bigint,@Before datetime2(7);
SELECT TOP(1) @Run=RunId,@Lower=LowerWatermark,@Upper=UpperWatermark,@Rows=RowsCopied
FROM etl.LoadHistory WHERE SchemaName='retail' AND TableName='Sales' ORDER BY CompletedAt;
SELECT @Before=LastWatermark FROM etl.LoadConfig WHERE SchemaName='retail' AND TableName='Sales';
EXEC etl.CommitLoad @SchemaName='retail',@TableName='Sales',@RunId=@Run,@LowerWatermark=@Lower,@UpperWatermark=@Upper,@RowsCopied=@Rows;
IF (SELECT COUNT(*) FROM etl.LoadHistory WHERE RunId=@Run AND SchemaName='retail' AND TableName='Sales')<>1
    THROW 50014,'Commit duplicado no es idempotente.',1;
IF (SELECT LastWatermark FROM etl.LoadConfig WHERE SchemaName='retail' AND TableName='Sales')<>@Before
    THROW 50015,'El reintento de Commit alteró el checkpoint.',1;
SELECT Position,RunId,RowsCopied,UpperWatermark FROM @loads ORDER BY Position;
SELECT 'RETAIL_HISTORY_TEST_PASS' AS Result;
