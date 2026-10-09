using CareApp.Infrastructure;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Testcontainers.PostgreSql;

namespace CareApp.Tests.Integration.Infrastructure;

/// <summary>
/// Hosts the API in memory against a real PostgreSQL instance running in a container.
/// </summary>
public class CareAppApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder("postgres:17-alpine").Build();

    public async ValueTask InitializeAsync()
    {
        await _postgres.StartAsync();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting($"ConnectionStrings:{DependencyInjection.ConnectionStringName}", _postgres.GetConnectionString());
        builder.UseSetting("Database:MigrateOnStartup", "true");

        builder.ConfigureServices(services =>
            services.AddControllers().AddApplicationPart(typeof(CareAppApiFactory).Assembly));
    }

    public override async ValueTask DisposeAsync()
    {
        await base.DisposeAsync();
        await _postgres.DisposeAsync();
        GC.SuppressFinalize(this);
    }
}
