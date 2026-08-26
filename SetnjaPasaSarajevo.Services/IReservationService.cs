using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Model.Responses;

namespace SetnjaPasaSarajevo.Services
{
    public interface IReservationService
    {
        Task<List<ReservationResponse>> GetAllReservations();
        Task<List<ReservationResponse>> GetReservationsByUser(int userId);

        Task UpdateStatus(int id, string status);
        Task DeleteReservation(int id);

        // ✅ OVO DODAJ
        Task<ReservationResponse> InsertAsync(ReservationInsertRequest request);
    }
}