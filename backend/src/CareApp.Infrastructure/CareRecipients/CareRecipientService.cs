using CareApp.Application.CareRecipients;
using CareApp.Application.CareRecipients.Contracts;
using CareApp.Application.Common.Exceptions;
using CareApp.Domain.CareRecipients;

namespace CareApp.Infrastructure.CareRecipients;

internal sealed class CareRecipientService(CareRecipientManager manager, TimeProvider timeProvider) : ICareRecipientService
{
    private const string NotFoundMessage = "Care recipient not found.";
    private const string ForbiddenMessage = "Only the owner can perform this action.";

    public async Task<CareRecipientResponse> CreateAsync(Guid userId, CreateCareRecipientRequest request, CancellationToken cancellationToken = default)
    {
        var now = timeProvider.GetUtcNow();
        var recipient = new CareRecipient(Guid.CreateVersion7(), request.Name.Trim(), request.DateOfBirth, request.Notes?.Trim(), now);
        var member = new CareRecipientMember(Guid.CreateVersion7(), recipient.Id, userId, CareRecipientMemberRole.Owner, now);

        await manager.CreateAsync(recipient, member, cancellationToken);
        return ToResponse(recipient);
    }

    public async Task<IReadOnlyList<CareRecipientResponse>> ListAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var recipients = await manager.ListByUserIdAsync(userId, cancellationToken);
        return recipients.Select(ToResponse).ToList();
    }

    public async Task<CareRecipientResponse> GetAsync(Guid userId, Guid id, CancellationToken cancellationToken = default)
    {
        var recipient = await manager.FindAsync(id, cancellationToken);

        if (recipient is null)
            throw new NotFoundException(NotFoundMessage);

        if (recipient.Members.All(m => m.UserId != userId))
            throw new NotFoundException(NotFoundMessage);

        return ToResponse(recipient);
    }

    public async Task<CareRecipientResponse> UpdateAsync(Guid userId, Guid id, UpdateCareRecipientRequest request, CancellationToken cancellationToken = default)
    {
        var recipient = await manager.FindAsync(id, cancellationToken);

        if (recipient is null)
            throw new NotFoundException(NotFoundMessage);

        var userMember = recipient.Members.FirstOrDefault(m => m.UserId == userId);

        if (userMember is null)
            throw new NotFoundException(NotFoundMessage);

        if (userMember.Role != CareRecipientMemberRole.Owner)
            throw new ForbiddenException(ForbiddenMessage);

        recipient.Name = request.Name.Trim();
        recipient.DateOfBirth = request.DateOfBirth;
        recipient.Notes = request.Notes?.Trim();

        await manager.UpdateAsync(recipient, cancellationToken);
        return ToResponse(recipient);
    }

    public async Task DeleteAsync(Guid userId, Guid id, CancellationToken cancellationToken = default)
    {
        var recipient = await manager.FindAsync(id, cancellationToken);

        if (recipient is null)
            throw new NotFoundException(NotFoundMessage);

        var userMember = recipient.Members.FirstOrDefault(m => m.UserId == userId);

        if (userMember is null)
            throw new NotFoundException(NotFoundMessage);

        if (userMember.Role != CareRecipientMemberRole.Owner)
            throw new ForbiddenException(ForbiddenMessage);

        await manager.DeleteAsync(recipient, cancellationToken);
    }

    private static CareRecipientResponse ToResponse(CareRecipient recipient) =>
        new(recipient.Id, recipient.Name, recipient.DateOfBirth, recipient.Notes, recipient.CreatedAt);
}
