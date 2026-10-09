using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using CareApp.Application.Auth.Contracts;
using CareApp.Application.CareRecipients.Contracts;
using CareApp.Domain.CareRecipients;
using CareApp.Infrastructure.Persistence;
using CareApp.Tests.Integration.Infrastructure;
using Microsoft.Extensions.DependencyInjection;

namespace CareApp.Tests.Integration;

[Collection(ApiCollection.Name)]
public class CareRecipientsEndpointsTests(CareAppApiFactory factory)
{
    private const string Password = "correct-horse";
    private readonly CancellationToken _cancellationToken = TestContext.Current.CancellationToken;

    [Fact]
    public async Task HappyPath_CreateGetUpdateDelete()
    {
        var client = await AuthenticatedClientAsync();

        // Create
        var createResponse = await client.PostAsJsonAsync(
            "/api/care-recipients",
            new CreateCareRecipientRequest("Avó Maria", new DateOnly(1940, 5, 15), "Some notes"),
            _cancellationToken);

        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        var created = await createResponse.Content.ReadFromJsonAsync<CareRecipientResponse>(_cancellationToken);
        Assert.NotNull(created);
        Assert.NotEqual(Guid.Empty, created.Id);
        Assert.Equal("Avó Maria", created.Name);
        Assert.Equal(new DateOnly(1940, 5, 15), created.DateOfBirth);
        Assert.Equal("Some notes", created.Notes);

        // Get
        var getResponse = await client.GetAsync($"/api/care-recipients/{created.Id}", _cancellationToken);
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
        var fetched = await getResponse.Content.ReadFromJsonAsync<CareRecipientResponse>(_cancellationToken);
        Assert.Equal(created.Id, fetched!.Id);
        Assert.Equal(created.Name, fetched.Name);

        // Update
        var updateResponse = await client.PutAsJsonAsync(
            $"/api/care-recipients/{created.Id}",
            new UpdateCareRecipientRequest("Avó Maria Updated", new DateOnly(1940, 5, 15)),
            _cancellationToken);

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        var updated = await updateResponse.Content.ReadFromJsonAsync<CareRecipientResponse>(_cancellationToken);
        Assert.Equal("Avó Maria Updated", updated!.Name);
        Assert.Null(updated.Notes);

        // Delete
        var deleteResponse = await client.DeleteAsync($"/api/care-recipients/{created.Id}", _cancellationToken);
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        // Get after delete returns 404
        var getAfterDelete = await client.GetAsync($"/api/care-recipients/{created.Id}", _cancellationToken);
        Assert.Equal(HttpStatusCode.NotFound, getAfterDelete.StatusCode);
    }

