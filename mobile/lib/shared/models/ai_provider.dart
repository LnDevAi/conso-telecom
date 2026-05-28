import 'ai_model.dart';

class AiProvider {
  final String id;
  final String name;
  final List<AiModel> models;

  const AiProvider({
    required this.id,
    required this.name,
    required this.models,
  });

  factory AiProvider.fromJson(Map<String, dynamic> json) {
    return AiProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      models: (json['models'] as List<dynamic>?)
              ?.map((m) => AiModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'models': models.map((m) => m.toJson()).toList(),
      };

  AiModel? findModel(String modelId) {
    try {
      return models.firstWhere((m) => m.id == modelId);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'AiProvider($id, $name, ${models.length} modèles)';
}
