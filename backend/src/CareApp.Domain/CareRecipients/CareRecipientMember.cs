namespace CareApp.Domain.CareRecipients;

public class CareRecipientMember
{
    protected CareRecipientMember() { }

    public CareRecipientMember(Guid id, Guid careRecipientId, Guid userId, CareRecipientMemberRole role, DateTimeOffset joinedAt)
    {
        Id = id;
        CareRecipientId = careRecipientId;
        UserId = userId;
        Role = role;
        JoinedAt = joinedAt;
    }

    public Guid Id { get; private set; }

    public Guid CareRecipientId { get; private set; }

    public CareRecipient CareRecipient { get; private set; } = null!;

    public Guid UserId { get; private set; }

    public CareRecipientMemberRole Role { get; private set; }

    public DateTimeOffset JoinedAt { get; private set; }
}
