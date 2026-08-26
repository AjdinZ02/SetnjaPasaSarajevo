using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Model.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SetnjaPasaSarajevo.Services
{
    public interface IBaseReadService<TResponse, TSearch>
        where TSearch : BaseSearchObject
    {
        Task<TResponse> GetByIdAsync(int id);
        Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null);
    }
}
