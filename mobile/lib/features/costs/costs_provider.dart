import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';

import '../../core/database/isar_service.dart';
import '../../core/database/models/data_record.dart';
import '../../core/database/models/call_record.dart';
import '../../core/database/models/sms_record.dart';
import '../../core/database/models/plan.dart';
import '../../core/database/models/ai_usage_record.dart';
import '../../shared/widgets/period_selector.dart';
import 'cost_engine.dart';

part 'costs_provider.g.dart';

class CostBreakdown {
  final double dataCostFcfa;
  final double callCostFcfa;
  final double smsCostFcfa;
  final double aiCostFcfa;
  final double aiCostUsd;
  final double totalFcfa;
  final double? actualFcfa; // Saisi par l'utilisateur
  final DateTime periodStart;
  final DateTime periodEnd;

  const CostBreakdown({
    required this.dataCostFcfa,
    required this.callCostFcfa,
    required this.smsCostFcfa,
    required this.aiCostFcfa,
    required this.aiCostUsd,
    required this.totalFcfa,
    this.actualFcfa,
    required this.periodStart,
    required this.periodEnd,
  });

  double get telecomCostFcfa => dataCostFcfa + callCostFcfa + smsCostFcfa;

  double get variancePercent {
    if (actualFcfa == null || totalFcfa == 0) return 0;
    return ((actualFcfa! - totalFcfa) / totalFcfa) * 100;
  }

  static const empty = CostBreakdown(
    dataCostFcfa: 0,
    callCostFcfa: 0,
    smsCostFcfa: 0,
    aiCostFcfa: 0,
    aiCostUsd: 0,
    totalFcfa: 0,
    periodStart: _epoch,
    periodEnd: _epoch,
  );

  static const _epoch = DateTime.utc(2020);
}

@riverpod
Future<CostBreakdown> costBreakdown(
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

  // Données mobiles
  final dataRecords = await isar.dataRecords
      .filter()
      .timestampBetween(startDate, now)
      .findAll();

  double totalMobileBytes = 0;
  for (final r in dataRecords) {
    totalMobileBytes += r.mobileRxBytes + r.mobileTxBytes;
  }

  // Appels
  final callRecords = await isar.callRecords
      .filter()
      .timestampBetween(startDate, now)
      .callTypeEqualTo('outgoing')
      .findAll();

  double totalCallMinutes = 0;
  int onNetCount = 0;
  for (final r in callRecords) {
    totalCallMinutes += r.durationMinutes;
    if (r.isOnNet) onNetCount++;
  }
  final onNetRatio = callRecords.isEmpty ? 0.6 : onNetCount / callRecords.length;

  // SMS
  final smsCount = await isar.smsRecords
      .filter()
      .timestampBetween(startDate, now)
      .directionEqualTo('sent')
      .count();

  // Plans actifs
  final activePlans = await isar.plans.filter().isActiveEqualTo(true).findAll();
  final dataplan = activePlans.where((p) => p.isDataPlan).firstOrNull;
  final voicePlan = activePlans.where((p) => p.isVoicePlan).firstOrNull;

  // Calcul coûts télécom
  final dataCost = CostEngine.calculateDataCost(
    mobileBytes: totalMobileBytes,
    activePlan: dataplan,
    unitPricePerMb: 5.0,
  );

  final callCost = CostEngine.calculateCallCost(
    minutes: totalCallMinutes,
    onNetRatio: onNetRatio,
    activePlan: voicePlan,
    onNetPerMin: 35.0,
    offNetPerMin: 60.0,
  );

  final smsCost = smsCount * 15.0;

  // Usage IA
  final aiRecords = await isar.aiUsageRecords
      .filter()
      .timestampBetween(startDate, now)
      .findAll();

  double aiCostUsd = 0;
  double aiCostLocal = 0;
  for (final r in aiRecords) {
    aiCostUsd += r.costUsd;
    aiCostLocal += r.costLocal;
  }

  final total = dataCost + callCost + smsCost + aiCostLocal;

  return CostBreakdown(
    dataCostFcfa: dataCost,
    callCostFcfa: callCost,
    smsCostFcfa: smsCost,
    aiCostFcfa: aiCostLocal,
    aiCostUsd: aiCostUsd,
    totalFcfa: total,
    periodStart: startDate,
    periodEnd: now,
  );
}
