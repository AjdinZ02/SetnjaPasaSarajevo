using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Services.Database
{
    public class User
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;
        
        public string PasswordHash { get; set; } = string.Empty;
        
        public string PasswordSalt { get; set; } = string.Empty;
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? LastLoginAt { get; set; }
        
        [Phone]
        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        public string? ProfileImageBase64 { get; set; }

        // UserProfile fields
        [MaxLength(255)]
        public string? Address { get; set; }

        [MaxLength(100)]
        public string? PetName { get; set; }

        [MaxLength(50)]
        public string? PetType { get; set; }

        [MaxLength(500)]
        public string? AdditionalNotes { get; set; }

        // Navigation property for the many-to-many relationship with Role
        public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();

        public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();

        public ICollection<Pet> Pets { get; set; } = new List<Pet>();

        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();

        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();

        public ICollection<Location> Locations { get; set; } = new List<Location>();

        public ICollection<Schedule> Schedules { get; set; } = new List<Schedule>();

        public ICollection<Payment> Payments { get; set; } = new List<Payment>();

        public ICollection<WalletTransaction> WalletTransactions { get; set; } = new List<WalletTransaction>();
    }
}
