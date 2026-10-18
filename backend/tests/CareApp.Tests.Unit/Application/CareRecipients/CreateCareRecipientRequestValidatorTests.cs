using CareApp.Application.CareRecipients;
using CareApp.Application.CareRecipients.Contracts;

namespace CareApp.Tests.Unit.Application.CareRecipients;

public class CreateCareRecipientRequestValidatorTests
{
    private readonly CreateCareRecipientRequestValidator _validator = new();

    private static readonly DateOnly ValidDateOfBirth = new(1950, 6, 15);

    [Fact]
    public void Validate_WithValidRequest_Succeeds()
    {
        var result = _validator.Validate(new CreateCareRecipientRequest("Maria Silva", ValidDateOfBirth, "Some notes"));

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Validate_WithoutNotes_Succeeds()
    {
        var result = _validator.Validate(new CreateCareRecipientRequest("Maria Silva", ValidDateOfBirth));

        Assert.True(result.IsValid);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Validate_WithEmptyName_Fails(string name)
    {
        var result = _validator.Validate(new CreateCareRecipientRequest(name, ValidDateOfBirth));

        Assert.Contains(result.Errors, e => e.PropertyName == nameof(CreateCareRecipientRequest.Name));
    }

    [Fact]
    public void Validate_WithNameExceedingMaxLength_Fails()
    {
        var longName = new string('a', CreateCareRecipientRequestValidator.NameMaxLength + 1);

        var result = _validator.Validate(new CreateCareRecipientRequest(longName, ValidDateOfBirth));

        Assert.Contains(result.Errors, e => e.PropertyName == nameof(CreateCareRecipientRequest.Name));
    }

    [Fact]
    public void Validate_WithFutureDateOfBirth_Fails()
    {
        var future = DateOnly.FromDateTime(DateTime.Today.AddDays(1));

        var result = _validator.Validate(new CreateCareRecipientRequest("Maria Silva", future));

        Assert.Contains(result.Errors, e => e.PropertyName == nameof(CreateCareRecipientRequest.DateOfBirth));
    }

    [Fact]
    public void Validate_WithTodayAsDateOfBirth_Fails()
    {
        var today = DateOnly.FromDateTime(DateTime.Today);

        var result = _validator.Validate(new CreateCareRecipientRequest("Maria Silva", today));

        Assert.Contains(result.Errors, e => e.PropertyName == nameof(CreateCareRecipientRequest.DateOfBirth));
    }

    [Fact]
    public void Validate_WithNotesExceedingMaxLength_Fails()
    {
        var longNotes = new string('a', CreateCareRecipientRequestValidator.NotesMaxLength + 1);

        var result = _validator.Validate(new CreateCareRecipientRequest("Maria Silva", ValidDateOfBirth, longNotes));

        Assert.Contains(result.Errors, e => e.PropertyName == nameof(CreateCareRecipientRequest.Notes));
    }
}
