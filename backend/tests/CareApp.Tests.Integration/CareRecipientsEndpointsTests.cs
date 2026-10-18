using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using CareApp.Application.Auth.Contracts;
using CareApp.Application.CareRecipients.Contracts;
using CareApp.Tests.Integration.Infrastructure;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace CareApp.Tests.Integration;

[Collection(ApiCollection.Name)]
public class CareRecipientsEndpointsTests(CareAppApiFactory factory)
{
    private const string Password = "correct-horse";

    private static readonly DateOnly DateOfBirth = new(1945, 3, 10);

    private readonly HttpClient _client = factory.CreateClient();
    private readonly CancellationToken _cancellationToken = TestContext.Current.CancellationToken;

    // Create

    [Fact]
    public async Task Create_WithValidData_Returns201WithRecipient()
    {
        var token = await RegisterAndGetTokenAsync();

        var response = await PostAsync(token, new CreateCareRecipientRequest("Avó Maria", DateOfBirth, "Diabética"));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var dto = await response.Content.ReadFromJsonAsync<CareRecipientResponse>(_cancellationToken);
        Assert.NotNull(dto);
        Assert.NotEqual(Guid.Empty, dto.Id);
        Assert.Equal("Avó Maria", dto.Name);
        Assert.Equal(DateOfBirth, dto.DateOfBirth);
        Assert.Equal("Diabética", dto.Notes);
        Assert.True(dto.CreatedAt > DateTimeOffset.UtcNow.AddMinutes(-1));
    }

    [Fact]
    public async Task Create_WithoutNotes_Returns201()
    {
        var token = await RegisterAndGetTokenAsync();

        var response = await PostAsync(token, new CreateCareRecipientRequest("Avó Maria", DateOfBirth));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var dto = await response.Content.ReadFromJsonAsync<CareRecipientResponse>(_cancellationToken);
        Assert.Null(dto!.Notes);
    }

