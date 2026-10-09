using CareApp.Application.Auth;
using CareApp.Application.Auth.Contracts;
using CareApp.Application.Common.Exceptions;
using FluentValidation;
using FluentValidation.Results;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Npgsql;

namespace CareApp.Infrastructure.Identity;

internal sealed class IdentityAuthService(
    UserManager<User> userManager,
    RefreshTokenManager refreshTokenManager,
    TokenService tokenService,
    IOptions<JwtOptions> jwtOptions,
    TimeProvider timeProvider) : IAuthService
{
    private const string DuplicateEmailMessage = "An account with this email already exists.";
    private const string InvalidCredentialsMessage = "Invalid email or password.";

    public async Task<UserResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        if (await userManager.FindByEmailAsync(request.Email) is not null)
        {
            throw new ConflictException(DuplicateEmailMessage);
        }

        var user = new User(
            request.Email,
            request.Name.Trim(),
            string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim());

        IdentityResult result;
        try
        {
            result = await userManager.CreateAsync(user, request.Password);
        }
        catch (DbUpdateException exception)
            when (exception.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // Lost a race against a concurrent registration with the same email.
            throw new ConflictException(DuplicateEmailMessage);
        }

        if (!result.Succeeded)
        {
            if (result.Errors.Any(error => error.Code is nameof(IdentityErrorDescriber.DuplicateEmail)
                or nameof(IdentityErrorDescriber.DuplicateUserName)))
            {
                throw new ConflictException(DuplicateEmailMessage);
            }

            throw new ValidationException(result.Errors.Select(error => new ValidationFailure(
                error.Code.StartsWith("Password", StringComparison.Ordinal)
                    ? nameof(RegisterRequest.Password)
                    : nameof(RegisterRequest.Email),
                error.Description)));
        }

        return ToResponse(user);
    }

    public async Task<AuthTokensResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        var user = await userManager.FindByEmailAsync(request.Email);
        if (user is null)
        {
            // Hash anyway so that response times do not reveal whether the email is registered.
            userManager.PasswordHasher.HashPassword(new User(request.Email, string.Empty), request.Password);
            throw new AuthenticationFailedException(InvalidCredentialsMessage);
        }

        if (!await userManager.CheckPasswordAsync(user, request.Password))
        {
            throw new AuthenticationFailedException(InvalidCredentialsMessage);
        }

        return await IssueTokensAsync(user, cancellationToken);
    }

    public async Task<AuthTokensResponse> RefreshAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default)
    {
        var oldTokenHash = TokenService.HashRefreshToken(request.RefreshToken);
        var now = timeProvider.GetUtcNow();
        var expiresAt = now.Add(jwtOptions.Value.RefreshTokenLifetime);

        var (user, newRawRefreshToken) = await refreshTokenManager.RotateAsync(oldTokenHash, now, expiresAt, cancellationToken);
        var (accessToken, accessTokenExpiresAt) = tokenService.CreateAccessToken(user);

        return new AuthTokensResponse(accessToken, accessTokenExpiresAt, newRawRefreshToken, expiresAt);
    }

    public async Task<UserResponse?> GetUserAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var user = await userManager.FindByIdAsync(userId.ToString());
        return user is null ? null : ToResponse(user);
    }

    private async Task<AuthTokensResponse> IssueTokensAsync(User user, CancellationToken cancellationToken)
    {
        var (accessToken, accessTokenExpiresAt) = tokenService.CreateAccessToken(user);
        var now = timeProvider.GetUtcNow();
        var expiresAt = now.Add(jwtOptions.Value.RefreshTokenLifetime);
        var rawRefreshToken = await refreshTokenManager.IssueAsync(user.Id, now, expiresAt, cancellationToken);

        return new AuthTokensResponse(accessToken, accessTokenExpiresAt, rawRefreshToken, expiresAt);
    }

    private static UserResponse ToResponse(User user) => new(user.Id, user.Name, user.Email!, user.PhoneNumber);
}
