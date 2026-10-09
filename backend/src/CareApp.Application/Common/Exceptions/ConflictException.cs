namespace CareApp.Application.Common.Exceptions;

/// <summary>
/// The request conflicts with the current state of a resource (e.g. a duplicate unique value). Mapped to HTTP 409.
/// </summary>
public sealed class ConflictException(string message) : Exception(message);
