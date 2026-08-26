class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://127.0.0.1:5126",
  );

  static const String accessEndpoint = "/Access";
  static const String reservationsEndpoint = "/api/Reservations";
  static const String usersEndpoint = "/Users";
  static const String petsEndpoint = "/Pets";

  static String getFullUrl(String endpoint) => "$baseUrl$endpoint";
}
