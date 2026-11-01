import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

/// Exception personnalisée pour les erreurs de communication API.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}

/// Client REST générique prêt pour le raccordement avec le backend réel.
class ApiClient {
  final http.Client _client;
  final SecureStorageService _secureStorage;
  final String _baseUrl;

  ApiClient({
    http.Client? client,
    SecureStorageService? secureStorage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorageService(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<Map<String, String>> _buildHeaders() async {
    final token = await _secureStorage.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Exécute une requête GET
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _buildHeaders();

    try {
      final response = await _client.get(uri, headers: headers).timeout(AppConfig.requestTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'Impossible de joindre le serveur. Vérifiez votre réseau.');
    }
  }

  /// Exécute une requête POST
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _buildHeaders();

    try {
      final response = await _client
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(AppConfig.requestTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'Impossible de joindre le serveur. Vérifiez votre réseau.');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Erreur serveur HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {}
      throw ApiException(statusCode: response.statusCode, message: errorMessage);
    }
  }

  void close() {
    _client.close();
  }
}
