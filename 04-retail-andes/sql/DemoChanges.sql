-- Cambios únicamente sobre datos ficticios. La segunda ejecución no añade cambios.
IF NOT EXISTS (SELECT 1 FROM retail.Sales WHERE SaleId=4)
BEGIN
    BEGIN TRANSACTION;
    UPDATE retail.Sales SET Quantity=3,UpdatedAt=SYSUTCDATETIME() WHERE SaleId=1;
    INSERT retail.Sales(SaleId,ProductName,Quantity,UnitPrice)
    VALUES(4,N'Agenda Arequipa',2,32.50);
    COMMIT;
END;
SELECT SaleId,ProductName,Quantity,UnitPrice,UpdatedAt FROM retail.Sales ORDER BY SaleId;
