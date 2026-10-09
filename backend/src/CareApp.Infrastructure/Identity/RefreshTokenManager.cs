using CareApp.Application.Common.Exceptions;
using CareApp.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CareApp.Infrastructure.Identity;

internal sealed class RefreshTokenManager(CareAppDbContext dbContext)
{
    private const string InvalidRefreshTokenMessage = "The session is invalid or has expired. Please sign in again.";

    /// <summary>
    /// Atomically revokes the old refresh token and issues a new one.
    /// </summary>
    /// <exception cref="AuthenticationFailedException">The token is unknown, expired or already revoked.</exception>
    public async Task<(User user, string newRawToken)> RotateAsync(
        string oldTokenHash,
        DateTimeOffset now,
        DateTimeOffset newTokenExpiresAt,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var existing = await dbContext.RefreshTokens
            .AsNoTracking()
            .Include(t => t.User)
            .SingleOrDefaultAsync(t => t.TokenHash == oldTokenHash, cancellationToken);

        if (existing is null || existing.RevokedAt is not null || existing.ExpiresAt <= now)
            throw new AuthenticationFailedException(InvalidRefreshTokenMessage);

        var revoked = await dbContext.RefreshTokens
            .Where(t => t.Id == existing.Id && t.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.RevokedAt, now), cancellationToken);

        if (revoked == 0)
            throw new AuthenticationFailedException(InvalidRefreshTokenMessage);

        var newRawToken = TokenService.GenerateRefreshToken();
        dbContext.RefreshTokens.Add(new RefreshToken(
            Guid.CreateVersion7(),
            existing.UserId,
            TokenService.HashRefreshToken(newRawToken),
            now,
            newTokenExpiresAt));
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return (existing.User, newRawToken);
    }

    public async Task<string> IssueAsync(
        Guid userId,
        DateTimeOffset now,
        DateTimeOffset expiresAt,
        CancellationToken cancellationToken)
    {
        var rawToken = TokenService.GenerateRefreshToken();
        dbContext.RefreshTokens.Add(new RefreshToken(
            Guid.CreateVersion7(),
            userId,
            TokenService.HashRefreshToken(rawToken),
            now,
            expiresAt));
        await dbContext.SaveChangesAsync(cancellationToken);
        return rawToken;
    }
}
