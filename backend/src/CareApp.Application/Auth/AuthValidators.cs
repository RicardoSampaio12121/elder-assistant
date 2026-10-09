using FluentValidation;

namespace CareApp.Application.Auth;

public sealed class RegisterRequestValidator : AbstractValidator<RegisterRequest>
{
    public const int PasswordMinLength = 8;
    public const int NameMaxLength = 200;
    public const int EmailMaxLength = 256;
    public const int PhoneNumberMaxLength = 32;

    public RegisterRequestValidator()
    {
        RuleFor(request => request.Name)
            .NotEmpty().WithMessage("Name is required.")
            .MaximumLength(NameMaxLength).WithMessage($"Name cannot exceed {NameMaxLength} characters.");

        RuleFor(request => request.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Email is not valid.")
            .MaximumLength(EmailMaxLength).WithMessage($"Email cannot exceed {EmailMaxLength} characters.");

        RuleFor(request => request.Password)
            .NotEmpty().WithMessage("Password is required.")
            .MinimumLength(PasswordMinLength).WithMessage($"Password must be at least {PasswordMinLength} characters.");

        RuleFor(request => request.PhoneNumber)
            .MaximumLength(PhoneNumberMaxLength).WithMessage($"Phone number cannot exceed {PhoneNumberMaxLength} characters.");
    }
}

public sealed class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(request => request.Email).NotEmpty().WithMessage("Email is required.");
        RuleFor(request => request.Password).NotEmpty().WithMessage("Password is required.");
    }
}

public sealed class RefreshTokenRequestValidator : AbstractValidator<RefreshTokenRequest>
{
    public RefreshTokenRequestValidator()
    {
        RuleFor(request => request.RefreshToken).NotEmpty().WithMessage("Refresh token is required.");
    }
}
