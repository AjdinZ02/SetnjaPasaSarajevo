using System;
using System.Text.Json.Serialization;

namespace SetnjaPasaSarajevo.Model.Responses
{
    public class PetResponse
    {
        public int Id { get; set; }

        [JsonPropertyName("name")]
        public string PetName { get; set; } = string.Empty;

        [JsonPropertyName("age")]
        public int Age { get; set; }

        [JsonPropertyName("type")]
        public string PetType { get; set; } = string.Empty;

        [JsonPropertyName("notes")]
        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsActive { get; set; }
    }
}
