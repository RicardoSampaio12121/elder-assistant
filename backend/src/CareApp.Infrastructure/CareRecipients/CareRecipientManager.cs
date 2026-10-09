using CareApp.Domain.CareRecipients;
using CareApp.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CareApp.Infrastructure.CareRecipients;

internal sealed class CareRecipientManager(CareAppDbContext dbContext)
{
    public async Task<CareRecipient> CreateAsync(CareRecipient recipient, CareRecipientMember member, CancellationToken cancellationToken)
    {
        dbContext.CareRecipients.Add(recipient);
        dbContext.CareRecipientMembers.Add(member);
        await dbContext.SaveChangesAsync(cancellationToken);
        return recipient;
    }

    public async Task<List<CareRecipient>> ListByUserIdAsync(Guid userId, CancellationToken cancellationToken)
    {
        return await dbContext.CareRecipients
            .Where(r => r.Members.Any(m => m.UserId == userId))
            .ToListAsync(cancellationToken);
    }

    public async Task<CareRecipient?> FindAsync(Guid id, CancellationToken cancellationToken)
    {
        return await dbContext.CareRecipients
            .Include(r => r.Members)
            .SingleOrDefaultAsync(r => r.Id == id, cancellationToken);
    }

    public async Task UpdateAsync(CareRecipient recipient, CancellationToken cancellationToken)
    {
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteAsync(CareRecipient recipient, CancellationToken cancellationToken)
    {
        dbContext.CareRecipients.Remove(recipient);
        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
