namespace SetnjaPasaSarajevo.Model.SearchObjects
{
    public class PetSearch : BaseSearchObject
    {
        public int? UserId { get; set; }
        public string? PetName { get; set; }
        public string? PetType { get; set; }
        public bool? IsActive { get; set; }
    }
}
