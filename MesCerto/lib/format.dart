import 'package:intl/intl.dart';

final _brl =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

String formatCurrency(num value) => _brl.format(value);

String formatDate(String date) {
  try {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse('${date}T12:00:00'));
  } catch (_) {
    return date;
  }
}

String formatMonth(DateTime date) {
  final s = DateFormat("MMMM 'de' yyyy", 'pt_BR').format(date);
  return s[0].toUpperCase() + s.substring(1);
}

String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// 187.0 -> "187", 44.9 -> "44,9" (igual ao String(number) do JS)
String amountToInput(double v) =>
    (v == v.roundToDouble() ? v.toInt().toString() : v.toString())
        .replaceAll('.', ',');

/// Lê um valor digitado pelo usuário: "1.234,56", "44,9" ou "44.90".
/// Devolve null se não for um número válido.
double? parseMoney(String text) {
  var t = text.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.'); // vírgula = decimal
  }
  return double.tryParse(t);
}
