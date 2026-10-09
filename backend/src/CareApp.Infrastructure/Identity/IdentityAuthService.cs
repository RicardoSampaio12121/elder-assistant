using CareApp.Application.Auth;
using CareApp.Application.Common.Exceptions;
using CareApp.Infrastructure.Persistence;
using FluentValidation;
using FluentValidation.Results;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Npgsql;

namespace CareApp.Infrastructure.Identity;

internal sealed class IdentityAuthService(
    UserManager<User> userManager,
    CareAppDbContext dbContext,
    TokenService tokenService,
    IOptions<JwtOptions> jwtOptions,
    TimeProvider timeProvider) : IAuthService
{
    private const string DuplicateEmailMessage = "Já existe uma conta registada com este email.";
    private const string InvalidCredentialsMessage = "Email ou palavra-passe inválidos.";
    private const string InvalidRefreshTokenMessage = "A sessão é inválida ou expirou. Inicie sessão novamente.";

    public async Task<UserResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        if (await userManager.FindByEmailAsync(request.Email) is not null)
        {
            throw new ConflictException(DuplicateEmailMessage);
        }

        var user = new User
        {
            UserName = request.Email,
            Email = request.Email,
            Name = request.Name.Trim(),
            PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim(),
        };

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
            userManager.PasswordHasher.HashPassword(new User(), request.Password);
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
        var tokenHash = TokenService.HashRefreshToken(request.RefreshToken);
        var now = timeProvider.GetUtcNow();

        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var refreshToken = await dbContext.RefreshTokens
            .AsNoTracking()
            .Include(token => token.User)
            .SingleOrDefaultAsync(token => token.TokenHash == tokenHash, cancellationToken);

        if (refreshToken is null || refreshToken.RevokedAt is not null || refreshToken.ExpiresAt <= now)
        {
            throw new AuthenticationFailedException(InvalidRefreshTokenMessage);
        }

        // Revoke with a conditional update so that concurrent requests with the same token issue at most one new pair.
        var revoked = await dbContext.RefreshTokens
            .Where(token => token.Id == refreshToken.Id && token.RevokedAt == null)
            .ExecuteUpdateAsync(setters => setters.SetProperty(token => token.RevokedAt, now), cancellationToken);

        if (revoked == 0)
        {
            throw new AuthenticationFailedException(InvalidRefreshTokenMessage);
        }

        var tokens = await IssueTokensAsync(refreshToken.User, cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return tokens;
    }

    public async Task<UserResponse?> GetUserAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var user = await userManager.FindByIdAsync(userId.ToString());

        return user is null ? null : ToResponse(user);
    }

    private async Task<AuthTokensResponse> IssueTokensAsync(User user, CancellationToken cancellationToken)
    {
        var (accessToken, accessTokenExpiresAt) = tokenService.CreateAccessToken(user);

        var refreshToken = TokenService.GenerateRefreshToken();
        var now = timeProvider.GetUtcNow();
        var refreshTokenExpiresAt = now.Add(jwtOptions.Value.RefreshTokenLifetime);

        dbContext.RefreshTokens.Add(new RefreshToken
        {
            Id = Guid.CreateVersion7(),
            UserId = user.Id,
            TokenHash = TokenService.HashRefreshToken(refreshToken),
            CreatedAt = now,
            ExpiresAt = refreshTokenExpiresAt,
        });
        await dbContext.SaveChangesAsync(cancellationToken);

        return new AuthTokensResponse(accessToken, accessTokenExpiresAt, refreshToken, refreshTokenExpiresAt);
    }

    private static UserResponse ToResponse(User user) => new(user.Id, user.Name, user.Email!, user.PhoneNumber);
}
