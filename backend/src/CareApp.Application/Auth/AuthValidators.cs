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
            .NotEmpty().WithMessage("O nome é obrigatório.")
            .MaximumLength(NameMaxLength).WithMessage($"O nome não pode ter mais de {NameMaxLength} caracteres.");

        RuleFor(request => request.Email)
            .NotEmpty().WithMessage("O email é obrigatório.")
            .EmailAddress().WithMessage("O email não é válido.")
            .MaximumLength(EmailMaxLength).WithMessage($"O email não pode ter mais de {EmailMaxLength} caracteres.");

        RuleFor(request => request.Password)
            .NotEmpty().WithMessage("A palavra-passe é obrigatória.")
            .MinimumLength(PasswordMinLength).WithMessage($"A palavra-passe deve ter pelo menos {PasswordMinLength} caracteres.");

        RuleFor(request => request.PhoneNumber)
            .MaximumLength(PhoneNumberMaxLength).WithMessage($"O telefone não pode ter mais de {PhoneNumberMaxLength} caracteres.");
    }
}

public sealed class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(request => request.Email).NotEmpty().WithMessage("O email é obrigatório.");
        RuleFor(request => request.Password).NotEmpty().WithMessage("A palavra-passe é obrigatória.");
    }
}

public sealed class RefreshTokenRequestValidator : AbstractValidator<RefreshTokenRequest>
{
    public RefreshTokenRequestValidator()
    {
        RuleFor(request => request.RefreshToken).NotEmpty().WithMessage("O refresh token é obrigatório.");
    }
}
