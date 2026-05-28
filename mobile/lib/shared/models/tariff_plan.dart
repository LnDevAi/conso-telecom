class TariffPlan {
  final String id;
  final String operatorId;
  final String name;

  /// Type: DATA / VOICE / SMS / COMBO
  final String planType;

  final double? dataLimitMb;
  final double? voiceLimitMinutes;
  final int? smsLimit;
  final double price;
  final String currency;
  final int validityDays;

  const TariffPlan({
    required this.id,
    required this.operatorId,
    required this.name,
    required this.planType,
    this.dataLimitMb,
    this.voiceLimitMinutes,
    this.smsLimit,
    required this.price,
    this.currency = 'XOF',
    required this.validityDays,
  });

  factory TariffPlan.fromJson(Map<String, dynamic> json) {
    return TariffPlan(
      id: json['id'] as String,
      operatorId: json['operator_id'] as String,
      name: json['name'] as String,
      planType: json['plan_type'] as String,
      dataLimitMb: (json['data_limit_mb'] as num?)?.toDouble(),
      voiceLimitMinutes: (json['voice_limit_minutes'] as num?)?.toDouble(),
      smsLimit: json['sms_limit'] as int?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'XOF',
      validityDays: json['validity_days'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'operator_id': operatorId,
        'name': name,
        'plan_type': planType,
        'data_limit_mb': dataLimitMb,
        'voice_limit_minutes': voiceLimitMinutes,
        'sms_limit': smsLimit,
        'price': price,
        'currency': currency,
        'validity_days': validityDays,
      };

  String get dataLimitLabel {
    if (dataLimitMb == null) return 'Illimité';
    if (dataLimitMb! >= 1024) {
      return '${(dataLimitMb! / 1024).toStringAsFixed(1)} Go';
    }
    return '${dataLimitMb!.toStringAsFixed(0)} Mo';
  }

  @override
  String toString() => 'TariffPlan($id, $name, $planType)';
}
