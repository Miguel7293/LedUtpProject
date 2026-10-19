var builder = WebApplication.CreateBuilder(args);
builder.Services.AddHttpClient("catalog", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["CatalogApiUrl"] ?? "http://localhost:8000");
    client.Timeout = TimeSpan.FromSeconds(15);
});
var app = builder.Build();
app.UseDefaultFiles();
app.UseStaticFiles();
app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "catalog-web" }));
app.MapGet("/api/products", async (IHttpClientFactory factory, CancellationToken cancellation) =>
{
    try
    {
        using var response = await factory.CreateClient("catalog").GetAsync("/api/products", cancellation);
        if (!response.IsSuccessStatusCode) return Results.Problem("El catálogo no está disponible.", statusCode: 503);
        var json = await response.Content.ReadAsStringAsync(cancellation);
        return Results.Content(json, "application/json");
    }
    catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
    {
        return Results.Problem("No se pudo conectar con el catálogo. Intenta nuevamente.", statusCode: 503);
    }
});
app.Run();
