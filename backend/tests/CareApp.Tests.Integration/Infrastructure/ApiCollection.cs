namespace CareApp.Tests.Integration.Infrastructure;

/// <summary>
/// Shares a single API host and PostgreSQL container across all integration test classes.
/// </summary>
[CollectionDefinition(Name)]
public class ApiCollection : ICollectionFixture<CareAppApiFactory>
{
    public const string Name = "Api";
}
