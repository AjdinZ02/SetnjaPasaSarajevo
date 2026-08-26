using System;
using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Model.Requests
{
    public class ReservationUpdateRequest
    {
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

        [Required]
        public DateTime ReservationDateTime { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
