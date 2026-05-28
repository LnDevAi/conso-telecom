import 'tariff_plan.dart';

class UnitTariff {
  final double dataPricePerMb;
  final double onNetPerMin;
  final double offNetPerMin;
  final double smsPriceLocal;
  final String currency;

  const UnitTariff({
    required this.dataPricePerMb,
    required this.onNetPerMin,
    required this.offNetPerMin,
    required this.smsPriceLocal,
    this.currency = 'XOF',
  });

  factory UnitTariff.fromJson(Map<String, dynamic> json) {
    return UnitTariff(
      dataPricePerMb: (json['data_price_per_mb'] as num).toDouble(),
      onNetPerMin: (json['on_net_per_min'] as num).toDouble(),
      offNetPerMin: (json['off_net_per_min'] as num).toDouble(),
      smsPriceLocal: (json['sms_price_local'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'XOF',
    );
  }

  Map<String, dynamic> toJson() => {
        'data_price_per_mb': dataPricePerMb,
        'on_net_per_min': onNetPerMin,
        'off_net_per_min': offNetPerMin,
        'sms_price_local': smsPriceLocal,
        'currency': currency,
      };
}

class Operator {
  final String id;
  final String name;
  final String countryCode;
  final String? ussdBalanceCode;
  final List<TariffPlan> plans;
  final UnitTariff? unitTariff;

  const Operator({
    required this.id,
    required this.name,
    required this.countryCode,
    this.ussdBalanceCode,
    required this.plans,
    this.unitTariff,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      id: json['id'] as String,
      name: json['name'] as String,
      countryCode: json['country_code'] as String,
      ussdBalanceCode: json['ussd_balance_code'] as String?,
      plans: (json['plans'] as List<dynamic>?)
              ?.map((p) => TariffPlan.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      unitTariff: json['unit_tariff'] != null
          ? UnitTariff.fromJson(json['unit_tariff'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country_code': countryCode,
        'ussd_balance_code': ussdBalanceCode,
        'plans': plans.map((p) => p.toJson()).toList(),
        'unit_tariff': unitTariff?.toJson(),
      };

  @override
  String toString() => 'Operator($id, $name)';
}
