using CareApp.Application.Auth;
using CareApp.Infrastructure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CareApp.Infrastructure.Persistence.Configurations;

internal sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.Property(user => user.Name)
            .HasMaxLength(RegisterRequestValidator.NameMaxLength)
            .IsRequired();

        builder.Property(user => user.PhoneNumber)
            .HasMaxLength(RegisterRequestValidator.PhoneNumberMaxLength);
    }
}
