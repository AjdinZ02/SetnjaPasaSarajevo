using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Model.Requests
{
    public class UserUpdateRequest
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Username { get; set; }
        public string? PhoneNumber { get; set; }
        public bool IsActive { get; set; }
        public string? ProfileImageBase64 { get; set; }
        public string? Address { get; set; }
        public string? PetName { get; set; }
        public string? PetType { get; set; }
        public string? AdditionalNotes { get; set; }
    }
}
