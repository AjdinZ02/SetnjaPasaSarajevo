using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Model.SearchObjects;
using SetnjaPasaSarajevo.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SetnjaPasaSarajevo.Services
{
    public class PetService : BaseCRUDService<Pet, PetResponse, PetSearch, PetInsertRequest, PetUpdateRequest>, IPetService
    {
        private readonly IAuthenticatedUserAccessor _authenticatedUserAccessor;

        public PetService(
            SetnjaPasaSarajevoDbContext dbContext,
            IMapper mapper,
            IValidator<PetInsertRequest> insertValidator,
            IValidator<PetUpdateRequest> updateValidator,
            IAuthenticatedUserAccessor authenticatedUserAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _authenticatedUserAccessor = authenticatedUserAccessor;
        }

        protected override IEnumerable<Pet> ApplyFilters(IEnumerable<Pet> query, PetSearch? search)
        {
            // Pet feature does not use BaseCRUD filtering for now.
            return query;
        }

        public override async Task<PetResponse> InsertAsync(PetInsertRequest request)
        {
            await _insertValidator.ValidateAndThrowAsync(request);

            var currentUserId = _authenticatedUserAccessor.GetCurrentUserId();
            if (!currentUserId.HasValue)
                throw new UnauthorizedAccessException("User must be authenticated.");

            var entity = new Pet
            {
                UserId = currentUserId.Value,
                PetName = request.PetName,
                Age = request.Age,
                PetType = request.PetType,
                Notes = request.Notes,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _dbContext.Pets.Add(entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<PetResponse>(entity);
        }

        public async Task<List<PetResponse>> GetByUserAsync(int userId)
        {
            return await _dbContext.Pets
                .Where(p => p.UserId == userId)
                .Select(p => new PetResponse
                {
                    Id = p.Id,
                    PetName = p.PetName,
                    Age = p.Age,
                    PetType = p.PetType,
                    Notes = p.Notes,
                    CreatedAt = p.CreatedAt,
                    UpdatedAt = p.UpdatedAt,
                    IsActive = p.IsActive
                })
                .ToListAsync();
        }

        private IEnumerable<Pet> ApplyAuthorizationFilter(IEnumerable<Pet> query)
        {
            if (_authenticatedUserAccessor.IsInRole("Admin"))
                return query;

            var currentUserId = _authenticatedUserAccessor.GetCurrentUserId();

            if (!currentUserId.HasValue)
                throw new UnauthorizedAccessException("User must be authenticated.");

            return query.Where(p => p.UserId == currentUserId.Value);
        }

        private void EnforcePetAccess(Pet pet)
        {
            if (_authenticatedUserAccessor.IsInRole("Admin"))
                return;

            var currentUserId = _authenticatedUserAccessor.GetCurrentUserId();

            if (!currentUserId.HasValue || pet.UserId != currentUserId.Value)
            {
                throw new UnauthorizedAccessException("You are not authorized to access this pet.");
            }
        }
    }
}