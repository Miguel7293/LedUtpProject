IF SCHEMA_ID('retail') IS NULL EXEC('CREATE SCHEMA retail');
IF SCHEMA_ID('etl') IS NULL EXEC('CREATE SCHEMA etl');
GO
IF OBJECT_ID('retail.Sales') IS NULL
BEGIN
    CREATE TABLE retail.Sales (
        SaleId int NOT NULL PRIMARY KEY,
        ProductName nvarchar(100) NOT NULL,
        Quantity int NOT NULL CHECK (Quantity > 0),
        UnitPrice decimal(12,2) NOT NULL CHECK (UnitPrice >= 0),
        UpdatedAt datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
    INSERT retail.Sales (SaleId, ProductName, Quantity, UnitPrice)
    VALUES (1,N'Mochila Andes',2,89.90),(2,N'Termo Lima',1,45.00),(3,N'Cuaderno UTP',5,18.50);
END;
IF OBJECT_ID('etl.LoadConfig') IS NULL
BEGIN
    CREATE TABLE etl.LoadConfig (
        SchemaName sysname NOT NULL,
        TableName sysname NOT NULL,
        LoadType varchar(11) NOT NULL CHECK (LoadType IN ('Full','Incremental')),
        WatermarkColumn sysname NULL,
        LastWatermark datetime2(7) NOT NULL DEFAULT '1900-01-01',
        Enabled bit NOT NULL DEFAULT 1,
        PRIMARY KEY (SchemaName, TableName),
        CHECK (LoadType='Full' OR WatermarkColumn IS NOT NULL)
    );
    INSERT etl.LoadConfig (SchemaName,TableName,LoadType,WatermarkColumn)
    VALUES ('SalesLT','Customer','Full',NULL),('SalesLT','Product','Full',NULL),('retail','Sales','Incremental','UpdatedAt');
END;
IF OBJECT_ID('etl.LoadHistory') IS NULL
    CREATE TABLE etl.LoadHistory (
        RunId uniqueidentifier NOT NULL,
        SchemaName sysname NOT NULL,
        TableName sysname NOT NULL,
        LoadType varchar(11) NOT NULL,
        LowerWatermark datetime2(7) NOT NULL,
        UpperWatermark datetime2(7) NOT NULL,
        RowsCopied bigint NOT NULL,
        CompletedAt datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        PRIMARY KEY (RunId,SchemaName,TableName)
    );
GO
CREATE OR ALTER PROCEDURE etl.ListLoads @OnlyTable nvarchar(257)=''
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    IF @OnlyTable<>'' AND NOT EXISTS(SELECT 1 FROM etl.LoadConfig WHERE SchemaName+'.'+TableName=@OnlyTable AND Enabled=1)
        THROW 50005,'Tabla solicitada no habilitada.',1;
    SELECT SchemaName,TableName FROM etl.LoadConfig
    WHERE Enabled=1 AND (@OnlyTable='' OR SchemaName+'.'+TableName=@OnlyTable)
    ORDER BY SchemaName,TableName;
END;
GO
CREATE OR ALTER PROCEDURE etl.GetBounds @SchemaName sysname, @TableName sysname
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Mode varchar(11), @Column sysname, @Lower datetime2(7), @Upper datetime2(7);
    SELECT @Mode=LoadType,@Column=WatermarkColumn,@Lower=LastWatermark
    FROM etl.LoadConfig WHERE SchemaName=@SchemaName AND TableName=@TableName AND Enabled=1;
    IF @Mode IS NULL THROW 50001,'Tabla no habilitada en metadatos.',1;
    SET @Upper=@Lower;
    IF @Mode='Incremental'
    BEGIN
        DECLARE @sql nvarchar(max)=N'SELECT @upper=COALESCE(MAX('+QUOTENAME(@Column)+N'),@lower) FROM '+QUOTENAME(@SchemaName)+N'.'+QUOTENAME(@TableName)+N';';
        EXEC sp_executesql @sql,N'@upper datetime2(7) OUTPUT,@lower datetime2(7)',@upper=@Upper OUTPUT,@lower=@Lower;
        IF @Upper<@Lower SET @Upper=@Lower;
    END;
    SELECT @Mode AS LoadType, COALESCE(@Column,'') AS WatermarkColumn,
        CONVERT(varchar(33),@Lower,126) AS LowerWatermark,
        CONVERT(varchar(33),@Upper,126) AS UpperWatermark;
END;
GO
CREATE OR ALTER PROCEDURE etl.CommitLoad
    @SchemaName sysname,@TableName sysname,@RunId uniqueidentifier,
    @LowerWatermark datetime2(7),@UpperWatermark datetime2(7),@RowsCopied bigint
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DECLARE @Mode varchar(11);
    SELECT @Mode=LoadType FROM etl.LoadConfig WITH (UPDLOCK,HOLDLOCK)
    WHERE SchemaName=@SchemaName AND TableName=@TableName AND Enabled=1;
    IF @Mode IS NULL THROW 50002,'Tabla no habilitada.',1;
    IF EXISTS (SELECT 1 FROM etl.LoadHistory WHERE RunId=@RunId AND SchemaName=@SchemaName AND TableName=@TableName)
    BEGIN
        COMMIT;
        RETURN;
    END;
    IF @UpperWatermark<@LowerWatermark THROW 50003,'Checkpoint inválido.',1;
    IF @Mode='Incremental'
    BEGIN
        UPDATE etl.LoadConfig SET LastWatermark=@UpperWatermark
        WHERE SchemaName=@SchemaName AND TableName=@TableName AND LastWatermark=@LowerWatermark;
        IF @@ROWCOUNT<>1 THROW 50004,'Checkpoint cambió durante la carga.',1;
    END;
    INSERT etl.LoadHistory(RunId,SchemaName,TableName,LoadType,LowerWatermark,UpperWatermark,RowsCopied)
    VALUES(@RunId,@SchemaName,@TableName,@Mode,@LowerWatermark,@UpperWatermark,@RowsCopied);
    COMMIT;
END;
GO
IF DATABASE_PRINCIPAL_ID('$(AdfName)') IS NULL
    CREATE USER [$(AdfName)] FROM EXTERNAL PROVIDER;
REVOKE SELECT ON SCHEMA::SalesLT FROM [$(AdfName)];
REVOKE SELECT ON SCHEMA::retail FROM [$(AdfName)];
GRANT SELECT ON OBJECT::SalesLT.Customer TO [$(AdfName)];
GRANT SELECT ON OBJECT::SalesLT.Product TO [$(AdfName)];
GRANT SELECT ON OBJECT::retail.Sales TO [$(AdfName)];
GRANT SELECT ON OBJECT::etl.LoadConfig TO [$(AdfName)];
GRANT EXECUTE ON OBJECT::etl.ListLoads TO [$(AdfName)];
GRANT EXECUTE ON OBJECT::etl.GetBounds TO [$(AdfName)];
GRANT EXECUTE ON OBJECT::etl.CommitLoad TO [$(AdfName)];
GO
SELECT SchemaName,TableName,LoadType,LastWatermark FROM etl.LoadConfig;