    [Fact]
    public async Task Create_WithoutToken_Returns401()
    {
        var response = await _client.PostAsJsonAsync(
            "/api/care-recipients", new CreateCareRecipientRequest("Avó Maria", DateOfBirth), _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Create_WithEmptyName_Returns400()
    {
        var token = await RegisterAndGetTokenAsync();

        var response = await PostAsync(token, new CreateCareRecipientRequest("", DateOfBirth));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<ValidationProblemDetails>(_cancellationToken);
        Assert.Contains(nameof(CreateCareRecipientRequest.Name), problem!.Errors.Keys);
    }

    [Fact]
    public async Task Create_WithFutureDateOfBirth_Returns400()
    {
        var token = await RegisterAndGetTokenAsync();
        var future = DateOnly.FromDateTime(DateTime.Today.AddDays(1));

        var response = await PostAsync(token, new CreateCareRecipientRequest("Avó Maria", future));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<ValidationProblemDetails>(_cancellationToken);
        Assert.Contains(nameof(CreateCareRecipientRequest.DateOfBirth), problem!.Errors.Keys);
    }

    // List

    [Fact]
    public async Task List_ReturnsOnlyCallerRecipients()
    {
        var tokenA = await RegisterAndGetTokenAsync();
        var tokenB = await RegisterAndGetTokenAsync();

        await PostAsync(tokenA, new CreateCareRecipientRequest("Recipient A1", DateOfBirth));
        await PostAsync(tokenA, new CreateCareRecipientRequest("Recipient A2", DateOfBirth));
        await PostAsync(tokenB, new CreateCareRecipientRequest("Recipient B1", DateOfBirth));

        var response = await GetAsync(tokenA, "/api/care-recipients");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await response.Content.ReadFromJsonAsync<IReadOnlyList<CareRecipientResponse>>(_cancellationToken);
        Assert.NotNull(list);
        Assert.All(list, r => Assert.True(r.Name is "Recipient A1" or "Recipient A2"));
        Assert.DoesNotContain(list, r => r.Name == "Recipient B1");
    }

    [Fact]
    public async Task List_WithoutToken_Returns401()
    {
        var response = await _client.GetAsync("/api/care-recipients", _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // Get by ID

    [Fact]
    public async Task GetById_WithValidId_Returns200()
    {
        var token = await RegisterAndGetTokenAsync();
        var created = await CreateRecipientAsync(token, "Avó Maria");

        var response = await GetAsync(token, $"/api/care-recipients/{created.Id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var dto = await response.Content.ReadFromJsonAsync<CareRecipientResponse>(_cancellationToken);
        Assert.Equal(created.Id, dto!.Id);
    }

    [Fact]
    public async Task GetById_WithUnknownId_Returns404()
    {
        var token = await RegisterAndGetTokenAsync();

        var response = await GetAsync(token, $"/api/care-recipients/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetById_WhenNotMember_Returns404()
    {
        var tokenA = await RegisterAndGetTokenAsync();
        var tokenB = await RegisterAndGetTokenAsync();
        var created = await CreateRecipientAsync(tokenA, "Avó Maria");

        var response = await GetAsync(tokenB, $"/api/care-recipients/{created.Id}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // Update

    [Fact]
    public async Task Update_AsOwner_Returns200WithUpdatedData()
    {
        var token = await RegisterAndGetTokenAsync();
        var created = await CreateRecipientAsync(token, "Old Name");

        var response = await PutAsync(token, $"/api/care-recipients/{created.Id}",
            new UpdateCareRecipientRequest("New Name", new DateOnly(1940, 1, 1), "Updated notes"));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var dto = await response.Content.ReadFromJsonAsync<CareRecipientResponse>(_cancellationToken);
        Assert.Equal("New Name", dto!.Name);
        Assert.Equal(new DateOnly(1940, 1, 1), dto.DateOfBirth);
        Assert.Equal("Updated notes", dto.Notes);
    }

    [Fact]
    public async Task Update_WithUnknownId_Returns404()
    {
        var token = await RegisterAndGetTokenAsync();

        var response = await PutAsync(token, $"/api/care-recipients/{Guid.NewGuid()}",
            new UpdateCareRecipientRequest("Name", DateOfBirth));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Update_WithoutToken_Returns401()
    {
        var token = await RegisterAndGetTokenAsync();
        var created = await CreateRecipientAsync(token, "Avó Maria");

        using var request = new HttpRequestMessage(HttpMethod.Put, $"/api/care-recipients/{created.Id}");
        request.Content = JsonContent.Create(new UpdateCareRecipientRequest("New Name", DateOfBirth));
        var response = await _client.SendAsync(request, _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // Delete

    [Fact]
    public async Task Delete_AsOwner_Returns204()
    {
        var token = await RegisterAndGetTokenAsync();
        var created = await CreateRecipientAsync(token, "Avó Maria");

        var response = await DeleteAsync(token, $"/api/care-recipients/{created.Id}");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        var getAfterDelete = await GetAsync(token, $"/api/care-recipients/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getAfterDelete.StatusCode);
    }

    [Fact]
    public async Task Delete_WithUnknownId_Returns404()
    {
        var token = await RegisterAndGetTokenAsync();

        var response = await DeleteAsync(token, $"/api/care-recipients/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Delete_WhenNotMember_Returns404()
    {
        var tokenA = await RegisterAndGetTokenAsync();
        var tokenB = await RegisterAndGetTokenAsync();
        var created = await CreateRecipientAsync(tokenA, "Avó Maria");

        var response = await DeleteAsync(tokenB, $"/api/care-recipients/{created.Id}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Delete_WithoutToken_Returns401()
    {
        var token = await RegisterAndGetTokenAsync();
        var created = await CreateRecipientAsync(token, "Avó Maria");

        using var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/care-recipients/{created.Id}");
        var response = await _client.SendAsync(request, _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // Happy path: create → get → update → delete

    [Fact]
    public async Task HappyPath_CreateGetUpdateDelete()
    {
        var token = await RegisterAndGetTokenAsync();

        var created = await CreateRecipientAsync(token, "Avó Maria");
        Assert.NotEqual(Guid.Empty, created.Id);

        var fetched = await GetAsync(token, $"/api/care-recipients/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, fetched.StatusCode);

        var updated = await PutAsync(token, $"/api/care-recipients/{created.Id}",
            new UpdateCareRecipientRequest("Avó Maria Actualizada", new DateOnly(1940, 5, 20)));
        Assert.Equal(HttpStatusCode.OK, updated.StatusCode);

        var deleted = await DeleteAsync(token, $"/api/care-recipients/{created.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);

        var afterDelete = await GetAsync(token, $"/api/care-recipients/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, afterDelete.StatusCode);
    }

    private static string UniqueEmail() => $"cuidador-{Guid.NewGuid():N}@example.com";

    private async Task<string> RegisterAndGetTokenAsync()
    {
        var email = UniqueEmail();
        var registerResponse = await _client.PostAsJsonAsync(
            "/auth/register", new Application.Auth.Contracts.RegisterRequest("Cuidador", email, Password), _cancellationToken);
        Assert.Equal(HttpStatusCode.Created, registerResponse.StatusCode);

        var loginResponse = await _client.PostAsJsonAsync(
            "/auth/login", new Application.Auth.Contracts.LoginRequest(email, Password), _cancellationToken);
        Assert.Equal(HttpStatusCode.OK, loginResponse.StatusCode);

        var tokens = await loginResponse.Content.ReadFromJsonAsync<AuthTokensResponse>(_cancellationToken);
        return tokens!.AccessToken;
    }

    private async Task<CareRecipientResponse> CreateRecipientAsync(string token, string name)
    {
        var response = await PostAsync(token, new CreateCareRecipientRequest(name, DateOfBirth));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<CareRecipientResponse>(_cancellationToken))!;
    }

    private async Task<HttpResponseMessage> PostAsync(string token, CreateCareRecipientRequest request)
    {
        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "/api/care-recipients");
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        httpRequest.Content = JsonContent.Create(request);
        return await _client.SendAsync(httpRequest, _cancellationToken);
    }

    private async Task<HttpResponseMessage> GetAsync(string token, string url)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await _client.SendAsync(request, _cancellationToken);
    }

    private async Task<HttpResponseMessage> PutAsync(string token, string url, UpdateCareRecipientRequest body)
    {
        using var request = new HttpRequestMessage(HttpMethod.Put, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Content = JsonContent.Create(body);
        return await _client.SendAsync(request, _cancellationToken);
    }

    private async Task<HttpResponseMessage> DeleteAsync(string token, string url)
    {
        using var request = new HttpRequestMessage(HttpMethod.Delete, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await _client.SendAsync(request, _cancellationToken);
    }
}
