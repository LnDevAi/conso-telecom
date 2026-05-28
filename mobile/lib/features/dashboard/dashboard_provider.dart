import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';

import '../../core/database/isar_service.dart';
import '../../core/database/models/data_record.dart';
import '../../core/database/models/call_record.dart';
import '../../core/database/models/sms_record.dart';
import '../../core/database/models/plan.dart';
import '../../core/database/models/ai_usage_record.dart';
import '../../core/database/models/alert_threshold.dart';

part 'dashboard_provider.g.dart';

class DashboardStats {
  final double dataMobileBytes;
  final double dataWifiBytes;
  final double callsMinutes;
  final int smsCount;
  final int aiTokensTotal;
  final double aiCostUsd;
  final double estimatedCostFcfa;
  final DateTime periodStart;
  final DateTime periodEnd;

  const DashboardStats({
    required this.dataMobileBytes,
    required this.dataWifiBytes,
    required this.callsMinutes,
    required this.smsCount,
    required this.aiTokensTotal,
    required this.aiCostUsd,
    required this.estimatedCostFcfa,
    required this.periodStart,
    required this.periodEnd,
  });

  double get dataMobileMb => dataMobileBytes / (1024 * 1024);
  double get dataWifiMb => dataWifiBytes / (1024 * 1024);
  double get dataMobileGb => dataMobileMb / 1024;
  int get daysInPeriod => periodEnd.difference(periodStart).inDays + 1;
  double get dailyAverageCostFcfa =>
      daysInPeriod > 0 ? estimatedCostFcfa / daysInPeriod : 0;

  static const empty = DashboardStats(
    dataMobileBytes: 0,
    dataWifiBytes: 0,
    callsMinutes: 0,
    smsCount: 0,
    aiTokensTotal: 0,
    aiCostUsd: 0,
    estimatedCostFcfa: 0,
    periodStart: _epoch,
    periodEnd: _epoch,
  );

  static const _epoch = DateTime.utc(2020);
}

@riverpod
Future<DashboardStats> dashboardStats(Ref ref) async {
  final isar = IsarService.instance;
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // Données mobiles du mois
  final dataRecords = await isar.dataRecords
      .filter()
      .timestampBetween(startOfMonth, endOfMonth)
      .findAll();

  double totalMobileRx = 0;
  double totalMobileTx = 0;
  double totalWifiRx = 0;
  double totalWifiTx = 0;

  for (final record in dataRecords) {
    totalMobileRx += record.mobileRxBytes;
    totalMobileTx += record.mobileTxBytes;
    totalWifiRx += record.wifiRxBytes;
    totalWifiTx += record.wifiTxBytes;
  }

  // Appels du mois
  final callRecords = await isar.callRecords
      .filter()
      .timestampBetween(startOfMonth, endOfMonth)
      .callTypeEqualTo('outgoing')
      .findAll();

  double totalCallMinutes = callRecords.fold(
    0.0,
    (sum, r) => sum + r.durationMinutes,
  );

  // SMS du mois
  final smsCount = await isar.smsRecords
      .filter()
      .timestampBetween(startOfMonth, endOfMonth)
      .directionEqualTo('sent')
      .count();

  // Usage IA du mois
  final aiRecords = await isar.aiUsageRecords
      .filter()
      .timestampBetween(startOfMonth, endOfMonth)
      .findAll();

  int totalAiTokens = 0;
  double totalAiCostUsd = 0;
  double totalAiCostLocal = 0;

  for (final record in aiRecords) {
    totalAiTokens += record.totalTokens;
    totalAiCostUsd += record.costUsd;
    totalAiCostLocal += record.costLocal;
  }

  // Estimation coût télécom (simplifié, sans plan actif)
  final dataCostFcfa = (totalMobileRx + totalMobileTx) / (1024 * 1024) * 5.0;
  final callCostFcfa = totalCallMinutes * 45.0;
  final smsCostFcfa = smsCount * 15.0;
  final estimatedTotal = dataCostFcfa + callCostFcfa + smsCostFcfa + totalAiCostLocal;

  return DashboardStats(
    dataMobileBytes: totalMobileRx + totalMobileTx,
    dataWifiBytes: totalWifiRx + totalWifiTx,
    callsMinutes: totalCallMinutes,
    smsCount: smsCount,
    aiTokensTotal: totalAiTokens,
    aiCostUsd: totalAiCostUsd,
    estimatedCostFcfa: estimatedTotal,
    periodStart: startOfMonth,
    periodEnd: endOfMonth,
  );
}

@riverpod
Stream<List<Plan>> activePlans(Ref ref) {
  final isar = IsarService.instance;
  return isar.plans
      .filter()
      .isActiveEqualTo(true)
      .sortByExpiryDate()
      .watch(fireImmediately: true);
}

@riverpod
Stream<List<AlertThreshold>> triggeredAlerts(Ref ref) {
  final isar = IsarService.instance;
  return isar.alertThresholds
      .filter()
      .isEnabledEqualTo(true)
      .watch(fireImmediately: true);
}
