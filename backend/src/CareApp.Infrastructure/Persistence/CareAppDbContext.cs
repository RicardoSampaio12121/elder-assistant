using CareApp.Domain.CareRecipients;
using CareApp.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace CareApp.Infrastructure.Persistence;

public class CareAppDbContext(DbContextOptions<CareAppDbContext> options)
    : IdentityUserContext<User, Guid>(options)
{
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<CareRecipient> CareRecipients => Set<CareRecipient>();
    public DbSet<CareRecipientMember> CareRecipientMembers => Set<CareRecipientMember>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.ApplyConfigurationsFromAssembly(typeof(CareAppDbContext).Assembly);
    }
}
