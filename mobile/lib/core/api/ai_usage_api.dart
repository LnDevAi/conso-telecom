import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/database/models/ai_usage_record.dart';

class AiUsageApiException implements Exception {
  final String message;
  final String provider;
  final int? statusCode;

  const AiUsageApiException({
    required this.message,
    required this.provider,
    this.statusCode,
  });

  @override
  String toString() => 'AiUsageApiException[$provider]: $message (status: $statusCode)';
}

class AiUsageApi {
  AiUsageApi({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Récupère l'usage Anthropic entre [startDate] et [endDate].
  Future<List<AiUsageRecord>> fetchAnthropicUsage({
    required String decryptedKey,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        'https://api.anthropic.com/v1/usage',
        queryParameters: {
          'start_time': startDate.toUtc().toIso8601String(),
          'end_time': endDate.toUtc().toIso8601String(),
          'granularity': 'day',
        },
        options: Options(
          headers: {
            'x-api-key': decryptedKey,
            'anthropic-version': '2023-06-01',
          },
        ),
      );

      final records = <AiUsageRecord>[];
      final data = response.data;

      if (data is Map && data.containsKey('data')) {
        final usageList = data['data'] as List<dynamic>;
        for (final item in usageList) {
          final usage = item as Map<String, dynamic>;
          final models = usage['models'] as List<dynamic>? ?? [];

          for (final modelData in models) {
            final model = modelData as Map<String, dynamic>;
            final inputTokens = (model['input_tokens'] as num?)?.toInt() ?? 0;
            final outputTokens = (model['output_tokens'] as num?)?.toInt() ?? 0;
            final modelId = model['model_id'] as String? ?? 'unknown';

            // Calcul du coût basé sur le modèle
            final costUsd = _computeAnthropicCost(modelId, inputTokens, outputTokens);

            records.add(
              AiUsageRecord.create(
                timestamp: DateTime.parse(usage['timestamp'] as String? ?? DateTime.now().toIso8601String()),
                providerId: 'anthropic',
                modelId: modelId,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                costUsd: costUsd,
                costLocal: costUsd * 610.0, // Taux approximatif USD→XOF
                source: 'API',
              ),
            );
          }
        }
      }

      return records;
    } on DioException catch (e) {
      debugPrint('AiUsageApi.fetchAnthropicUsage error: $e');
      throw AiUsageApiException(
        message: e.message ?? 'Erreur réseau',
        provider: 'anthropic',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Récupère l'usage OpenAI entre [startDate] et [endDate].
  Future<List<AiUsageRecord>> fetchOpenAIUsage({
    required String decryptedKey,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        'https://api.openai.com/v1/usage',
        queryParameters: {
          'date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $decryptedKey',
          },
        ),
      );

      final records = <AiUsageRecord>[];
      final data = response.data;

      if (data is Map && data.containsKey('data')) {
        final usageList = data['data'] as List<dynamic>;
        for (final item in usageList) {
          final usage = item as Map<String, dynamic>;
          final inputTokens = (usage['n_context_tokens_total'] as num?)?.toInt() ?? 0;
          final outputTokens = (usage['n_generated_tokens_total'] as num?)?.toInt() ?? 0;
          final modelId = usage['snapshot_id'] as String? ?? 'gpt-4o';

          final costUsd = _computeOpenAICost(modelId, inputTokens, outputTokens);
          final timestamp = (usage['aggregation_timestamp'] as num?) != null
              ? DateTime.fromMillisecondsSinceEpoch((usage['aggregation_timestamp'] as num).toInt() * 1000)
              : DateTime.now();

          records.add(
            AiUsageRecord.create(
              timestamp: timestamp,
              providerId: 'openai',
              modelId: modelId,
              inputTokens: inputTokens,
              outputTokens: outputTokens,
              costUsd: costUsd,
              costLocal: costUsd * 610.0,
              source: 'API',
            ),
          );
        }
      }

      return records;
    } on DioException catch (e) {
      debugPrint('AiUsageApi.fetchOpenAIUsage error: $e');
      throw AiUsageApiException(
        message: e.message ?? 'Erreur réseau',
        provider: 'openai',
        statusCode: e.response?.statusCode,
      );
    }
  }

  double _computeAnthropicCost(String modelId, int inputTokens, int outputTokens) {
    double inputPrice = 3.0; // USD per MTok par défaut (Sonnet)
    double outputPrice = 15.0;

    if (modelId.contains('opus')) {
      inputPrice = 15.0;
      outputPrice = 75.0;
    } else if (modelId.contains('haiku')) {
      inputPrice = 0.8;
      outputPrice = 4.0;
    } else if (modelId.contains('sonnet')) {
      inputPrice = 3.0;
      outputPrice = 15.0;
    }

    return (inputTokens / 1_000_000) * inputPrice + (outputTokens / 1_000_000) * outputPrice;
  }

  double _computeOpenAICost(String modelId, int inputTokens, int outputTokens) {
    double inputPrice = 2.5;
    double outputPrice = 10.0;

    if (modelId.contains('gpt-4o-mini')) {
      inputPrice = 0.15;
      outputPrice = 0.6;
    } else if (modelId.contains('o1')) {
      inputPrice = 15.0;
      outputPrice = 60.0;
    }

    return (inputTokens / 1_000_000) * inputPrice + (outputTokens / 1_000_000) * outputPrice;
  }
}
