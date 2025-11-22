import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter;

  CurrencyInputFormatter({bool allowDecimals = true})
    : _formatter = NumberFormat.decimalPattern();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Handle "deletion" of a comma or other non-digit char by checking if the
    // new text is just the old text minus a non-digit.
    // However, a simpler robust approach for currency is:
    // 1. Strip all non-numeric characters (except decimal point).
    // 2. Re-format.

    String newText = newValue.text;

    // Allow only digits and one decimal point
    String cleanedText = newText.replaceAll(RegExp(r'[^\d.]'), '');

    // Prevent multiple decimal points
    if (cleanedText.indexOf('.') != cleanedText.lastIndexOf('.')) {
      return oldValue;
    }

    // Split integer and decimal parts
    List<String> parts = cleanedText.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // Format integer part
    if (integerPart.isNotEmpty) {
      try {
        integerPart = _formatter.format(int.parse(integerPart));
      } catch (e) {
        // Fallback if parsing fails (e.g. too large)
      }
    }

    String formattedText = integerPart;
    if (newText.endsWith('.') || (parts.length > 1)) {
      formattedText += '.';
    }
    if (decimalPart != null) {
      formattedText += decimalPart;
    }

    // Calculate new selection offset
    // This is tricky. A simple heuristic: keep cursor at end if it was at end,
    // otherwise try to preserve relative position.
    // For simplicity in this specific use case (mostly appending), we'll try to
    // keep the cursor relative to the digits.

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  static double parse(String text) {
    if (text.isEmpty) return 0.0;
    return double.tryParse(text.replaceAll(',', '')) ?? 0.0;
  }

  static String format(double value) {
    return NumberFormat.decimalPattern().format(value);
  }

  /// Formats a double as currency with 2 decimal places (e.g., "1,234.50").
  /// Does not include the currency symbol.
  static String formatResult(double value) {
    return NumberFormat.currency(symbol: '', decimalDigits: 2).format(value);
  }
}
