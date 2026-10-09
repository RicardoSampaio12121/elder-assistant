namespace CareApp.Application.Auth;

public sealed record RegisterRequest(string Name, string Email, string Password, string? PhoneNumber = null);

public sealed record LoginRequest(string Email, string Password);

public sealed record RefreshTokenRequest(string RefreshToken);

public sealed record UserResponse(Guid Id, string Name, string Email, string? PhoneNumber);

public sealed record AuthTokensResponse(
    string AccessToken,
    DateTimeOffset AccessTokenExpiresAt,
    string RefreshToken,
    DateTimeOffset RefreshTokenExpiresAt);
