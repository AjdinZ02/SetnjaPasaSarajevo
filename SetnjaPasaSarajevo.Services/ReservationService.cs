using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Model.SearchObjects;
using SetnjaPasaSarajevo.Services.Database;
using SetnjaPasaSarajevo.Model.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SetnjaPasaSarajevo.Services
{
    public class ReservationService : BaseCRUDService<Reservation, ReservationResponse, ReservationSearch, ReservationInsertRequest, ReservationUpdateRequest>, IReservationService
    {
        public ReservationService(
            SetnjaPasaSarajevoDbContext dbContext,
            IMapper mapper,
            IValidator<ReservationInsertRequest> insertValidator,
            IValidator<ReservationUpdateRequest> updateValidator,
            IAuthenticatedUserAccessor currentUser,
            IEventPublisher eventPublisher
        ) : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _currentUser = currentUser;
            _eventPublisher = eventPublisher;
            _reservationPrice = 10m;
        }

        private readonly IAuthenticatedUserAccessor _currentUser;
        private readonly decimal _reservationPrice;
        private readonly IEventPublisher _eventPublisher;

        public async Task<List<ReservationResponse>> GetAllReservations()
        {
            var data = await _dbContext.Reservations
                .Where(r => r.IsActive)
                .Include(r => r.ReservationStatus)
                .Include(r => r.TimeSlot)
                .Include(r => r.Pet)
                .ToListAsync();

            return _mapper.Map<List<ReservationResponse>>(data);
        }

        public async Task<List<ReservationResponse>> GetReservationsByUser(int userId)
        {
            var data = await _dbContext.Reservations
                .Where(r => r.UserId == userId && r.IsActive)
                .Include(r => r.ReservationStatus)
                .Include(r => r.TimeSlot)
                .Include(r => r.Pet)
                .ToListAsync();

            return _mapper.Map<List<ReservationResponse>>(data);
        }

        // ✅ NOVI STATUS SISTEM (FIX)
        public async Task UpdateStatus(int id, string status)
        {
            var entity = await _dbContext.Reservations
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                throw new Exception("Reservation not found");

            var statusEntity = await _dbContext.ReservationStatuses
    .FirstOrDefaultAsync(s => s.Name.ToLower() == status.ToLower());

if (statusEntity == null)
{
    throw new Exception($"Invalid status: {status}");
}


            entity.ReservationStatusId = statusEntity.Id;
            entity.UpdatedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();
            await _eventPublisher.PublishAsync("reservation.status-changed", new
            {
                reservationId = entity.Id,
                userId = entity.UserId,
                status
            });
        }

        public async Task DeleteReservation(int id)
        {
            var entity = await _dbContext.Reservations.FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                throw new Exception("Reservation not found");

            // Keep payment history intact and return the reservation credit once. A hard delete
            // would also break the wallet ledger's foreign-key reference to this reservation.
            if (!entity.IsActive)
                return;

            await using var transaction = await _dbContext.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable);
            var alreadyRefunded = await _dbContext.WalletTransactions.AnyAsync(t =>
                t.ReservationId == entity.Id && t.Type == "ReservationRefund");
            if (!alreadyRefunded && entity.PricePaid > 0)
            {
                _dbContext.WalletTransactions.Add(new WalletTransaction
                {
                    UserId = entity.UserId,
                    Amount = entity.PricePaid,
                    Currency = "EUR",
                    Type = "ReservationRefund",
                    Reference = $"reservation:{entity.Id}",
                    Description = "Reservation cancellation refund",
                    ReservationId = entity.Id
                });
            }
            entity.IsActive = false;
            entity.UpdatedAt = DateTime.UtcNow;
            var cancelledStatus = await _dbContext.ReservationStatuses.FirstOrDefaultAsync(s => s.Name == "Cancelled");
            if (cancelledStatus != null)
                entity.ReservationStatusId = cancelledStatus.Id;
            await _dbContext.SaveChangesAsync();
            await transaction.CommitAsync();
            await _eventPublisher.PublishAsync("reservation.cancelled", new
            {
                reservationId = entity.Id,
                userId = entity.UserId,
                timeSlotId = entity.TimeSlotId
            });
        }

        public override async Task DeleteAsync(int id)
        {
            await DeleteReservation(id);
        }

        protected override IEnumerable<Reservation> ApplyFilters(IEnumerable<Reservation> query, ReservationSearch? search)
        {
            return query;
        }
        public override async Task<ReservationResponse> InsertAsync(ReservationInsertRequest request)
{
    await _insertValidator.ValidateAndThrowAsync(request);

    var authenticatedUserId = _currentUser.GetCurrentUserId()
        ?? throw new ClinetException("You must be signed in to create a reservation.");
    if (request.UserId != authenticatedUserId && !_currentUser.IsInRole("Admin"))
        throw new ClinetException("You can only create reservations for your own account.");

    var user = await _dbContext.Users.FindAsync(request.UserId);
    if (user == null)
        throw new Exception("User not found");

    var timeSlot = await _dbContext.TimeSlots.FindAsync(request.TimeSlotId);
    if (timeSlot == null)
        throw new Exception("TimeSlot not found");

    var pet = await _dbContext.Pets.SingleOrDefaultAsync(p => p.Id == request.PetId && p.UserId == request.UserId);
    if (pet == null)
        throw new ClinetException("Selected pet does not belong to this account.");

    await using var transaction = await _dbContext.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable);
    var balance = await _dbContext.WalletTransactions.Where(t => t.UserId == request.UserId)
        .SumAsync(t => (decimal?)t.Amount) ?? 0m;
    if (balance < _reservationPrice)
        throw new ClinetException($"Insufficient account credit. This reservation costs {_reservationPrice:0.00} EUR.");

    var entity = new Reservation
    {
        UserId = request.UserId,
        PetId = request.PetId,
        TimeSlotId = request.TimeSlotId,
        ReservationStatusId = request.ReservationStatusId == 0 ? 1 : request.ReservationStatusId,

        // ✅ AUTO USER DATA
        FirstName = user.FirstName,
        LastName = user.LastName,
        Address = user.Address ?? "",
        PhoneNumber = user.PhoneNumber ?? "",

        // ✅ FROM REQUEST
        PetName = request.PetName,
        PetType = request.PetType,
        Notes = request.Notes,

        CreatedAt = DateTime.UtcNow,
        IsActive = true,
        PricePaid = _reservationPrice
    };

    _dbContext.Reservations.Add(entity);
    await _dbContext.SaveChangesAsync();
    _dbContext.WalletTransactions.Add(new WalletTransaction
    {
        UserId = request.UserId,
        Amount = -_reservationPrice,
        Currency = "EUR",
        Type = "ReservationCharge",
        Reference = $"reservation:{entity.Id}",
        Description = "Reservation payment",
        ReservationId = entity.Id
    });
    await _dbContext.SaveChangesAsync();
    await transaction.CommitAsync();
    await _eventPublisher.PublishAsync("reservation.created", new
    {
        reservationId = entity.Id,
        userId = entity.UserId,
        timeSlotId = entity.TimeSlotId
    });
    // Reload entity with related TimeSlot and Pet to ensure nested data is present in response
    var saved = await _dbContext.Reservations
        .Where(r => r.Id == entity.Id)
        .Include(r => r.TimeSlot)
        .Include(r => r.Pet)
        .FirstOrDefaultAsync();

    if (saved == null)
        return _mapper.Map<ReservationResponse>(entity);

    return _mapper.Map<ReservationResponse>(saved);
}
        
    }
}
