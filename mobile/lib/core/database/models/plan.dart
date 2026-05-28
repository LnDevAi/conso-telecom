import 'package:isar/isar.dart';

part 'plan.g.dart';

@Collection()
class Plan {
  Id id = Isar.autoIncrement;

  late String name;

  @Index()
  late String operatorId;

  /// Type de forfait: DATA / VOICE / SMS / COMBO
  @Index()
  late String planType;

  double? dataLimitMb;
  double? voiceLimitMinutes;
  int? smsLimit;

  late double priceFcfa;
  late String currency;
  late int validityDays;

  @Index()
  late DateTime startDate;

  @Index()
  late DateTime expiryDate;

  /// Slot SIM associé (0 ou 1)
  late int simSlot;

  @Index()
  late bool isActive;

  Plan();

  Plan.create({
    required this.name,
    required this.operatorId,
    required this.planType,
    this.dataLimitMb,
    this.voiceLimitMinutes,
    this.smsLimit,
    required this.priceFcfa,
    this.currency = 'XOF',
    required this.validityDays,
    required this.startDate,
    required this.expiryDate,
    required this.simSlot,
    this.isActive = true,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());
  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;

  bool get isDataPlan => planType == 'DATA' || planType == 'COMBO';
  bool get isVoicePlan => planType == 'VOICE' || planType == 'COMBO';
  bool get isSmsPlan => planType == 'SMS' || planType == 'COMBO';
}
