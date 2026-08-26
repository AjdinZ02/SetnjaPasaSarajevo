using System;

namespace SetnjaPasaSarajevo.Model.Responses
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string PetName { get; set; } = string.Empty;
        public string PetType { get; set; } = string.Empty;
        public string? Notes { get; set; }
        public string Status { get; set; } ="Pending";
        // Backward-compatible field (may be unused)
        public DateTime? ReservationDateTime { get; set; }
        // Nested TimeSlot info
        public TimeSlotResponse? TimeSlot { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsActive { get; set; }
        public decimal PricePaid { get; set; }
        public UserResponse? User { get; set; }
    }
}
