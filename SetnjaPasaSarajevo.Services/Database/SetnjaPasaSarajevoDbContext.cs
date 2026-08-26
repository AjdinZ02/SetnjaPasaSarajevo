using Microsoft.EntityFrameworkCore;

namespace SetnjaPasaSarajevo.Services.Database
{
    public partial class SetnjaPasaSarajevoDbContext : DbContext
    {
        public SetnjaPasaSarajevoDbContext(DbContextOptions<SetnjaPasaSarajevoDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }
        public DbSet<RefreshToken> RefreshTokens { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<Pet> Pets { get; set; }
        public DbSet<TimeSlot> TimeSlots { get; set; }
        public DbSet<ReservationStatus> ReservationStatuses { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Location> Locations { get; set; }
        public DbSet<Schedule> Schedules { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<WalletTransaction> WalletTransactions { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // ✅ USER RELATIONS
            modelBuilder.Entity<User>()
                .HasMany(u => u.Pets)
                .WithOne(p => p.User)
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<User>()
                .HasMany(u => u.Reservations)
                .WithOne(r => r.User)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<User>()
                .HasMany(u => u.Notifications)
                .WithOne(n => n.User)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<User>()
                .HasMany(u => u.Locations)
                .WithOne(l => l.User)
                .HasForeignKey(l => l.UserId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<User>()
                .HasMany(u => u.Schedules)
                .WithOne(s => s.User)
                .HasForeignKey(s => s.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<User>()
                .HasMany(u => u.Payments).WithOne(p => p.User).HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            modelBuilder.Entity<User>()
                .HasMany(u => u.WalletTransactions).WithOne(t => t.User).HasForeignKey(t => t.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Payment>().Property(p => p.Amount).HasPrecision(18, 2);
            modelBuilder.Entity<WalletTransaction>().Property(t => t.Amount).HasPrecision(18, 2);
            modelBuilder.Entity<Reservation>().Property(r => r.PricePaid).HasPrecision(18, 2);
            modelBuilder.Entity<WalletTransaction>().HasIndex(t => new { t.UserId, t.CreatedAt });
            modelBuilder.Entity<WalletTransaction>().HasIndex(t => t.PaymentId).IsUnique();
            modelBuilder.Entity<Payment>().HasIndex(p => p.ProviderOrderId).IsUnique();

            // ✅ RESERVATION RELATIONS
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Pet)
                .WithMany()
                .HasForeignKey(r => r.PetId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.TimeSlot)
                .WithMany(ts => ts.Reservations)
                .HasForeignKey(r => r.TimeSlotId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.ReservationStatus)
                .WithMany(s => s.Reservations)
                .HasForeignKey(r => r.ReservationStatusId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Location)
                .WithMany(l => l.Reservations)
                .HasForeignKey(r => r.LocationId)
                .OnDelete(DeleteBehavior.Restrict);

            // ✅ REVIEW RELATION
            modelBuilder.Entity<Review>()
                .HasOne(rv => rv.Reservation)
                .WithMany(r => r.Reviews)
                .HasForeignKey(rv => rv.ReservationId)
                .OnDelete(DeleteBehavior.Cascade);

            // ✅ PRECISION FIX (uklanja warninge)
            modelBuilder.Entity<Location>()
                .Property(l => l.Latitude)
                .HasPrecision(9, 6);

            modelBuilder.Entity<Location>()
                .Property(l => l.Longitude)
                .HasPrecision(9, 6);

            // ✅ SEED STATUS (STATIC - BEZ GREŠKE)
            modelBuilder.Entity<ReservationStatus>().HasData(
                new ReservationStatus
                {
                    Id = 1,
                    Name = "Pending",
                    Description = "Waiting for confirmation",
                    IsActive = true,
                    CreatedAt = new DateTime(2024, 1, 1)
                },
                new ReservationStatus
                {
                    Id = 2,
                    Name = "Confirmed",
                    Description = "Reservation is confirmed",
                    IsActive = true,
                    CreatedAt = new DateTime(2024, 1, 1)
                },
                new ReservationStatus
                {
                    Id = 3,
                    Name = "Cancelled",
                    Description = "Reservation is cancelled",
                    IsActive = true,
                    CreatedAt = new DateTime(2024, 1, 1)
                },
                new ReservationStatus
                {
                    Id = 4,
                    Name = "Completed",
                    Description = "Reservation is completed",
                    IsActive = true,
                    CreatedAt = new DateTime(2024, 1, 1)
                }
            );
            // ✅ SEED ROLES (OBAVEZNO)
            modelBuilder.Entity<Role>().HasData(
                new Role
                {
                    Id = 1,
                    Name = "Admin"
                },
                new Role
                {
                    Id = 2,
                    Name = "User"
                }
            );

            base.OnModelCreating(modelBuilder);
        }
    }
}
