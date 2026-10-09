namespace CareApp.Application.Auth.Contracts;

public sealed record RegisterRequest(string Name, string Email, string Password, string? PhoneNumber = null);
