using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SetnjaPasaSarajevo.Services.Database
{
    public class Reservation
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        public User User { get; set; } = null!;

        [Required]
        public int PetId { get; set; }

        public Pet Pet { get; set; } = null!;

        [Required]
        public int TimeSlotId { get; set; }

        public TimeSlot TimeSlot { get; set; } = null!;

        [Required]
        public int ReservationStatusId { get; set; }

        public ReservationStatus ReservationStatus { get; set; } = null!;

        public int? LocationId { get; set; }

        public Location? Location { get; set; }

        // Snapshot podaci (OK ostaviti)
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        public string Address { get; set; } = string.Empty;

        [Required]
        [Phone]
        [MaxLength(20)]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string PetName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string PetType { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public bool IsActive { get; set; } = true;

        public decimal PricePaid { get; set; }

        public ICollection<Review> Reviews { get; set; } = new List<Review>();
    }
}
