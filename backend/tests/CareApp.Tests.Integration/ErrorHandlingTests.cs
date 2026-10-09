using System.Net;
using System.Net.Http.Json;
using CareApp.Tests.Integration.Infrastructure;
using Microsoft.AspNetCore.Mvc;

namespace CareApp.Tests.Integration;

[Collection(ApiCollection.Name)]
public class ErrorHandlingTests(CareAppApiFactory factory)
{
    [Fact]
    public async Task UnhandledException_ReturnsInternalServerErrorProblemDetails()
    {
        using var client = factory.CreateClient();
        var cancellationToken = TestContext.Current.CancellationToken;

        var response = await client.GetAsync("/test/throw", cancellationToken);

        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);

        var problem = await response.Content.ReadFromJsonAsync<ProblemDetails>(cancellationToken);
        Assert.NotNull(problem);
        Assert.Equal(500, problem.Status);
        Assert.DoesNotContain("internal detail", problem.Detail ?? string.Empty);
    }

    [Fact]
    public async Task UnknownRoute_ReturnsNotFoundProblemDetails()
    {
        using var client = factory.CreateClient();
        var cancellationToken = TestContext.Current.CancellationToken;

        var response = await client.GetAsync("/does-not-exist", cancellationToken);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
    }
}
