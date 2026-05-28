import 'package:isar/isar.dart';

part 'alert_threshold.g.dart';

@Collection()
class AlertThreshold {
  Id id = Isar.autoIncrement;

  /// Type d'alerte: DATA_MB / COST_LOCAL / AI_COST_USD / VOICE_MINUTES
  @Index()
  late String type;

  late double value;

  @Index()
  late bool isEnabled;

  DateTime? lastTriggeredAt;

  AlertThreshold();

  AlertThreshold.create({
    required this.type,
    required this.value,
    this.isEnabled = true,
  });

  String get typeLabel {
    switch (type) {
      case 'DATA_MB':
        return 'Données mobiles';
      case 'COST_LOCAL':
        return 'Coût total (FCFA)';
      case 'AI_COST_USD':
        return 'Coût IA (USD)';
      case 'VOICE_MINUTES':
        return 'Appels (minutes)';
      default:
        return type;
    }
  }

  String get valueLabel {
    switch (type) {
      case 'DATA_MB':
        return '${value.toStringAsFixed(0)} Mo';
      case 'COST_LOCAL':
        return '${value.toStringAsFixed(0)} FCFA';
      case 'AI_COST_USD':
        return '\$${value.toStringAsFixed(2)}';
      case 'VOICE_MINUTES':
        return '${value.toStringAsFixed(0)} min';
      default:
        return value.toString();
    }
  }

  bool get canTriggerAgain {
    if (lastTriggeredAt == null) return true;
    return DateTime.now().difference(lastTriggeredAt!).inHours >= 4;
  }
}
