import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';

import '../../core/database/isar_service.dart';
import '../../core/database/models/data_record.dart';
import '../../shared/widgets/period_selector.dart';

part 'data_usage_provider.g.dart';

const _channel = MethodChannel('tech.edefence.consotelecom/network');

class AppDataUsage {
  final String packageName;
  final String appName;
  final double mobileRxBytes;
  final double mobileTxBytes;
  final double wifiRxBytes;
  final double wifiTxBytes;

  const AppDataUsage({
    required this.packageName,
    required this.appName,
    required this.mobileRxBytes,
    required this.mobileTxBytes,
    required this.wifiRxBytes,
    required this.wifiTxBytes,
  });

  double get totalMobileMb => (mobileRxBytes + mobileTxBytes) / (1024 * 1024);
  double get totalWifiMb => (wifiRxBytes + wifiTxBytes) / (1024 * 1024);
  double get totalMb => totalMobileMb + totalWifiMb;
}

class DailyDataPoint {
  final DateTime date;
  final double mobileMb;
  final double wifiMb;

  const DailyDataPoint({
    required this.date,
    required this.mobileMb,
    required this.wifiMb,
  });
}

class DataUsageState {
  final List<DailyDataPoint> dailyPoints;
  final List<AppDataUsage> perAppUsage;
  final double totalMobileMb;
  final double totalWifiMb;

  const DataUsageState({
    required this.dailyPoints,
    required this.perAppUsage,
    required this.totalMobileMb,
    required this.totalWifiMb,
  });

  static const empty = DataUsageState(
    dailyPoints: [],
    perAppUsage: [],
    totalMobileMb: 0,
    totalWifiMb: 0,
  );
}

@riverpod
Future<DataUsageState> dataUsage(
  Ref ref,
  PeriodOption period,
) async {
  final isar = IsarService.instance;
  final now = DateTime.now();

  DateTime startDate;
  switch (period) {
    case PeriodOption.jour:
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case PeriodOption.semaine:
      startDate = now.subtract(const Duration(days: 7));
      break;
    case PeriodOption.mois:
      startDate = DateTime(now.year, now.month, 1);
      break;
    case PeriodOption.cycle:
      startDate = DateTime(now.year, now.month, 1);
      break;
  }

  // Rafraîchir les stats réseau via MethodChannel
  await _refreshNetworkStats(isar);

  // Lire depuis Isar
  final records = await isar.dataRecords
      .filter()
      .timestampBetween(startDate, now)
      .sortByTimestamp()
      .findAll();

  // Agréger par jour
  final dayMap = <String, DailyDataPoint>{};
  for (final r in records) {
    final dayKey = '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}-${r.timestamp.day.toString().padLeft(2, '0')}';
    final existing = dayMap[dayKey];
    if (existing == null) {
      dayMap[dayKey] = DailyDataPoint(
        date: DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day),
        mobileMb: (r.mobileRxBytes + r.mobileTxBytes) / (1024 * 1024),
        wifiMb: (r.wifiRxBytes + r.wifiTxBytes) / (1024 * 1024),
      );
    } else {
      dayMap[dayKey] = DailyDataPoint(
        date: existing.date,
        mobileMb: existing.mobileMb + (r.mobileRxBytes + r.mobileTxBytes) / (1024 * 1024),
        wifiMb: existing.wifiMb + (r.wifiRxBytes + r.wifiTxBytes) / (1024 * 1024),
      );
    }
  }

  // Agréger par application
  final appMap = <String, AppDataUsage>{};
  for (final r in records) {
    final existing = appMap[r.packageName];
    if (existing == null) {
      appMap[r.packageName] = AppDataUsage(
        packageName: r.packageName,
        appName: r.appName,
        mobileRxBytes: r.mobileRxBytes.toDouble(),
        mobileTxBytes: r.mobileTxBytes.toDouble(),
        wifiRxBytes: r.wifiRxBytes.toDouble(),
        wifiTxBytes: r.wifiTxBytes.toDouble(),
      );
    } else {
      appMap[r.packageName] = AppDataUsage(
        packageName: r.packageName,
        appName: r.appName,
        mobileRxBytes: existing.mobileRxBytes + r.mobileRxBytes,
        mobileTxBytes: existing.mobileTxBytes + r.mobileTxBytes,
        wifiRxBytes: existing.wifiRxBytes + r.wifiRxBytes,
        wifiTxBytes: existing.wifiTxBytes + r.wifiTxBytes,
      );
    }
  }

  final sortedApps = appMap.values.toList()
    ..sort((a, b) => b.totalMb.compareTo(a.totalMb));

  double totalMobile = 0;
  double totalWifi = 0;
  for (final r in records) {
    totalMobile += (r.mobileRxBytes + r.mobileTxBytes) / (1024 * 1024);
    totalWifi += (r.wifiRxBytes + r.wifiTxBytes) / (1024 * 1024);
  }

  return DataUsageState(
    dailyPoints: dayMap.values.toList()..sort((a, b) => a.date.compareTo(b.date)),
    perAppUsage: sortedApps,
    totalMobileMb: totalMobile,
    totalWifiMb: totalWifi,
  );
}

Future<void> _refreshNetworkStats(Isar isar) async {
  try {
    final result = await _channel.invokeMethod<String>('getNetworkStatsPerApp');
    if (result == null) return;

    final List<dynamic> apps = jsonDecode(result) as List<dynamic>;
    final now = DateTime.now();

    await isar.writeTxn(() async {
      for (final app in apps) {
        final data = app as Map<String, dynamic>;
        final record = DataRecord.create(
          timestamp: now,
          packageName: data['package_name'] as String,
          appName: data['app_name'] as String,
          mobileRxBytes: (data['mobile_rx'] as num).toInt(),
          mobileTxBytes: (data['mobile_tx'] as num).toInt(),
          wifiRxBytes: (data['wifi_rx'] as num).toInt(),
          wifiTxBytes: (data['wifi_tx'] as num).toInt(),
          simSlot: 0,
          cycleDay: now.day,
        );
        await isar.dataRecords.put(record);
      }
    });
  } on PlatformException catch (e) {
    debugPrint('_refreshNetworkStats error: $e');
  } catch (e) {
    debugPrint('_refreshNetworkStats unexpected error: $e');
  }
}
