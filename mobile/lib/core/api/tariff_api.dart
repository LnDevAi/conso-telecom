import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/country.dart';
import '../../shared/models/operator.dart';
import '../../shared/models/ai_provider.dart';
import '../../shared/models/ai_model.dart';
import '../../shared/models/exchange_rate.dart';

class TariffApiException implements Exception {
  final String message;
  final int? statusCode;
  const TariffApiException(this.message, {this.statusCode});

  @override
  String toString() => 'TariffApiException: $message (status: $statusCode)';
}

class TariffApi {
  TariffApi({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  // URL de base — changer pour production
  static const String _baseUrl = 'http://localhost:8000/api/v1';

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'fr',
        },
      ),
    )..interceptors.add(
        LogInterceptor(
          requestBody: kDebugMode,
          responseBody: kDebugMode,
          error: true,
        ),
      );
  }

  /// Récupère la liste des pays supportés.
  Future<List<Country>> fetchCountries() async {
    try {
      final response = await _dio.get('/countries');
      final data = response.data as List<dynamic>;
      return data.map((j) => Country.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      debugPrint('TariffApi.fetchCountries error: $e');
      return _fallbackCountries();
    }
  }

  /// Récupère les opérateurs d'un pays.
  Future<List<Operator>> fetchOperators(String countryCode) async {
    try {
      final response = await _dio.get('/operators', queryParameters: {'country': countryCode});
      final data = response.data as List<dynamic>;
      return data.map((j) => Operator.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      debugPrint('TariffApi.fetchOperators error: $e');
      return _fallbackOperators(countryCode);
    }
  }

  /// Récupère la liste des fournisseurs IA et leurs modèles.
  Future<List<AiProvider>> fetchAiProviders() async {
    try {
      final response = await _dio.get('/ai-providers');
      final data = response.data as List<dynamic>;
      return data.map((j) => AiProvider.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      debugPrint('TariffApi.fetchAiProviders error: $e');
      return _fallbackAiProviders();
    }
  }

  /// Récupère les taux de change.
  Future<List<ExchangeRate>> fetchExchangeRates() async {
    try {
      final response = await _dio.get('/exchange-rates');
      final data = response.data as List<dynamic>;
      return data.map((j) => ExchangeRate.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      debugPrint('TariffApi.fetchExchangeRates error: $e');
      return _fallbackExchangeRates();
    }
  }

  // ---- Données de secours (hors-ligne) ----

  List<Country> _fallbackCountries() {
    return [
      Country(
        code: 'BF',
        nameFr: 'Burkina Faso',
        nameEn: 'Burkina Faso',
        defaultCurrency: 'XOF',
        operators: _fallbackOperators('BF'),
      ),
    ];
  }

  List<Operator> _fallbackOperators(String countryCode) {
    if (countryCode != 'BF') return [];
    return [
      Operator(
        id: 'orange_bf',
        name: 'Orange Burkina Faso',
        countryCode: 'BF',
        ussdBalanceCode: '#123#',
        plans: [],
        unitTariff: UnitTariff(
          dataPricePerMb: 5.0,
          onNetPerMin: 35.0,
          offNetPerMin: 60.0,
          smsPriceLocal: 15.0,
          currency: 'XOF',
        ),
      ),
      Operator(
        id: 'telecel_bf',
        name: 'Telecel Burkina Faso',
        countryCode: 'BF',
        ussdBalanceCode: '#200#',
        plans: [],
        unitTariff: UnitTariff(
          dataPricePerMb: 4.0,
          onNetPerMin: 30.0,
          offNetPerMin: 55.0,
          smsPriceLocal: 15.0,
          currency: 'XOF',
        ),
      ),
      Operator(
        id: 'moov_bf',
        name: 'Moov Africa Burkina',
        countryCode: 'BF',
        ussdBalanceCode: '#111#',
        plans: [],
        unitTariff: UnitTariff(
          dataPricePerMb: 4.5,
          onNetPerMin: 32.0,
          offNetPerMin: 58.0,
          smsPriceLocal: 15.0,
          currency: 'XOF',
        ),
      ),
    ];
  }

  List<AiProvider> _fallbackAiProviders() {
    return [
      AiProvider(
        id: 'anthropic',
        name: 'Anthropic',
        models: [
          AiModel(id: 'claude-opus-4-5', providerId: 'anthropic', name: 'Claude Opus 4.5', inputPricePerMtokUsd: 15.0, outputPricePerMtokUsd: 75.0),
          AiModel(id: 'claude-sonnet-4-5', providerId: 'anthropic', name: 'Claude Sonnet 4.5', inputPricePerMtokUsd: 3.0, outputPricePerMtokUsd: 15.0),
          AiModel(id: 'claude-haiku-3-5', providerId: 'anthropic', name: 'Claude Haiku 3.5', inputPricePerMtokUsd: 0.8, outputPricePerMtokUsd: 4.0),
        ],
      ),
      AiProvider(
        id: 'openai',
        name: 'OpenAI',
        models: [
          AiModel(id: 'gpt-4o', providerId: 'openai', name: 'GPT-4o', inputPricePerMtokUsd: 2.5, outputPricePerMtokUsd: 10.0),
          AiModel(id: 'gpt-4o-mini', providerId: 'openai', name: 'GPT-4o mini', inputPricePerMtokUsd: 0.15, outputPricePerMtokUsd: 0.6),
          AiModel(id: 'o1', providerId: 'openai', name: 'o1', inputPricePerMtokUsd: 15.0, outputPricePerMtokUsd: 60.0),
        ],
      ),
      AiProvider(
        id: 'google',
        name: 'Google',
        models: [
          AiModel(id: 'gemini-2.0-flash', providerId: 'google', name: 'Gemini 2.0 Flash', inputPricePerMtokUsd: 0.075, outputPricePerMtokUsd: 0.3),
          AiModel(id: 'gemini-1.5-pro', providerId: 'google', name: 'Gemini 1.5 Pro', inputPricePerMtokUsd: 1.25, outputPricePerMtokUsd: 5.0),
        ],
      ),
      AiProvider(
        id: 'mistral',
        name: 'Mistral',
        models: [
          AiModel(id: 'mistral-large', providerId: 'mistral', name: 'Mistral Large', inputPricePerMtokUsd: 2.0, outputPricePerMtokUsd: 6.0),
          AiModel(id: 'mistral-small', providerId: 'mistral', name: 'Mistral Small', inputPricePerMtokUsd: 0.1, outputPricePerMtokUsd: 0.3),
        ],
      ),
    ];
  }

  List<ExchangeRate> _fallbackExchangeRates() {
    return [
      ExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'XOF',
        rate: 610.0,
        effectiveDate: DateTime.now(),
      ),
      ExchangeRate(
        fromCurrency: 'EUR',
        toCurrency: 'XOF',
        rate: 655.957,
        effectiveDate: DateTime.now(),
      ),
    ];
  }
}
