class ApiConstants {
  // Base URL de Claude API
  static const String claudeBaseUrl = 'https://api.anthropic.com/v1';
  
  // Endpoints
  static const String messagesEndpoint = '/messages';
  
  // Versión de la API
  static const String apiVersion = '2023-06-01';
  
  // Modelo a usar
  static const String claudeModel = 'claude-3-5-sonnet-20241022';
  
  // Límites
  static const int maxTokens = 1024;
  static const int timeoutSeconds = 30;
  
  // Headers
  static const String contentTypeHeader = 'application/json';
  static const String apiKeyHeader = 'x-api-key';
  static const String apiVersionHeader = 'anthropic-version';
}