namespace CareApp.Application.Common.Exceptions;

/// <summary>
/// The caller does not have permission to perform the requested action. Mapped to HTTP 403.
/// </summary>
public sealed class ForbiddenException(string message) : Exception(message);
