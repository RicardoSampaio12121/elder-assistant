using Microsoft.AspNetCore.Identity;

namespace CareApp.Infrastructure.Identity;

/// <summary>
/// An account holder (caregiver). The email doubles as the Identity user name.
/// </summary>
public class User : IdentityUser<Guid>
{
    public string Name { get; set; } = string.Empty;
}
