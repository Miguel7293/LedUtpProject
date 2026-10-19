SELECT SchemaName,TableName,LoadType,LastWatermark FROM etl.LoadConfig;
SELECT RunId,SchemaName,TableName,LoadType,RowsCopied,LowerWatermark,UpperWatermark,CompletedAt
FROM etl.LoadHistory ORDER BY CompletedAt,SchemaName,TableName;
