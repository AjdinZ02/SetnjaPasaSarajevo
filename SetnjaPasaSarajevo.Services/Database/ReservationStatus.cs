using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Services.Database
{
    public class ReservationStatus
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(200)]
        public string? Description { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }
}
