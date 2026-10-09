namespace CareApp.Application.CareRecipients.Contracts;

public sealed record CareRecipientResponse(Guid Id, string Name, DateOnly DateOfBirth, string? Notes, DateTimeOffset CreatedAt);
