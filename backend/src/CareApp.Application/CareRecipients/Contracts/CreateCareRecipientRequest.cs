namespace CareApp.Application.CareRecipients.Contracts;

public sealed record CreateCareRecipientRequest(string Name, DateOnly DateOfBirth, string? Notes = null);
