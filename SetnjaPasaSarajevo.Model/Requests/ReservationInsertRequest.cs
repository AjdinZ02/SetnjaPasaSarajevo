using System;
using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Model.Requests
{
    public class ReservationInsertRequest
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        public int PetId { get; set; }

        [Required]
        public int TimeSlotId { get; set; }

        public int ReservationStatusId { get; set; } = 1;

        // ✅ snapshot = opcionalno (uzima se iz user)
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Address { get; set; }
        public string? PhoneNumber { get; set; }

        [Required]
        public string PetName { get; set; } = string.Empty;

        [Required]
        public string PetType { get; set; } = string.Empty;

        public string? Notes { get; set; }

        public bool IsActive { get; set; } = true;
    }
}