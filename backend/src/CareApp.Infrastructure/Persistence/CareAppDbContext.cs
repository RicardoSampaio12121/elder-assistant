using CareApp.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace CareApp.Infrastructure.Persistence;

public class CareAppDbContext(DbContextOptions<CareAppDbContext> options)
    : IdentityUserContext<User, Guid>(options)
{
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.ApplyConfigurationsFromAssembly(typeof(CareAppDbContext).Assembly);
    }
}
