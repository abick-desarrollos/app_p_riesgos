/// Servicio para realizar llamadas HTTP a la API de ABICK NC.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class ApiService {
  static final String baseUrl = AppConfig.apiBaseUrl;

  /// Construye los headers comunes, incluyendo el JWT si existe.
  static Future<Map<String, String>> _headers() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Realiza una solicitud GET a la API.
  ///
  /// Devuelve el cuerpo de la respuesta decodificado como Map o List.
  /// Lanza [ApiException] si la conexión falla o si la API
  /// devuelve un código de estado de error.
  static Future<dynamic> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();

    print('=== API REQUEST ===');
    print('URL: $uri');
    print('Method: GET');
    print('===================');

    final response = await http.get(uri, headers: headers);

    print('=== API RESPONSE ===');
    print('Status: ${response.statusCode}');
    final truncatedBody = response.body.length > 200
        ? '${response.body.substring(0, 200)}...'
        : response.body;
    print('Body: $truncatedBody');
    print('====================');

    if (response.statusCode >= 400) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded['error'] ?? 'Error desconocido',
      );
    }

    return json.decode(response.body);
  }

  /// Realiza una solicitud PUT a la API.
  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();

    final response = await http.put(
      uri,
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode >= 400) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded['error'] ?? 'Error desconocido',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Realiza una solicitud POST a la API.
  ///
  /// Devuelve el cuerpo de la respuesta decodificado como Map.
  /// Lanza una excepción si la conexión falla o si la API
  /// devuelve un código de estado de error.
  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();

    print('=== API REQUEST ===');
    print('URL: $uri');
    print('Method: POST');
    final safeBody = body != null ? json.encode(body).replaceAll(body['contrasena'] ?? '', '[HIDDEN]') : 'null';
    print('Body: $safeBody');
    print('===================');

    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    print('=== API RESPONSE ===');
    print('Status: ${response.statusCode}');
    final truncatedBody = response.body.length > 200
        ? '${response.body.substring(0, 200)}...'
        : response.body;
    print('Body: $truncatedBody');
    print('====================');

    final decoded = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded['error'] ?? 'Error desconocido',
      );
    }

    return decoded;
  }

  /// Sube fotografías a una no conformidad mediante multipart/form-data.
  ///
  /// Devuelve el cuerpo de la respuesta decodificado como Map.
  /// Lanza [ApiException] si la conexión falla o si la API
  /// devuelve un código de estado de error.
  static Future<Map<String, dynamic>> postFotos(
    String path, {
    required List<File> files,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await SecureStorage.getToken();

    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    for (final file in files) {
      final contentType = _getContentType(file.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto',
          file.path,
          contentType: contentType,
        ),
      );
    }

    print('=== API REQUEST ===');
    print('URL: $uri');
    print('Method: POST (multipart)');
    print('Files: ${files.length}');
    print('===================');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('=== API RESPONSE ===');
    print('Status: ${response.statusCode}');
    final truncatedBody = response.body.length > 200
        ? '${response.body.substring(0, 200)}...'
        : response.body;
    print('Body: $truncatedBody');
    print('====================');

    if (response.statusCode >= 400) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded['error'] ?? 'Error desconocido',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Determina el tipo MIME según la extensión del archivo.
  static MediaType _getContentType(String filePath) {
    final ext = filePath.substring(filePath.lastIndexOf('.')).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}

/// Excepción personalizada para errores de la API.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'APIException($statusCode): $message';
}
