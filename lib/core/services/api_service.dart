import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kreatif_laundrymu_app/core/services/log_service.dart';

class ApiService {
  final Dio _dio;
  final LogService _logService = LogService();

  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: 'http://localhost:8080',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ));

  Dio get client => _dio;

  void setBaseUrl(String url) {
    if (!url.startsWith('http')) {
       url = 'http://$url';
    }
    _dio.options.baseUrl = url;
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<String?> login(String username, String password) async {
    // Log request (mask password)
    await _logService.logRequest('auth_login', {
      'username': username, 
      'password': '***'
    });

    try {
      final response = await _dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });

      // Log success response
      await _logService.logResponse('auth_login', response.data);

      if (response.data['code'] == 200) {
        final token = response.data['data']['token'];
        return token;
      }
      return null;
    } catch (e) {
      // Log error
      await _logService.logResponse('auth_login', null, error: e);
      return null;
    }
  }

  Future<Response> executeFlow(String flowName, String menu, Map<String, dynamic> data) async {
    // Log the request
    await _logService.logRequest(flowName, data);

    // Basic FormData construction
    final formData = FormData.fromMap({
      'flowname': flowName,
      'menu': menu,
      'search': 'true',
    });

    data.forEach((key, value) {
      if (value != null) {
        if (value is Map || value is List) {
          formData.fields.add(MapEntry(key, jsonEncode(value)));
        } else if (value is bool) {
          formData.fields.add(MapEntry(key, value ? '1' : '0'));
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      }
    });

    try {
      // Assuming a standard endpoint for flow execution, similar to pos
      final response = await _dio.post('/api/flow/execute', data: formData);
      
      // Log the success response
      await _logService.logResponse(flowName, response.data);

      return response;
    } catch (e) {
      // Log the error
      await _logService.logResponse(flowName, null, error: e);
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    try {
      // Simple health check or ping
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
