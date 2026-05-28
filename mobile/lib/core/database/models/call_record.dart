import 'package:isar/isar.dart';

part 'call_record.g.dart';

@Collection()
class CallRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime timestamp;

  /// Durée en secondes
  late int durationSeconds;

  /// Type d'appel: incoming / outgoing / missed
  @Index()
  late String callType;

  /// Appel dans le réseau de l'opérateur (on-net)
  late bool isOnNet;

  /// Slot SIM utilisé (0 ou 1)
  late int simSlot;

  CallRecord();

  CallRecord.create({
    required this.timestamp,
    required this.durationSeconds,
    required this.callType,
    required this.isOnNet,
    required this.simSlot,
  });

  double get durationMinutes => durationSeconds / 60.0;

  bool get isIncoming => callType == 'incoming';
  bool get isOutgoing => callType == 'outgoing';
  bool get isMissed => callType == 'missed';
}
