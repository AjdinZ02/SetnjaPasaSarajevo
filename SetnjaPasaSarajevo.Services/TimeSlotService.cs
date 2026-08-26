using Microsoft.EntityFrameworkCore;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Services.Database;

namespace SetnjaPasaSarajevo.Services;

public sealed class TimeSlotService : ITimeSlotService
{
    private readonly SetnjaPasaSarajevoDbContext _dbContext;

    public TimeSlotService(SetnjaPasaSarajevoDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyList<TimeSlotResponse>> GetByDateAsync(DateTime date)
    {
        var targetDate = date.Date;
        var slots = await _dbContext.TimeSlots
            .Where(slot => slot.Date.Date == targetDate && slot.IsActive)
            .ToListAsync();

        if (slots.Count == 0)
        {
            var generated = Enumerable.Range(8, 14).Select(hour => new TimeSlot
            {
                Date = targetDate,
                StartTime = TimeSpan.FromHours(hour),
                EndTime = TimeSpan.FromHours(hour + 1),
                IsActive = true,
                IsAvailable = true,
                CreatedAt = DateTime.UtcNow
            }).ToList();
            await _dbContext.TimeSlots.AddRangeAsync(generated);
            await _dbContext.SaveChangesAsync();
            slots = generated;
        }

        return slots
            .OrderBy(slot => slot.StartTime)
            .Select(slot => new TimeSlotResponse
            {
                Id = slot.Id,
                Date = slot.Date,
                StartTime = slot.StartTime.ToString(@"hh\:mm"),
                EndTime = slot.EndTime.ToString(@"hh\:mm"),
                IsActive = slot.IsActive
            })
            .ToList();
    }
}
