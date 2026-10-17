using CareApp.Domain.CareRecipients;
using CareApp.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CareApp.Infrastructure.CareRecipients;

internal sealed class CareRecipientManager(CareAppDbContext dbContext)
{
    public async Task<CareRecipient> CreateAsync(CareRecipient recipient, CancellationToken cancellationToken)
    {
        dbContext.CareRecipients.Add(recipient);
        await dbContext.SaveChangesAsync(cancellationToken);
        return recipient;
    }

    public async Task<IReadOnlyList<CareRecipient>> ListByUserAsync(Guid userId, CancellationToken cancellationToken)
    {
        return await dbContext.CareRecipients
            .Include(r => r.Members)
            .Where(r => r.Members.Any(m => m.UserId == userId))
            .ToListAsync(cancellationToken);
    }

    public async Task<CareRecipient?> FindByIdForUserAsync(Guid id, Guid userId, CancellationToken cancellationToken)
    {
        return await dbContext.CareRecipients
            .Include(r => r.Members)
            .Where(r => r.Id == id && r.Members.Any(m => m.UserId == userId))
            .SingleOrDefaultAsync(cancellationToken);
    }

    public async Task UpdateAsync(CancellationToken cancellationToken)
    {
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteAsync(CareRecipient recipient, CancellationToken cancellationToken)
    {
        dbContext.CareRecipients.Remove(recipient);
        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
