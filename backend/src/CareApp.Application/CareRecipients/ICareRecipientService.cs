using CareApp.Application.CareRecipients.Contracts;

namespace CareApp.Application.CareRecipients;

public interface ICareRecipientService
{
    Task<CareRecipientResponse> CreateAsync(Guid userId, CreateCareRecipientRequest request, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CareRecipientResponse>> ListAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <exception cref="Common.Exceptions.NotFoundException">Not found or the user is not a member.</exception>
    Task<CareRecipientResponse> GetAsync(Guid userId, Guid id, CancellationToken cancellationToken = default);

    /// <exception cref="Common.Exceptions.NotFoundException">Not found or the user is not a member.</exception>
    /// <exception cref="Common.Exceptions.ForbiddenException">The user is a member but not the Owner.</exception>
    Task<CareRecipientResponse> UpdateAsync(Guid userId, Guid id, UpdateCareRecipientRequest request, CancellationToken cancellationToken = default);

    /// <exception cref="Common.Exceptions.NotFoundException">Not found or the user is not a member.</exception>
    /// <exception cref="Common.Exceptions.ForbiddenException">The user is a member but not the Owner.</exception>
    Task DeleteAsync(Guid userId, Guid id, CancellationToken cancellationToken = default);
}
