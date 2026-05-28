class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime effectiveDate;

  const ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.effectiveDate,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      fromCurrency: json['from_currency'] as String,
      toCurrency: json['to_currency'] as String,
      rate: (json['rate'] as num).toDouble(),
      effectiveDate: DateTime.parse(json['effective_date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        'rate': rate,
        'effective_date': effectiveDate.toIso8601String(),
      };

  /// Convertit un montant de [fromCurrency] vers [toCurrency].
  double convert(double amount) => amount * rate;

  /// Convertit en sens inverse (de [toCurrency] vers [fromCurrency]).
  double convertInverse(double amount) => amount / rate;

  @override
  String toString() => 'ExchangeRate($fromCurrency→$toCurrency @ $rate)';
}
