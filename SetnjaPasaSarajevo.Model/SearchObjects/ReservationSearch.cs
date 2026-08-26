using System;

namespace SetnjaPasaSarajevo.Model.SearchObjects
{
    public class ReservationSearch : BaseSearchObject
    {
        /// <summary>
        /// Filter reservations by user id.
        /// </summary>
        public int? UserId { get; set; }

        /// <summary>
        /// Substring to match against pet name (case-insensitive).
        /// </summary>
        public string? PetName { get; set; }

        /// <summary>
        /// Filter reservations by pet type (case-insensitive).
        /// </summary>
        public string? PetType { get; set; }

        /// <summary>
        /// Filter reservations by active status.
        /// </summary>
        public bool? IsActive { get; set; }

        /// <summary>
        /// Filter reservations by reservation date (start date).
        /// </summary>
        public DateTime? ReservationDateFrom { get; set; }

        /// <summary>
        /// Filter reservations by reservation date (end date).
        /// </summary>
        public DateTime? ReservationDateTo { get; set; }

        /// <summary>
        /// Include User entity in the result.
        /// </summary>
        public bool IncludeUser { get; set; } = false;
    }
}
