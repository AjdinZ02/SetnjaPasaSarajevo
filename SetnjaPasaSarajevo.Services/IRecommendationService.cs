using SetnjaPasaSarajevo.Model.Responses;

namespace SetnjaPasaSarajevo.Services;

public interface IRecommendationService
{
    Task<List<TimeSlotResponse>> GetRecommendedTimeSlotsAsync(int userId, int limit = 3);
}
