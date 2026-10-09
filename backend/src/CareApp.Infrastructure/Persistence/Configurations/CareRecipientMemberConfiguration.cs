using CareApp.Domain.CareRecipients;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CareApp.Infrastructure.Persistence.Configurations;

internal sealed class CareRecipientMemberConfiguration : IEntityTypeConfiguration<CareRecipientMember>
{
    public void Configure(EntityTypeBuilder<CareRecipientMember> builder)
    {
        builder.ToTable("CareRecipientMembers");

        builder.HasKey(m => m.Id);

        builder.HasIndex(m => new { m.CareRecipientId, m.UserId }).IsUnique();

        builder.HasOne<CareRecipient>()
            .WithMany(r => r.Members)
            .HasForeignKey(m => m.CareRecipientId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
