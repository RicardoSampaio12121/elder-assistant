using CareApp.Application.CareRecipients;
using CareApp.Domain.CareRecipients;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CareApp.Infrastructure.Persistence.Configurations;

internal sealed class CareRecipientConfiguration : IEntityTypeConfiguration<CareRecipient>
{
    public void Configure(EntityTypeBuilder<CareRecipient> builder)
    {
        builder.ToTable("CareRecipients");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Name)
            .HasMaxLength(CreateCareRecipientRequestValidator.NameMaxLength)
            .IsRequired();

        builder.Property(r => r.Notes)
            .HasMaxLength(CreateCareRecipientRequestValidator.NotesMaxLength);
    }
}
