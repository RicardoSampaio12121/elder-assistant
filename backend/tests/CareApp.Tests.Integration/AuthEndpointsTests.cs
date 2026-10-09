using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using CareApp.Application.Auth;
using CareApp.Infrastructure.Persistence;
using CareApp.Tests.Integration.Infrastructure;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace CareApp.Tests.Integration;

[Collection(ApiCollection.Name)]
public class AuthEndpointsTests(CareAppApiFactory factory)
{
    private const string Password = "correct-horse";

    private readonly HttpClient _client = factory.CreateClient();
    private readonly CancellationToken _cancellationToken = TestContext.Current.CancellationToken;

    // Register

    [Fact]
    public async Task Register_WithValidData_Returns201WithUser()
    {
        var email = UniqueEmail();

        var response = await _client.PostAsJsonAsync(
            "/auth/register", new RegisterRequest("Maria Silva", email, Password, "+351912345678"), _cancellationToken);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var user = await response.Content.ReadFromJsonAsync<UserResponse>(_cancellationToken);
        Assert.NotNull(user);
        Assert.NotEqual(Guid.Empty, user.Id);
        Assert.Equal("Maria Silva", user.Name);
        Assert.Equal(email, user.Email);
        Assert.Equal("+351912345678", user.PhoneNumber);
    }

    [Fact]
    public async Task Register_WithoutPhoneNumber_Returns201()
    {
        var response = await _client.PostAsJsonAsync(
            "/auth/register", new RegisterRequest("Maria Silva", UniqueEmail(), Password), _cancellationToken);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var user = await response.Content.ReadFromJsonAsync<UserResponse>(_cancellationToken);
        Assert.Null(user!.PhoneNumber);
    }

    [Fact]
    public async Task Register_DoesNotStorePlainTextPassword()
    {
        var email = UniqueEmail();
        await RegisterAsync(email);

        await using var scope = factory.Services.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<CareAppDbContext>();
        var user = await dbContext.Users.SingleAsync(user => user.Email == email, _cancellationToken);

        Assert.False(string.IsNullOrEmpty(user.PasswordHash));
        Assert.DoesNotContain(Password, user.PasswordHash);
    }

    [Fact]
    public async Task Register_WithPasswordShorterThan8Characters_Returns400()
    {
        var response = await _client.PostAsJsonAsync(
            "/auth/register", new RegisterRequest("Maria Silva", UniqueEmail(), "1234567"), _cancellationToken);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<ValidationProblemDetails>(_cancellationToken);
        Assert.Contains(nameof(RegisterRequest.Password), problem!.Errors.Keys);
    }

