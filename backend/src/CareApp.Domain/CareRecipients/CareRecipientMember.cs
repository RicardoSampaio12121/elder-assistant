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

    public Guid Id { get; set; }
    public Guid CareRecipientId { get; set; }
    public Guid UserId { get; set; }
    public CareRecipientMemberRole Role { get; set; }
    public DateTimeOffset JoinedAt { get; set; }
}
