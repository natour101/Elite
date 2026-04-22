import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat.currency(
  locale: 'ar',
  symbol: 'د.أ',
  decimalDigits: 0,
);

String formatPrice(double value) => _currencyFormatter.format(value);
