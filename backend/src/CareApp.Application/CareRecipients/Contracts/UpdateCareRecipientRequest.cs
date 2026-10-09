namespace CareApp.Application.CareRecipients.Contracts;

public sealed record UpdateCareRecipientRequest(string Name, DateOnly DateOfBirth, string? Notes = null);
