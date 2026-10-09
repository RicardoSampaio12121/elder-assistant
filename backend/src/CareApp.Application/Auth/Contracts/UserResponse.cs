namespace CareApp.Application.Auth.Contracts;

public sealed record UserResponse(Guid Id, string Name, string Email, string? PhoneNumber);
