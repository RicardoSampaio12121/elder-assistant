using CareApp.Application.CareRecipients.Contracts;

namespace CareApp.Application.CareRecipients;

public interface ICareRecipientService
{
    /// <exception cref="Common.Exceptions.NotFoundException">The care recipient was not found or the caller is not a member.</exception>
    /// <exception cref="Common.Exceptions.ForbiddenException">The caller is not the Owner.</exception>
    Task<CareRecipientResponse> CreateAsync(CreateCareRecipientRequest request, Guid userId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CareRecipientResponse>> ListAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <exception cref="Common.Exceptions.NotFoundException">The care recipient was not found or the caller is not a member.</exception>
    Task<CareRecipientResponse> GetByIdAsync(Guid id, Guid userId, CancellationToken cancellationToken = default);

    /// <exception cref="Common.Exceptions.NotFoundException">The care recipient was not found or the caller is not a member.</exception>
    /// <exception cref="Common.Exceptions.ForbiddenException">The caller is not the Owner.</exception>
    Task<CareRecipientResponse> UpdateAsync(Guid id, UpdateCareRecipientRequest request, Guid userId, CancellationToken cancellationToken = default);

    /// <exception cref="Common.Exceptions.NotFoundException">The care recipient was not found or the caller is not a member.</exception>
    /// <exception cref="Common.Exceptions.ForbiddenException">The caller is not the Owner.</exception>
    Task DeleteAsync(Guid id, Guid userId, CancellationToken cancellationToken = default);
}
