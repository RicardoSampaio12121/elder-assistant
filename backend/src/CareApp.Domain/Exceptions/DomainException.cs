namespace CareApp.Domain.Exceptions;

/// <summary>
/// Base type for violations of domain rules. Concrete domain exceptions derive from it.
/// </summary>
public abstract class DomainException : Exception
{
    protected DomainException(string message)
        : base(message)
    {
    }

    protected DomainException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}
