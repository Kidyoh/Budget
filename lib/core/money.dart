import 'package:intl/intl.dart';

class Currency {
  const Currency(this.code, this.symbol, this.name, {this.decimals = 2});

  final String code;
  final String symbol;
  final String name;
  final int decimals;
}

const List<Currency> supportedCurrencies = [
  Currency('ETB', 'Br ', 'Ethiopian Birr'),
  Currency('USD', r'$', 'US Dollar'),
  Currency('EUR', '€', 'Euro'),
  Currency('GBP', '£', 'British Pound'),
  Currency('KES', 'KSh ', 'Kenyan Shilling'),
  Currency('NGN', '₦', 'Nigerian Naira'),
  Currency('ZAR', 'R ', 'South African Rand'),
  Currency('INR', '₹', 'Indian Rupee'),
  Currency('JPY', '¥', 'Japanese Yen', decimals: 0),
  Currency('CNY', 'CN¥', 'Chinese Yuan'),
  Currency('AED', 'AED ', 'UAE Dirham'),
  Currency('CAD', r'CA$', 'Canadian Dollar'),
  Currency('AUD', r'A$', 'Australian Dollar'),
  Currency('BRL', r'R$', 'Brazilian Real'),
];

Currency currencyByCode(String? code) => supportedCurrencies.firstWhere(
  (c) => c.code == code,
  orElse: () => supportedCurrencies.first,
);

/// Formats amounts in the user's chosen currency.
class Money {
  Money(this.currency);

  final Currency currency;

  late final NumberFormat _full = NumberFormat.currency(
    symbol: currency.symbol,
    decimalDigits: currency.decimals,
  );

  late final NumberFormat _whole = NumberFormat.currency(
    symbol: currency.symbol,
    decimalDigits: 0,
  );

  late final NumberFormat _compact = NumberFormat.compactCurrency(
    symbol: currency.symbol,
    decimalDigits: 1,
  );

  /// Full precision, e.g. `$1,250.50`.
  String format(double value) => _full.format(value);

  /// Drops the cents when there are none, e.g. `$1,250`.
  String short(double value) => value == value.roundToDouble()
      ? _whole.format(value)
      : _full.format(value);

  /// Abbreviates large amounts, e.g. `$12.5K`, for tight spaces.
  String compact(double value) =>
      value.abs() < 10000 ? short(value) : _compact.format(value);
}
