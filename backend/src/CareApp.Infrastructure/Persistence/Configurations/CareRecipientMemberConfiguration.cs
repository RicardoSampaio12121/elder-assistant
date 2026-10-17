using CareApp.Domain.CareRecipients;
using CareApp.Infrastructure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CareApp.Infrastructure.Persistence.Configurations;

internal sealed class CareRecipientMemberConfiguration : IEntityTypeConfiguration<CareRecipientMember>
{
    public void Configure(EntityTypeBuilder<CareRecipientMember> builder)
    {
        builder.ToTable("CareRecipientMembers");

        builder.HasKey(m => m.Id);

        builder.Property(m => m.Role)
            .IsRequired();

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(m => m.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
