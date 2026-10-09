namespace CareApp.Application.Auth;

public sealed record RegisterRequest(string Name, string Email, string Password, string? PhoneNumber = null);
