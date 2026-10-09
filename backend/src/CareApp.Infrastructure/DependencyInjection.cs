using CareApp.Application.Auth;
using CareApp.Application.CareRecipients;
using CareApp.Infrastructure.CareRecipients;
using CareApp.Infrastructure.Identity;
using CareApp.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace CareApp.Infrastructure;

public static class DependencyInjection
{
    public const string ConnectionStringName = "CareApp";

    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        // The connection string is resolved lazily so that hosts (e.g. integration tests)
        // can override configuration after the services are registered.
        services.AddDbContext<CareAppDbContext>((serviceProvider, options) =>
        {
            var connectionString = serviceProvider.GetRequiredService<IConfiguration>()
                .GetConnectionString(ConnectionStringName)
                ?? throw new InvalidOperationException(
                    $"Connection string '{ConnectionStringName}' is not configured.");

            options.UseNpgsql(connectionString);
        });

        services.AddHealthChecks()
            .AddDbContextCheck<CareAppDbContext>();

        services.AddIdentityServices();

        return services;
    }

    private static void AddIdentityServices(this IServiceCollection services)
    {
        services.TryAddSingleton(TimeProvider.System);

        services.AddOptions<JwtOptions>()
            .BindConfiguration(JwtOptions.SectionName)
            .Validate(options => !string.IsNullOrWhiteSpace(options.Issuer), "Jwt:Issuer is not configured.")
            .Validate(options => !string.IsNullOrWhiteSpace(options.Audience), "Jwt:Audience is not configured.")
            .Validate(
                options => options.SigningKey.Length >= JwtOptions.SigningKeyMinLength,
                $"Jwt:SigningKey must be at least {JwtOptions.SigningKeyMinLength} characters long.")
            .ValidateOnStart();

        services.AddIdentityCore<User>(options =>
            {
                options.User.RequireUniqueEmail = true;
                // The email is used as the user name; any character valid in an email is allowed.
                options.User.AllowedUserNameCharacters = string.Empty;

                // Length is the only password rule (NIST SP 800-63B); it must match RegisterRequestValidator.
                options.Password.RequiredLength = RegisterRequestValidator.PasswordMinLength;
                options.Password.RequireDigit = false;
                options.Password.RequireLowercase = false;
                options.Password.RequireUppercase = false;
                options.Password.RequireNonAlphanumeric = false;
                options.Password.RequiredUniqueChars = 1;
            })
            .AddEntityFrameworkStores<CareAppDbContext>();

        services.AddScoped<TokenService>();
        services.AddScoped<RefreshTokenManager>();
        services.AddScoped<IAuthService, IdentityAuthService>();

        services.AddScoped<CareRecipientManager>();
        services.AddScoped<ICareRecipientService, CareRecipientService>();
    }

    public static async Task MigrateDatabaseAsync(this IServiceProvider services, CancellationToken cancellationToken = default)
    {
        await using var scope = services.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<CareAppDbContext>();

        await dbContext.Database.MigrateAsync(cancellationToken);
    }
}
