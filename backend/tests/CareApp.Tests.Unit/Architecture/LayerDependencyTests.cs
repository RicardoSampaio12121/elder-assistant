using System.Reflection;
using System.Xml.Linq;
using CareApp.Application;
using CareApp.Domain.Exceptions;

namespace CareApp.Tests.Unit.Architecture;

/// <summary>
/// Enforces the Clean Architecture dependency rule: Api → Infrastructure → Application → Domain.
/// </summary>
public class LayerDependencyTests
{
    private static readonly Assembly DomainAssembly = typeof(DomainException).Assembly;
    private static readonly Assembly ApplicationAssembly = typeof(DependencyInjection).Assembly;

    public static TheoryData<string, string[]> AllowedProjectReferences => new()
    {
        { "CareApp.Domain", [] },
        { "CareApp.Application", ["CareApp.Domain"] },
        { "CareApp.Infrastructure", ["CareApp.Application"] },
        { "CareApp.Api", ["CareApp.Application", "CareApp.Infrastructure"] },
    };

    [Theory]
    [MemberData(nameof(AllowedProjectReferences))]
    public void Project_DeclaresOnlyAllowedProjectReferences(string project, string[] expected)
    {
        var csproj = Path.Combine(FindBackendRoot(), "src", project, $"{project}.csproj");

        var references = XDocument.Load(csproj)
            .Descendants("ProjectReference")
            .Select(element => Path.GetFileNameWithoutExtension(
                element.Attribute("Include")!.Value.Replace('\\', Path.DirectorySeparatorChar)))
            .Order()
            .ToArray();

        Assert.Equal(expected, references);
    }

    [Fact]
    public void Domain_HasNoDependencies()
    {
        var references = DomainAssembly.GetReferencedAssemblies()
            .Select(reference => reference.Name!)
            .Where(name => !name.StartsWith("System", StringComparison.Ordinal)
                && name != "netstandard"
                && name != "mscorlib");

        Assert.Empty(references);
    }

    [Fact]
    public void Application_DoesNotReferenceOuterLayers()
    {
        var references = ApplicationAssembly.GetReferencedAssemblies()
            .Select(reference => reference.Name!)
            .Where(name => name.StartsWith("CareApp.", StringComparison.Ordinal));

        Assert.All(references, name => Assert.Equal("CareApp.Domain", name));
    }

    private static string FindBackendRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null && !File.Exists(Path.Combine(directory.FullName, "CareApp.sln")))
        {
            directory = directory.Parent;
        }

        return directory?.FullName
            ?? throw new InvalidOperationException("Could not locate CareApp.sln from the test output directory.");
    }
}
