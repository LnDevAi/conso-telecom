import '../../core/database/models/plan.dart';
import '../../shared/models/ai_model.dart';
import '../../shared/models/exchange_rate.dart';

/// Résultat du calcul de coût IA
class AiCostResult {
  final double usd;
  final double local;

  const AiCostResult({required this.usd, required this.local});
}

/// Moteur de calcul des coûts télécom et IA.
/// Dépendances pures Dart — aucune dépendance Flutter.
class CostEngine {
  const CostEngine._();

  // ─── Données mobiles ──────────────────────────────────────────────────────

  /// Calcule le coût des données mobiles en FCFA.
  ///
  /// Logique: épuiser d'abord le forfait DATA actif, puis facturer
  /// le surplus au tarif unitaire [unitPricePerMb].
  static double calculateDataCost({
    required double mobileBytes,
    required Plan? activePlan,
    required double unitPricePerMb,
  }) {
    final mobileMb = mobileBytes / (1024 * 1024);

    if (activePlan == null || !activePlan.isDataPlan || activePlan.dataLimitMb == null) {
      // Pas de forfait: tarif unitaire pur
      return mobileMb * unitPricePerMb;
    }

    final planMb = activePlan.dataLimitMb!;

    if (mobileMb <= planMb) {
      // Tout consommé dans le forfait → coût = prix forfait (déjà payé)
      // On retourne le coût proratisé du forfait
      final fraction = planMb > 0 ? mobileMb / planMb : 0.0;
      return activePlan.priceFcfa * fraction;
    } else {
      // Surplus au-delà du forfait
      final surplusMb = mobileMb - planMb;
      return activePlan.priceFcfa + (surplusMb * unitPricePerMb);
    }
  }

  // ─── Appels ───────────────────────────────────────────────────────────────

  /// Calcule le coût des appels en FCFA.
  ///
  /// [minutes] total des minutes sortantes.
  /// [onNetRatio] proportion d'appels dans le réseau (0.0–1.0).
  /// [activePlan] forfait voix actif (peut être null).
  /// [onNetPerMin] tarif on-net en FCFA/min.
  /// [offNetPerMin] tarif off-net en FCFA/min.
  static double calculateCallCost({
    required double minutes,
    required double onNetRatio,
    required Plan? activePlan,
    required double onNetPerMin,
    required double offNetPerMin,
  }) {
    if (activePlan != null && activePlan.isVoicePlan && activePlan.voiceLimitMinutes != null) {
      final planMinutes = activePlan.voiceLimitMinutes!;

      if (minutes <= planMinutes) {
        // Dans le forfait
        final fraction = planMinutes > 0 ? minutes / planMinutes : 0.0;
        return activePlan.priceFcfa * fraction;
      } else {
        // Surplus
        final surplusMinutes = minutes - planMinutes;
        final onNetSurplus = surplusMinutes * onNetRatio;
        final offNetSurplus = surplusMinutes * (1 - onNetRatio);
        return activePlan.priceFcfa +
            (onNetSurplus * onNetPerMin) +
            (offNetSurplus * offNetPerMin);
      }
    }

    // Tarif unitaire
    final onNetMinutes = minutes * onNetRatio;
    final offNetMinutes = minutes * (1 - onNetRatio);
    return (onNetMinutes * onNetPerMin) + (offNetMinutes * offNetPerMin);
  }

  // ─── Tokens IA ────────────────────────────────────────────────────────────

  /// Calcule le coût IA en USD et en monnaie locale.
  ///
  /// [exchangeRate] taux de conversion USD → monnaie locale.
  static AiCostResult calculateAiCost({
    required int inputTokens,
    required int outputTokens,
    required AiModel model,
    required double exchangeRate,
  }) {
    final costUsd = model.computeCostUsd(inputTokens, outputTokens);
    final costLocal = costUsd * exchangeRate;
    return AiCostResult(usd: costUsd, local: costLocal);
  }

  // ─── Conversion devises ───────────────────────────────────────────────────

  /// Convertit [amount] de [from] vers [to] selon [rate].
  static double convertCurrency(
    double amount,
    String from,
    String to,
    ExchangeRate rate,
  ) {
    if (rate.fromCurrency == from && rate.toCurrency == to) {
      return rate.convert(amount);
    }
    if (rate.fromCurrency == to && rate.toCurrency == from) {
      return rate.convertInverse(amount);
    }
    // Même devise
    return amount;
  }

  // ─── Estimation globale ───────────────────────────────────────────────────

  /// Estimation du coût total mensuel en FCFA.
  static double estimateMonthlyCost({
    required double dataMobileBytes,
    required double callsMinutes,
    required int smsCount,
    required int aiInputTokens,
    required int aiOutputTokens,
    Plan? dataActivePlan,
    Plan? voiceActivePlan,
    double unitDataPerMb = 5.0,
    double onNetPerMin = 35.0,
    double offNetPerMin = 60.0,
    double smsPrice = 15.0,
    double onNetRatio = 0.6,
    AiModel? aiModel,
    double exchangeRateUsdToLocal = 610.0,
  }) {
    final dataCost = calculateDataCost(
      mobileBytes: dataMobileBytes,
      activePlan: dataActivePlan,
      unitPricePerMb: unitDataPerMb,
    );

    final callCost = calculateCallCost(
      minutes: callsMinutes,
      onNetRatio: onNetRatio,
      activePlan: voiceActivePlan,
      onNetPerMin: onNetPerMin,
      offNetPerMin: offNetPerMin,
    );

    final smsCost = smsCount * smsPrice;

    double aiCostLocal = 0;
    if (aiModel != null) {
      final aiResult = calculateAiCost(
        inputTokens: aiInputTokens,
        outputTokens: aiOutputTokens,
        model: aiModel,
        exchangeRate: exchangeRateUsdToLocal,
      );
      aiCostLocal = aiResult.local;
    }

    return dataCost + callCost + smsCost + aiCostLocal;
  }
}
