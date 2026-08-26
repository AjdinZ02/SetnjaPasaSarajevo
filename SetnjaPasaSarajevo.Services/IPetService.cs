using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Model.SearchObjects;

namespace SetnjaPasaSarajevo.Services
{
    public interface IPetService : IBaseCRUDService<PetResponse, PetSearch, PetInsertRequest, PetUpdateRequest>
    {
        Task<List<PetResponse>> GetByUserAsync(int userId);
    }
}
