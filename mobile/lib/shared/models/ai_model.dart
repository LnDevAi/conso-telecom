class AiModel {
  final String id;
  final String providerId;
  final String name;

  /// Prix d'entrée en USD par million de tokens
  final double inputPricePerMtokUsd;

  /// Prix de sortie en USD par million de tokens
  final double outputPricePerMtokUsd;

  const AiModel({
    required this.id,
    required this.providerId,
    required this.name,
    required this.inputPricePerMtokUsd,
    required this.outputPricePerMtokUsd,
  });

  factory AiModel.fromJson(Map<String, dynamic> json) {
    return AiModel(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      name: json['name'] as String,
      inputPricePerMtokUsd: (json['input_price_per_mtok_usd'] as num).toDouble(),
      outputPricePerMtokUsd: (json['output_price_per_mtok_usd'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider_id': providerId,
        'name': name,
        'input_price_per_mtok_usd': inputPricePerMtokUsd,
        'output_price_per_mtok_usd': outputPricePerMtokUsd,
      };

  /// Calcule le coût en USD pour une utilisation donnée de tokens.
  double computeCostUsd(int inputTokens, int outputTokens) {
    return (inputTokens / 1_000_000) * inputPricePerMtokUsd +
        (outputTokens / 1_000_000) * outputPricePerMtokUsd;
  }

  /// Prix moyen (heuristique: 80% input, 20% output) par MTok en USD.
  double get blendedPricePerMtok =>
      inputPricePerMtokUsd * 0.8 + outputPricePerMtokUsd * 0.2;

  @override
  String toString() => 'AiModel($id, $name)';
}
