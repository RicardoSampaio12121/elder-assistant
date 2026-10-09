using Microsoft.AspNetCore.Mvc;

namespace CareApp.Tests.Integration.Infrastructure;

/// <summary>
/// Test-only endpoint used to exercise the unhandled exception pipeline.
/// </summary>
[ApiController]
[Route("test/throw")]
public class ThrowingController : ControllerBase
{
    [HttpGet]
    public IActionResult Get() => throw new InvalidOperationException("Boom: internal detail that must not leak.");
}
