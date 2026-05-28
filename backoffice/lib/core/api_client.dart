import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _tokenKey = 'admin_jwt_token';
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

const _storage = FlutterSecureStorage();

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<String> login(String email, String password) async {
    final resp = await _dio.post('/admin/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = resp.data['access_token'] as String;
    await _storage.write(key: _tokenKey, value: token);
    return token;
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> get isLoggedIn async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  Future<Map<String, dynamic>> getMe() async {
    final resp = await _dio.get('/admin/auth/me');
    return resp.data as Map<String, dynamic>;
  }

  // ── Countries ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getCountries() async {
    final resp = await _dio.get('/admin/countries');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createCountry(Map<String, dynamic> data) async {
    final resp = await _dio.post('/admin/countries', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCountry(String code, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/admin/countries/$code', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteCountry(String code) async {
    await _dio.delete('/admin/countries/$code');
  }

  // ── Operators ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getOperators() async {
    final resp = await _dio.get('/admin/operators');
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getOperatorsForCountry(String countryCode) async {
    final resp = await _dio.get('/tariffs/operators/$countryCode');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createOperator(Map<String, dynamic> data) async {
    final resp = await _dio.post('/admin/operators', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateOperator(String id, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/admin/operators/$id', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteOperator(String id) async {
    await _dio.delete('/admin/operators/$id');
  }

  // ── Tariff Plans ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getPlansForOperator(String operatorId) async {
    final resp = await _dio.get('/admin/operators/$operatorId/plans');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createPlan(String operatorId, Map<String, dynamic> data) async {
    final resp = await _dio.post('/admin/operators/$operatorId/plans', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePlan(String operatorId, String planId, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/admin/operators/$operatorId/plans/$planId', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deletePlan(String operatorId, String planId) async {
    await _dio.delete('/admin/operators/$operatorId/plans/$planId');
  }

  // ── Unit Tariffs ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getUnitTariffsForOperator(String operatorId) async {
    final resp = await _dio.get('/admin/operators/$operatorId/unit-tariffs');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createUnitTariff(String operatorId, Map<String, dynamic> data) async {
    final resp = await _dio.post('/admin/operators/$operatorId/unit-tariffs', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteUnitTariff(String operatorId, String tariffId) async {
    await _dio.delete('/admin/operators/$operatorId/unit-tariffs/$tariffId');
  }

  // ── AI Providers ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getAiProviders() async {
    final resp = await _dio.get('/admin/ai/providers');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createAiProvider(Map<String, dynamic> data) async {
    final resp = await _dio.post('/admin/ai/providers', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAiProvider(String id, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/admin/ai/providers/$id', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteAiProvider(String id) async {
    await _dio.delete('/admin/ai/providers/$id');
  }

  // ── AI Models ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getAiModels(String providerId) async {
    final resp = await _dio.get('/admin/ai/providers/$providerId/models');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createAiModel(String providerId, Map<String, dynamic> data) async {
    final resp = await _dio.post('/admin/ai/providers/$providerId/models', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAiModel(String providerId, String modelId, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/admin/ai/providers/$providerId/models/$modelId', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteAiModel(String providerId, String modelId) async {
    await _dio.delete('/admin/ai/providers/$providerId/models/$modelId');
  }

  // ── Exchange Rates ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getExchangeRates() async {
    final resp = await _dio.get('/admin/exchange-rates');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createExchangeRate(Map<String, dynamic> data) async {
    final resp = await _dio.post('/admin/exchange-rates', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> refreshExchangeRates() async {
    final resp = await _dio.post('/admin/exchange-rates/refresh');
    return resp.data as List<dynamic>;
  }

  // ── Dashboard stats ────────────────────────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([
      getCountries(),
      getOperators(),
      getAiProviders(),
      getExchangeRates(),
    ]);
    return {
      'countries': results[0].length,
      'operators': results[1].length,
      'ai_providers': results[2].length,
      'exchange_rates': results[3].length,
    };
  }
}
