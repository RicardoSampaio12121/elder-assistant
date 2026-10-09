using Microsoft.AspNetCore.Identity;

namespace CareApp.Infrastructure.Identity;

/// <summary>
/// An account holder (caregiver). The email doubles as the Identity user name.
/// </summary>
public class User : IdentityUser<Guid>
{
    protected User() { }

    public User(string email, string name, string? phoneNumber = null)
    {
        UserName = email;
        Email = email;
        Name = name;
        PhoneNumber = phoneNumber;
    }

    public string Name { get; set; } = string.Empty;
}
