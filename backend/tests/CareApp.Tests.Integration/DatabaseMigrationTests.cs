using CareApp.Infrastructure.Persistence;
using CareApp.Tests.Integration.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace CareApp.Tests.Integration;

[Collection(ApiCollection.Name)]
public class DatabaseMigrationTests(CareAppApiFactory factory)
{
    [Fact]
    public async Task Startup_AppliesAllMigrations()
    {
        await using var scope = factory.Services.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<CareAppDbContext>();
        var cancellationToken = TestContext.Current.CancellationToken;

        var applied = await dbContext.Database.GetAppliedMigrationsAsync(cancellationToken);
        var pending = await dbContext.Database.GetPendingMigrationsAsync(cancellationToken);

        Assert.Contains(applied, migration => migration.EndsWith("_InitialCreate", StringComparison.Ordinal));
        Assert.Contains(applied, migration => migration.EndsWith("_AddIdentityAndRefreshTokens", StringComparison.Ordinal));
        Assert.Empty(pending);
    }

    [Fact]
    public async Task Model_HasNoChangesMissingFromMigrations()
    {
        await using var scope = factory.Services.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<CareAppDbContext>();

        Assert.False(dbContext.Database.HasPendingModelChanges());
    }
}