    [Fact]
    public async Task Register_WithPasswordOf8Characters_Returns201()
    {
        var response = await _client.PostAsJsonAsync(
            "/auth/register", new RegisterRequest("Maria Silva", UniqueEmail(), "12345678"), _cancellationToken);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task Register_WithInvalidEmail_Returns400()
    {
        var response = await _client.PostAsJsonAsync(
            "/auth/register", new RegisterRequest("Maria Silva", "not-an-email", Password), _cancellationToken);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<ValidationProblemDetails>(_cancellationToken);
        Assert.Contains(nameof(RegisterRequest.Email), problem!.Errors.Keys);
    }

    [Fact]
    public async Task Register_WithDuplicateEmail_Returns409WithClearMessage()
    {
        var email = UniqueEmail();
        await RegisterAsync(email);

        var response = await _client.PostAsJsonAsync(
            "/auth/register", new RegisterRequest("Outra Pessoa", email, "another-password"), _cancellationToken);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
        var problem = await response.Content.ReadFromJsonAsync<ProblemDetails>(_cancellationToken);
        Assert.Equal(409, problem!.Status);
        Assert.Equal("Já existe uma conta registada com este email.", problem.Detail);
    }

    [Fact]
    public async Task Register_WithDuplicateEmailInDifferentCase_Returns409()
    {
        var email = UniqueEmail();
        await RegisterAsync(email);

        var response = await _client.PostAsJsonAsync(
            "/auth/register", new RegisterRequest("Outra Pessoa", email.ToUpperInvariant(), Password), _cancellationToken);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    // Login

    [Fact]
    public async Task Login_WithValidCredentials_ReturnsAccessTokenFor15MinutesAndRefreshTokenFor30Days()
    {
        var email = UniqueEmail();
        await RegisterAsync(email);
        var before = DateTimeOffset.UtcNow;

        var response = await _client.PostAsJsonAsync("/auth/login", new LoginRequest(email, Password), _cancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var tokens = await response.Content.ReadFromJsonAsync<AuthTokensResponse>(_cancellationToken);
        Assert.NotNull(tokens);
        Assert.False(string.IsNullOrWhiteSpace(tokens.RefreshToken));

        var accessToken = new JsonWebToken(tokens.AccessToken);
        Assert.Equal(TimeSpan.FromMinutes(15), accessToken.ValidTo - accessToken.IssuedAt);
        Assert.Equal(accessToken.ValidTo, tokens.AccessTokenExpiresAt.UtcDateTime);
        AssertApproximately(before.AddMinutes(15), tokens.AccessTokenExpiresAt);
        AssertApproximately(before.AddDays(30), tokens.RefreshTokenExpiresAt);
    }

    [Fact]
    public async Task Login_IsCaseInsensitiveForEmail()
    {
        var email = UniqueEmail();
        await RegisterAsync(email);

        var response = await _client.PostAsJsonAsync(
            "/auth/login", new LoginRequest(email.ToUpperInvariant(), Password), _cancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Login_WithWrongPasswordOrUnknownEmail_Returns401WithoutRevealingWhichIsWrong()
    {
        var email = UniqueEmail();
        await RegisterAsync(email);

        var wrongPassword = await _client.PostAsJsonAsync(
            "/auth/login", new LoginRequest(email, "wrong-password"), _cancellationToken);
        var unknownEmail = await _client.PostAsJsonAsync(
            "/auth/login", new LoginRequest(UniqueEmail(), Password), _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, wrongPassword.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, unknownEmail.StatusCode);

        var wrongPasswordProblem = await wrongPassword.Content.ReadFromJsonAsync<ProblemDetails>(_cancellationToken);
        var unknownEmailProblem = await unknownEmail.Content.ReadFromJsonAsync<ProblemDetails>(_cancellationToken);
        Assert.Equal("Email ou palavra-passe inválidos.", wrongPasswordProblem!.Detail);
        Assert.Equal(wrongPasswordProblem.Title, unknownEmailProblem!.Title);
        Assert.Equal(wrongPasswordProblem.Detail, unknownEmailProblem.Detail);
    }

    // Refresh

    [Fact]
    public async Task Refresh_WithValidToken_ReturnsNewPair()
    {
        var tokens = await RegisterAndLoginAsync();

        var response = await _client.PostAsJsonAsync(
            "/auth/refresh", new RefreshTokenRequest(tokens.RefreshToken), _cancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var refreshed = await response.Content.ReadFromJsonAsync<AuthTokensResponse>(_cancellationToken);
        Assert.NotNull(refreshed);
        Assert.NotEqual(tokens.RefreshToken, refreshed.RefreshToken);
        Assert.NotEqual(tokens.AccessToken, refreshed.AccessToken);

        var me = await GetMeAsync(refreshed.AccessToken);
        Assert.Equal(HttpStatusCode.OK, me.StatusCode);
    }

    [Fact]
    public async Task Refresh_WithAlreadyUsedToken_Returns401()
    {
        var tokens = await RegisterAndLoginAsync();
        var first = await _client.PostAsJsonAsync(
            "/auth/refresh", new RefreshTokenRequest(tokens.RefreshToken), _cancellationToken);
        Assert.Equal(HttpStatusCode.OK, first.StatusCode);

        var second = await _client.PostAsJsonAsync(
            "/auth/refresh", new RefreshTokenRequest(tokens.RefreshToken), _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, second.StatusCode);
    }

    [Fact]
    public async Task Refresh_WithConcurrentRequestsForSameToken_IssuesOnlyOnePair()
    {
        var tokens = await RegisterAndLoginAsync();

        var responses = await Task.WhenAll(Enumerable.Range(0, 5).Select(_ => _client.PostAsJsonAsync(
            "/auth/refresh", new RefreshTokenRequest(tokens.RefreshToken), _cancellationToken)));

        Assert.Single(responses, response => response.StatusCode == HttpStatusCode.OK);
        Assert.All(
            responses.Where(response => response.StatusCode != HttpStatusCode.OK),
            response => Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode));
    }

    [Fact]
    public async Task Refresh_WithUnknownToken_Returns401()
    {
        var response = await _client.PostAsJsonAsync(
            "/auth/refresh", new RefreshTokenRequest("not-a-real-refresh-token"), _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Refresh_WithExpiredToken_Returns401()
    {
        var email = UniqueEmail();
        var registered = await RegisterAsync(email);
        var tokens = await LoginAsync(email);

        await using (var scope = factory.Services.CreateAsyncScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<CareAppDbContext>();
            await dbContext.RefreshTokens
                .Where(token => token.UserId == registered.Id)
                .ExecuteUpdateAsync(
                    setters => setters.SetProperty(token => token.ExpiresAt, DateTimeOffset.UtcNow.AddSeconds(-1)),
                    _cancellationToken);
        }

        var response = await _client.PostAsJsonAsync(
            "/auth/refresh", new RefreshTokenRequest(tokens.RefreshToken), _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Refresh_DoesNotAcceptAccessToken()
    {
        var tokens = await RegisterAndLoginAsync();

        var response = await _client.PostAsJsonAsync(
            "/auth/refresh", new RefreshTokenRequest(tokens.AccessToken), _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // Protected endpoints

    [Fact]
    public async Task ProtectedEndpoint_WithValidAccessToken_Returns200()
    {
        var email = UniqueEmail();
        await RegisterAsync(email);
        var tokens = await LoginAsync(email);

        var response = await GetMeAsync(tokens.AccessToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var user = await response.Content.ReadFromJsonAsync<UserResponse>(_cancellationToken);
        Assert.Equal(email, user!.Email);
    }

    [Fact]
    public async Task ProtectedEndpoint_WithoutToken_Returns401()
    {
        var response = await _client.GetAsync("/auth/me", _cancellationToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ProtectedEndpoint_WithMalformedToken_Returns401()
    {
        var response = await GetMeAsync("not-a-jwt");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ProtectedEndpoint_WithRefreshTokenAsBearer_Returns401()
    {
        var tokens = await RegisterAndLoginAsync();

        var response = await GetMeAsync(tokens.RefreshToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ProtectedEndpoint_WithExpiredToken_Returns401()
    {
        var registered = await RegisterAsync(UniqueEmail());
        var token = CreateAccessToken(
            registered.Id, CareAppApiFactory.JwtSigningKey, expiresAt: DateTime.UtcNow.AddMinutes(-1));

        var response = await GetMeAsync(token);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ProtectedEndpoint_WithTokenSignedByAnotherKey_Returns401()
    {
        var registered = await RegisterAsync(UniqueEmail());
        var token = CreateAccessToken(
            registered.Id, "some-other-signing-key-0123456789abcdefgh", expiresAt: DateTime.UtcNow.AddMinutes(5));

        var response = await GetMeAsync(token);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private static string UniqueEmail() => $"cuidador-{Guid.NewGuid():N}@example.com";

    private async Task<UserResponse> RegisterAsync(string email)
    {
        var response = await _client.PostAsJsonAsync(
            "/auth/register", new RegisterRequest("Maria Silva", email, Password), _cancellationToken);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        return (await response.Content.ReadFromJsonAsync<UserResponse>(_cancellationToken))!;
    }

    private async Task<AuthTokensResponse> LoginAsync(string email)
    {
        var response = await _client.PostAsJsonAsync("/auth/login", new LoginRequest(email, Password), _cancellationToken);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        return (await response.Content.ReadFromJsonAsync<AuthTokensResponse>(_cancellationToken))!;
    }

    private async Task<AuthTokensResponse> RegisterAndLoginAsync()
    {
        var email = UniqueEmail();
        await RegisterAsync(email);

        return await LoginAsync(email);
    }

    private async Task<HttpResponseMessage> GetMeAsync(string accessToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "/auth/me");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        return await _client.SendAsync(request, _cancellationToken);
    }

    private static string CreateAccessToken(Guid userId, string signingKey, DateTime expiresAt) =>
        new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = "CareApp",
            Audience = "CareApp",
            IssuedAt = expiresAt.AddMinutes(-15),
            NotBefore = expiresAt.AddMinutes(-15),
            Expires = expiresAt,
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)), SecurityAlgorithms.HmacSha256),
            Claims = new Dictionary<string, object> { [JwtRegisteredClaimNames.Sub] = userId.ToString() },
        });

    private static void AssertApproximately(DateTimeOffset expected, DateTimeOffset actual) =>
        Assert.InRange(actual, expected.AddSeconds(-5), expected.AddMinutes(1));
}
