using System;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SetnjaPasaSarajevo.Model.Requests
{
    public class PetUpdateRequest
    {
        [JsonPropertyName("name")]
        [Required]
        [MaxLength(100)]
        public string PetName { get; set; } = string.Empty;

        [JsonPropertyName("age")]
        [Required]
        public int Age { get; set; }

        [JsonPropertyName("type")]
        [Required]
        [MaxLength(50)]
        public string PetType { get; set; } = string.Empty;

        [JsonPropertyName("notes")]
        [MaxLength(250)]
        public string? Notes { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
