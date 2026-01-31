import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;

  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: 'http://localhost:8080', // Replace with actual backend URL
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  Dio get client => _dio;

  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
