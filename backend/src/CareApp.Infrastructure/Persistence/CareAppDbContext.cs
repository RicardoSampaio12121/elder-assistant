using Microsoft.EntityFrameworkCore;

namespace CareApp.Infrastructure.Persistence;

public class CareAppDbContext(DbContextOptions<CareAppDbContext> options) : DbContext(options);
