using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Services.Database
{
    public class TimeSlot
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public DateTime Date { get; set; } // ✅ BITNO

        [Required]
        public TimeSpan StartTime { get; set; }

        [Required]
        public TimeSpan EndTime { get; set; }

        public bool IsAvailable { get; set; } = true;

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }
}