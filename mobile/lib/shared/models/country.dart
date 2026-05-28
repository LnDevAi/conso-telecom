import 'operator.dart';

class Country {
  final String code;
  final String nameFr;
  final String nameEn;
  final String defaultCurrency;
  final List<Operator> operators;

  const Country({
    required this.code,
    required this.nameFr,
    required this.nameEn,
    required this.defaultCurrency,
    required this.operators,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'] as String,
      nameFr: json['name_fr'] as String? ?? json['name'] as String,
      nameEn: json['name_en'] as String? ?? json['name'] as String,
      defaultCurrency: json['default_currency'] as String? ?? 'XOF',
      operators: (json['operators'] as List<dynamic>?)
              ?.map((o) => Operator.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name_fr': nameFr,
        'name_en': nameEn,
        'default_currency': defaultCurrency,
        'operators': operators.map((o) => o.toJson()).toList(),
      };

  @override
  String toString() => 'Country($code, $nameFr)';
}
