using CareApp.Application.Auth;

namespace CareApp.Tests.Unit.Application.Auth;

public class RegisterRequestValidatorTests
{
    private readonly RegisterRequestValidator _validator = new();

    [Fact]
    public void Validate_WithValidRequest_Succeeds()
    {
        var result = _validator.Validate(new RegisterRequest("Maria Silva", "maria@example.com", "12345678", "+351912345678"));

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Validate_WithoutPhoneNumber_Succeeds()
    {
        var result = _validator.Validate(new RegisterRequest("Maria Silva", "maria@example.com", "12345678"));

        Assert.True(result.IsValid);
    }

    [Theory]
    [InlineData("")]
    [InlineData("1234567")]
    public void Validate_WithPasswordShorterThan8Characters_Fails(string password)
    {
        var result = _validator.Validate(new RegisterRequest("Maria Silva", "maria@example.com", password));

        Assert.Contains(result.Errors, error => error.PropertyName == nameof(RegisterRequest.Password));
    }

    [Theory]
    [InlineData("")]
    [InlineData("not-an-email")]
    public void Validate_WithInvalidEmail_Fails(string email)
    {
        var result = _validator.Validate(new RegisterRequest("Maria Silva", email, "12345678"));

        Assert.Contains(result.Errors, error => error.PropertyName == nameof(RegisterRequest.Email));
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Validate_WithoutName_Fails(string name)
    {
        var result = _validator.Validate(new RegisterRequest(name, "maria@example.com", "12345678"));

        Assert.Contains(result.Errors, error => error.PropertyName == nameof(RegisterRequest.Name));
    }
}
