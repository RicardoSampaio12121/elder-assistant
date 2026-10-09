using CareApp.Application.CareRecipients.Contracts;
using FluentValidation;

namespace CareApp.Application.CareRecipients;

public sealed class CreateCareRecipientRequestValidator : AbstractValidator<CreateCareRecipientRequest>
{
    public const int NameMaxLength = 100;
    public const int NotesMaxLength = 500;

    public CreateCareRecipientRequestValidator()
    {
        RuleFor(r => r.Name)
            .NotEmpty().WithMessage("Name is required.")
            .MaximumLength(NameMaxLength).WithMessage($"Name cannot exceed {NameMaxLength} characters.");

        RuleFor(r => r.DateOfBirth)
            .Must(dob => dob < DateOnly.FromDateTime(DateTime.UtcNow))
            .WithMessage("Date of birth must be in the past.");

        RuleFor(r => r.Notes)
            .MaximumLength(NotesMaxLength).WithMessage($"Notes cannot exceed {NotesMaxLength} characters.");
    }
}

public sealed class UpdateCareRecipientRequestValidator : AbstractValidator<UpdateCareRecipientRequest>
{
    public UpdateCareRecipientRequestValidator()
    {
        RuleFor(r => r.Name)
            .NotEmpty().WithMessage("Name is required.")
            .MaximumLength(CreateCareRecipientRequestValidator.NameMaxLength)
            .WithMessage($"Name cannot exceed {CreateCareRecipientRequestValidator.NameMaxLength} characters.");

        RuleFor(r => r.DateOfBirth)
            .Must(dob => dob < DateOnly.FromDateTime(DateTime.UtcNow))
            .WithMessage("Date of birth must be in the past.");

        RuleFor(r => r.Notes)
            .MaximumLength(CreateCareRecipientRequestValidator.NotesMaxLength)
            .WithMessage($"Notes cannot exceed {CreateCareRecipientRequestValidator.NotesMaxLength} characters.");
    }
}
