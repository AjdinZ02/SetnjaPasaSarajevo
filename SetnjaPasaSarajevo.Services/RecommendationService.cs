using Microsoft.EntityFrameworkCore;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Services.Database;

namespace SetnjaPasaSarajevo.Services;

public sealed class RecommendationService : IRecommendationService
{
    private readonly SetnjaPasaSarajevoDbContext _db;

    public RecommendationService(SetnjaPasaSarajevoDbContext db) => _db = db;

    public async Task<List<TimeSlotResponse>> GetRecommendedTimeSlotsAsync(int userId, int limit = 3)
    {
        limit = Math.Clamp(limit, 1, 10);
        var now = DateTime.Now;
        var firstRecommendationDate = now.Date.AddDays(1);
        var lastRecommendationDate = now.Date.AddDays(30);

        var userReservations = await _db.Reservations
            .Where(r => r.UserId == userId && r.IsActive)
            .Include(r => r.TimeSlot)
            .ToListAsync();

        var userPreferences = userReservations
            .Where(r => r.TimeSlot != null)
            .GroupBy(r => (r.TimeSlot.Date.DayOfWeek, r.TimeSlot.StartTime.Hours))
            .ToDictionary(g => g.Key, g => g.Count());

        var otherReservations = await _db.Reservations
            .Where(r => r.UserId != userId && r.IsActive)
            .Include(r => r.TimeSlot)
            .ToListAsync();

        var similarUsers = otherReservations
            .GroupBy(r => r.UserId)
            .Select(g => new
            {
                UserId = g.Key,
                Score = g.Where(r => r.TimeSlot != null).Sum(r => userPreferences.TryGetValue(
                    (r.TimeSlot.Date.DayOfWeek, r.TimeSlot.StartTime.Hours), out var count) ? count : 0)
            })
            .Where(x => x.Score > 0)
            .OrderByDescending(x => x.Score)
            .Take(20)
            .Select(x => x.UserId)
            .ToHashSet();

        var popularTimes = otherReservations
            .Where(r => similarUsers.Contains(r.UserId) && r.TimeSlot != null)
            .GroupBy(r => (r.TimeSlot.Date.DayOfWeek, r.TimeSlot.StartTime.Hours))
            .ToDictionary(g => g.Key, g => g.Count());

        var reservedSlotIds = await _db.Reservations
            .Where(r => r.IsActive)
            .Select(r => r.TimeSlotId)
            .ToHashSetAsync();

        var candidates = await _db.TimeSlots
            .Where(s => s.IsActive &&
                        s.IsAvailable &&
                        s.Date >= firstRecommendationDate &&
                        s.Date < lastRecommendationDate.AddDays(1))
            .OrderBy(s => s.Date).ThenBy(s => s.StartTime)
            .ToListAsync();

        var ranked = candidates
            .Where(s => !reservedSlotIds.Contains(s.Id))
            .Select(s =>
            {
                var key = (s.Date.DayOfWeek, s.StartTime.Hours);
                popularTimes.TryGetValue(key, out var collaborativeScore);
                userPreferences.TryGetValue(key, out var personalScore);
                return new
                {
                    Slot = s,
                    CollaborativeScore = collaborativeScore,
                    PersonalScore = personalScore,
                    Score = collaborativeScore * 3 + personalScore * 2
                };
            })
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Slot.Date)
            .ThenBy(x => x.Slot.StartTime)
            .Take(limit)
            .Select(x => new TimeSlotResponse
            {
                Id = x.Slot.Id,
                Date = x.Slot.Date,
                StartTime = x.Slot.StartTime.ToString(@"hh\:mm"),
                EndTime = x.Slot.EndTime.ToString(@"hh\:mm"),
                IsActive = x.Slot.IsActive,
                Reason = GetRecommendationReason(x.CollaborativeScore, x.PersonalScore)
            })
            .ToList();

        return ranked;
    }

    private static string GetRecommendationReason(int collaborativeScore, int personalScore)
    {
        if (collaborativeScore > 0 && personalScore > 0)
        {
            return "Recommended because you and similar users often book this day and time.";
        }

        if (collaborativeScore > 0)
        {
            return "Recommended because similar users often book this day and time.";
        }

        if (personalScore > 0)
        {
            return "Recommended because you have booked this day and time before.";
        }

        return "Recommended as an available time slot in the next 30 days.";
    }
}
