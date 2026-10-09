using System.Net;
using CareApp.Tests.Integration.Infrastructure;

namespace CareApp.Tests.Integration;

[Collection(ApiCollection.Name)]
public class HealthEndpointTests(CareAppApiFactory factory)
{
    [Fact]
    public async Task GetHealth_WhenDatabaseIsReachable_ReturnsOkHealthy()
    {
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/health", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Healthy", await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken));
    }
}