    [Fact]
    public async Task Get_WithUnknownId_Returns404()
    {
        var client = await AuthenticatedClientAsync();
        var response = await client.GetAsync($"/api/care-recipients/{Guid.NewGuid()}", _cancellationToken);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Update_WithUnknownId_Returns404()
    {
        var client = await AuthenticatedClientAsync();
        var response = await client.PutAsJsonAsync(
            $"/api/care-recipients/{Guid.NewGuid()}",
            new UpdateCareRecipientRequest("Name", new DateOnly(1940, 5, 15)),
            _cancellationToken);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Delete_WithUnknownId_Returns404()
    {
        var client = await AuthenticatedClientAsync();
        var response = await client.DeleteAsync($"/api/care-recipients/{Guid.NewGuid()}", _cancellationToken);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Update_AsCaregiverMember_Returns403()
    {
        var ownerClient = await AuthenticatedClientAsync();
        var (caregiverClient, caregiverId) = await AuthenticatedClientWithIdAsync();

        var created = await CreateAsync(ownerClient, new CreateCareRecipientRequest("Avó Maria", new DateOnly(1940, 5, 15)));

        // Add the caregiver as a non-owner member directly in the DB.
        await using (var scope = factory.Services.CreateAsyncScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<CareAppDbContext>();
            dbContext.CareRecipientMembers.Add(new CareRecipientMember(
                Guid.CreateVersion7(), created.Id, caregiverId, CareRecipientMemberRole.Caregiver, DateTimeOffset.UtcNow));
            await dbContext.SaveChangesAsync(_cancellationToken);
        }

        var response = await caregiverClient.PutAsJsonAsync(
            $"/api/care-recipients/{created.Id}",
            new UpdateCareRecipientRequest("Changed", new DateOnly(1940, 5, 15)),
            _cancellationToken);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Delete_AsCaregiverMember_Returns403()
    {
        var ownerClient = await AuthenticatedClientAsync();
        var (caregiverClient, caregiverId) = await AuthenticatedClientWithIdAsync();

        var created = await CreateAsync(ownerClient, new CreateCareRecipientRequest("Avó Maria", new DateOnly(1940, 5, 15)));

        await using (var scope = factory.Services.CreateAsyncScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<CareAppDbContext>();
            dbContext.CareRecipientMembers.Add(new CareRecipientMember(
                Guid.CreateVersion7(), created.Id, caregiverId, CareRecipientMemberRole.Caregiver, DateTimeOffset.UtcNow));
            await dbContext.SaveChangesAsync(_cancellationToken);
        }

        var response = await caregiverClient.DeleteAsync($"/api/care-recipients/{created.Id}", _cancellationToken);
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task List_ReturnsOnlyOwnRecipients()
    {
        var aliceClient = await AuthenticatedClientAsync();
        var bobClient = await AuthenticatedClientAsync();

        var aliceRecipient = await CreateAsync(aliceClient, new CreateCareRecipientRequest("Alice's Elder", new DateOnly(1940, 5, 15)));
        await CreateAsync(bobClient, new CreateCareRecipientRequest("Bob's Elder", new DateOnly(1945, 3, 20)));

        var aliceList = await ListAsync(aliceClient);
        var bobList = await ListAsync(bobClient);

        Assert.Contains(aliceList, r => r.Id == aliceRecipient.Id);
        Assert.DoesNotContain(aliceList, r => r.Name == "Bob's Elder");
        Assert.DoesNotContain(bobList, r => r.Name == "Alice's Elder");
    }

    [Fact]
    public async Task Create_WithoutAuth_Returns401()
    {
        var client = factory.CreateClient();
        var response = await client.PostAsJsonAsync(
            "/api/care-recipients",
            new CreateCareRecipientRequest("Test", new DateOnly(1940, 5, 15)),
            _cancellationToken);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Create_WithFutureDateOfBirth_Returns400()
    {
        var client = await AuthenticatedClientAsync();
        var response = await client.PostAsJsonAsync(
            "/api/care-recipients",
            new CreateCareRecipientRequest("Test", DateOnly.FromDateTime(DateTime.UtcNow.AddDays(1))),
            _cancellationToken);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private static string UniqueEmail() => $"cuidador-{Guid.NewGuid():N}@example.com";

    private async Task<HttpClient> AuthenticatedClientAsync()
    {
        var (client, _) = await AuthenticatedClientWithIdAsync();
        return client;
    }

    private async Task<(HttpClient client, Guid userId)> AuthenticatedClientWithIdAsync()
    {
        var email = UniqueEmail();
        var registerResponse = await factory.CreateClient().PostAsJsonAsync(
            "/auth/register", new RegisterRequest("Test User", email, Password), _cancellationToken);
        Assert.Equal(HttpStatusCode.Created, registerResponse.StatusCode);
        var user = await registerResponse.Content.ReadFromJsonAsync<UserResponse>(_cancellationToken);

        var loginResponse = await factory.CreateClient().PostAsJsonAsync(
            "/auth/login", new LoginRequest(email, Password), _cancellationToken);
        Assert.Equal(HttpStatusCode.OK, loginResponse.StatusCode);
        var tokens = await loginResponse.Content.ReadFromJsonAsync<AuthTokensResponse>(_cancellationToken);

        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens!.AccessToken);
        return (client, user!.Id);
    }

    private async Task<CareRecipientResponse> CreateAsync(HttpClient client, CreateCareRecipientRequest request)
    {
        var response = await client.PostAsJsonAsync("/api/care-recipients", request, _cancellationToken);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<CareRecipientResponse>(_cancellationToken))!;
    }

    private async Task<List<CareRecipientResponse>> ListAsync(HttpClient client)
    {
        var response = await client.GetAsync("/api/care-recipients", _cancellationToken);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<List<CareRecipientResponse>>(_cancellationToken))!;
    }
}
