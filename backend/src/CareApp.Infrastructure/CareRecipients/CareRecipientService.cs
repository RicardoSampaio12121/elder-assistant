using CareApp.Application.CareRecipients;
using CareApp.Application.CareRecipients.Contracts;
using CareApp.Application.Common.Exceptions;
using CareApp.Domain.CareRecipients;

namespace CareApp.Infrastructure.CareRecipients;

internal sealed class CareRecipientService(
    CareRecipientManager careRecipientManager,
    TimeProvider timeProvider) : ICareRecipientService
{
    public async Task<CareRecipientResponse> CreateAsync(
        CreateCareRecipientRequest request,
        Guid userId,
        CancellationToken cancellationToken)
    {
        var now = timeProvider.GetUtcNow();
        var recipientId = Guid.CreateVersion7();
        var recipient = new CareRecipient(recipientId, request.Name, request.DateOfBirth, request.Notes, now);
        var member = new CareRecipientMember(Guid.CreateVersion7(), recipientId, userId, CareRecipientMemberRole.Owner, now);
        recipient.Members.Add(member);

        await careRecipientManager.CreateAsync(recipient, cancellationToken);
        return ToResponse(recipient);
    }

    public async Task<IReadOnlyList<CareRecipientResponse>> ListAsync(Guid userId, CancellationToken cancellationToken)
    {
        var recipients = await careRecipientManager.ListByUserAsync(userId, cancellationToken);
        return recipients.Select(ToResponse).ToList();
    }

    public async Task<CareRecipientResponse> GetByIdAsync(Guid id, Guid userId, CancellationToken cancellationToken)
    {
        var recipient = await careRecipientManager.FindByIdForUserAsync(id, userId, cancellationToken);
        if (recipient is null)
            throw new NotFoundException($"Care recipient '{id}' was not found.");

        return ToResponse(recipient);
    }

    public async Task<CareRecipientResponse> UpdateAsync(
        Guid id,
        UpdateCareRecipientRequest request,
        Guid userId,
        CancellationToken cancellationToken)
    {
        var recipient = await careRecipientManager.FindByIdForUserAsync(id, userId, cancellationToken);
        if (recipient is null)
            throw new NotFoundException($"Care recipient '{id}' was not found.");

        var member = recipient.Members.Single(m => m.UserId == userId);
        if (member.Role != CareRecipientMemberRole.Owner)
            throw new ForbiddenException("Only the owner can update a care recipient.");

        recipient.Name = request.Name;
        recipient.DateOfBirth = request.DateOfBirth;
        recipient.Notes = request.Notes;

        await careRecipientManager.UpdateAsync(cancellationToken);
        return ToResponse(recipient);
    }

    public async Task DeleteAsync(Guid id, Guid userId, CancellationToken cancellationToken)
    {
        var recipient = await careRecipientManager.FindByIdForUserAsync(id, userId, cancellationToken);
        if (recipient is null)
            throw new NotFoundException($"Care recipient '{id}' was not found.");

        var member = recipient.Members.Single(m => m.UserId == userId);
        if (member.Role != CareRecipientMemberRole.Owner)
            throw new ForbiddenException("Only the owner can delete a care recipient.");

        await careRecipientManager.DeleteAsync(recipient, cancellationToken);
    }

    private static CareRecipientResponse ToResponse(CareRecipient recipient) =>
        new(recipient.Id, recipient.Name, recipient.DateOfBirth, recipient.Notes, recipient.CreatedAt);
}
