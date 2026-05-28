import 'package:isar/isar.dart';

part 'sms_record.g.dart';

@Collection()
class SmsRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime timestamp;

  /// Direction: sent / received
  @Index()
  late String direction;

  /// Slot SIM (0 ou 1)
  late int simSlot;

  SmsRecord();

  SmsRecord.create({
    required this.timestamp,
    required this.direction,
    required this.simSlot,
  });

  bool get isSent => direction == 'sent';
  bool get isReceived => direction == 'received';
}
