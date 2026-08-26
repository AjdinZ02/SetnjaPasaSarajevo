using System;

namespace SetnjaPasaSarajevo.Model.Responses
{
    public class TimeSlotResponse
    {
        public int Id { get; set; }
        public DateTime Date { get; set; }
        public string StartTime { get; set; } = string.Empty;
        public string EndTime { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public string Reason { get; set; } = string.Empty;
    }
}
