using SetnjaPasaSarajevo.Model.Responses;

namespace SetnjaPasaSarajevo.Services;

public interface ITimeSlotService
{
    Task<IReadOnlyList<TimeSlotResponse>> GetByDateAsync(DateTime date);
}
