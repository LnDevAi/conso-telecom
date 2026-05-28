import 'package:isar/isar.dart';

part 'data_record.g.dart';

@Collection()
class DataRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime timestamp;

  @Index()
  late String packageName;

  late String appName;

  late long mobileRxBytes;
  late long mobileTxBytes;
  late long wifiRxBytes;
  late long wifiTxBytes;

  /// Numéro de slot SIM (0 ou 1)
  late int simSlot;

  /// Jour du cycle de facturation (1-31)
  late int cycleDay;

  DataRecord();

  DataRecord.create({
    required this.timestamp,
    required this.packageName,
    required this.appName,
    required this.mobileRxBytes,
    required this.mobileTxBytes,
    required this.wifiRxBytes,
    required this.wifiTxBytes,
    required this.simSlot,
    required this.cycleDay,
  });

  double get totalMobileMb => (mobileRxBytes + mobileTxBytes) / (1024 * 1024);
  double get totalWifiMb => (wifiRxBytes + wifiTxBytes) / (1024 * 1024);
  double get totalMb => totalMobileMb + totalWifiMb;
}
