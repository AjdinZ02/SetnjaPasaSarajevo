using SetnjaPasaSarajevo.Common.Services.CryptoService;
using SetnjaPasaSarajevo.Model.Access;
using SetnjaPasaSarajevo.Model.Exceptions;
using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Model.SearchObjects;
using SetnjaPasaSarajevo.Services.Database;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace SetnjaPasaSarajevo.Services
{
    public class UserService : BaseCRUDService<User, UserResponse, UserSearch, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly ICryptoService _cryptoService;
        public UserService(SetnjaPasaSarajevoDbContext dbContext, MapsterMapper.IMapper mapper, IValidator<UserInsertRequest> insertValidator, IValidator<UserUpdateRequest> updateValidator, ICryptoService cryptoService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _cryptoService = cryptoService;
        }


        protected override IEnumerable<User> ApplyFilters(IEnumerable<User> query, UserSearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Email))
                {
                    query = query.Where(u => u.Email.Contains(search.Email, StringComparison.OrdinalIgnoreCase));
                }

                if (!string.IsNullOrWhiteSpace(search.Username))
                {
                    query = query.Where(u => u.Username.Contains(search.Username, StringComparison.OrdinalIgnoreCase));
                }

                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(u => u.FirstName.Contains(search.Name, StringComparison.OrdinalIgnoreCase)
                                          || u.LastName.Contains(search.Name, StringComparison.OrdinalIgnoreCase));
                }

                if (search.IsActive.HasValue)
                {
                    query = query.Where(u => u.IsActive == search.IsActive.Value);
                }
            }

            return query;
        }

        protected override User MapInsertRequestToEntity(UserInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);

            // Handle password hashing for User entity
            var salt = _cryptoService.GenerateSlat();
            entity.PasswordSalt = salt;
            entity.PasswordHash = _cryptoService.GenerateHash(request.Password, salt);

            return entity;
        }

        public override async Task<UserResponse> InsertAsync(UserInsertRequest request)
{
    await _insertValidator.ValidateAndThrowAsync(request);

    if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
    {
        throw new InvalidOperationException($"Email '{request.Email}' is already in use.");
    }

    if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username))
    {
        throw new InvalidOperationException($"Username '{request.Username}' is already in use.");
    }

    var entity = MapInsertRequestToEntity(request);
    entity.CreatedAt = DateTime.UtcNow;

    // ✅ prvo dodaj user
    _dbContext.Users.Add(entity);

    // ✅ sačuvaj da dobije ID
    await _dbContext.SaveChangesAsync();

    // ✅ tek onda dodaj role (SADA IMAMO UserId)
    entity.UserRoles = new List<UserRole>
    {
        new UserRole
        {
            UserId = entity.Id, 
            RoleId = 2,
            DateAssigned = DateTime.UtcNow
        }
    };

    await _dbContext.SaveChangesAsync();

    return _mapper.Map<UserResponse>(entity);
}



        public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
        {
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.Users.FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"User with id {id} not found.");
            }

            // Check if email or username already exists
            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email && u.Id != id))
            {
                throw new InvalidOperationException($"Email '{request.Email}' is already in use.");
            }

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username && u.Id != id))
            {
                throw new InvalidOperationException($"Username '{request.Username}' is already in use.");
            }

            entity.FirstName = request.FirstName;
            entity.LastName = request.LastName;
            entity.Email = request.Email;
            entity.Username = request.Username;
            entity.PhoneNumber = request.PhoneNumber;
            entity.Address = request.Address;

            _dbContext.Users.Update(entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<UserResponse>(entity);
        }

        public override async Task DeleteAsync(int id)
        {
            var entity = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"User with id {id} not found.");
            }

            _dbContext.Users.Remove(entity);
            await _dbContext.SaveChangesAsync();
        }

        public async Task<UserSensitveResponse?> GetByUsernameAsync(string username)
        {
            var user = await _dbContext.Users
                .AsNoTracking()
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username == username);

            UserSensitveResponse? response = null;

            if (user != null)
            {
                response = _mapper.Map<UserSensitveResponse>(user);
                response.Role = user.UserRoles.FirstOrDefault()?.Role.Name;
            }

            return response;
        }

        public async Task<UserResponse?> GetWithRoleByIdAsync(int id)
        {
            var user = await _dbContext.Users
               .AsNoTracking()
               .Include(u => u.UserRoles)
               .ThenInclude(ur => ur.Role)
               .FirstOrDefaultAsync(u => u.Id == id);

            UserResponse? response = null;

            if (user != null)
            {
                response = _mapper.Map<UserResponse>(user);
                response.Role = user.UserRoles.First().Role.Name;
            }

            return response;
        }

        public async Task ChangePasswordAsync(UserPasswordChangeRequest request)
        {
            var user = _dbContext.Users.FirstOrDefault(u => u.Id == request.Id);

            if (user == null)
                throw new Exception("User not found");

            if (!_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password))
                throw new Exception("Wrong credential");

            if (!request.NewPassword.Equals(request.ConfirmNewPassword))
                throw new Exception("Password confimation doen't match new password");

            user.PasswordSalt = _cryptoService.GenerateSlat();
            user.PasswordHash = _cryptoService.GenerateHash(request.NewPassword, user.PasswordSalt);


            _dbContext.Users.Update(user);
            await _dbContext.SaveChangesAsync();
        }
        public async Task UploadProfileImage(int userId, string base64Image)
        {
            var user = await _dbContext.Users.FindAsync(userId);

            if (user == null)
                throw new Exception("User not found");

            user.ProfileImageBase64 = base64Image;

            _dbContext.Users.Update(user);
            await _dbContext.SaveChangesAsync();
        }
    }
}
