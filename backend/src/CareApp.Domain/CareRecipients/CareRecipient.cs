namespace CareApp.Domain.CareRecipients;

public class CareRecipient
{
    protected CareRecipient() { }

    public CareRecipient(Guid id, string name, DateOnly dateOfBirth, string? notes, DateTimeOffset createdAt)
    {
        Id = id;
        Name = name;
        DateOfBirth = dateOfBirth;
        Notes = notes;
        CreatedAt = createdAt;
    }

    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateOnly DateOfBirth { get; set; }
    public string? Notes { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public ICollection<CareRecipientMember> Members { get; set; } = [];
}
