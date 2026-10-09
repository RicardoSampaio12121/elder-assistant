namespace CareApp.Application.Common.Exceptions;

/// <summary>
/// The presented credentials or tokens could not be authenticated. Mapped to HTTP 401.
/// The message must not reveal which part of the credentials was wrong.
/// </summary>
public sealed class AuthenticationFailedException(string message) : Exception(message);
