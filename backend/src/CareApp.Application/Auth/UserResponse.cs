namespace CareApp.Application.Auth;

public sealed record UserResponse(Guid Id, string Name, string Email, string? PhoneNumber);
