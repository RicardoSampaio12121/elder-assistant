namespace CareApp.Application.Common.Exceptions;

/// <summary>
/// The requested resource does not exist or the caller is not a member. Mapped to HTTP 404.
/// </summary>
public sealed class NotFoundException(string message) : Exception(message);
