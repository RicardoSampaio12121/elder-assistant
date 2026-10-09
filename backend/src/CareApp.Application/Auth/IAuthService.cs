using CareApp.Application.Auth.Contracts;

namespace CareApp.Application.Auth;

/// <summary>
/// Account registration and token-based authentication for caregivers.
/// </summary>
public interface IAuthService
{
    /// <exception cref="Common.Exceptions.ConflictException">The email is already registered.</exception>
    Task<UserResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);

    /// <exception cref="Common.Exceptions.AuthenticationFailedException">The credentials are invalid.</exception>
    Task<AuthTokensResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);

    /// <summary>
    /// Exchanges a valid refresh token for a new token pair. The presented refresh token is revoked.
    /// </summary>
    /// <exception cref="Common.Exceptions.AuthenticationFailedException">The refresh token is unknown, expired or already used.</exception>
    Task<AuthTokensResponse> RefreshAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default);

    Task<UserResponse?> GetUserAsync(Guid userId, CancellationToken cancellationToken = default);
}
