import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';

import '../../core/database/isar_service.dart';
import '../../core/database/models/plan.dart';

part 'plans_provider.g.dart';

@riverpod
Stream<List<Plan>> plans(Ref ref) {
  final isar = IsarService.instance;
  return isar.plans
      .where()
      .sortByExpiryDate()
      .watch(fireImmediately: true);
}

@riverpod
Stream<List<Plan>> activePlansList(Ref ref) {
  final isar = IsarService.instance;
  return isar.plans
      .filter()
      .isActiveEqualTo(true)
      .sortByExpiryDate()
      .watch(fireImmediately: true);
}

@riverpod
class PlanNotifier extends _$PlanNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addPlan(Plan plan) async {
    state = const AsyncValue.loading();
    try {
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.plans.put(plan);
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePlan(Plan plan) async {
    state = const AsyncValue.loading();
    try {
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.plans.put(plan);
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePlan(int id) async {
    state = const AsyncValue.loading();
    try {
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.plans.delete(id);
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deactivatePlan(int id) async {
    final isar = IsarService.instance;
    final plan = await isar.plans.get(id);
    if (plan == null) return;
    plan.isActive = false;
    await isar.writeTxn(() async {
      await isar.plans.put(plan);
    });
  }

  Future<void> dialUssdBalance(String operatorId) async {
    // Correspondance opérateur → code USSD
    const ussdCodes = {
      'orange_bf': '#123#',
      'telecel_bf': '#200#',
      'moov_bf': '#111#',
    };

    final code = ussdCodes[operatorId] ?? '#123#';

    try {
      const channel = MethodChannel('tech.edefence.consotelecom/network');
      await channel.invokeMethod('dialUssd', {'code': code});
    } on PlatformException catch (e) {
      debugPrint('dialUssd error: $e');
    }
  }
}
