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

    public Guid Id { get; private set; }

    public string Name { get; private set; } = string.Empty;

    public DateOnly DateOfBirth { get; private set; }

    public string? Notes { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public ICollection<CareRecipientMember> Members { get; private set; } = new List<CareRecipientMember>();

    public void Update(string name, DateOnly dateOfBirth, string? notes)
    {
        Name = name;
        DateOfBirth = dateOfBirth;
        Notes = notes;
    }
}
