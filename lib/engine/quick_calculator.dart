// lib/engine/quick_calculator.dart
import 'dart:math' as math;

class QuickCalculatorEngine {
  /// Basic amortized monthly payment:
  /// amountFinanced = principal after down/trade/fees, etc.
  /// annualRatePercent = APR like 7.9
  /// termMonths = e.g. 75
  static double monthlyPayment({
    required double amountFinanced,
    required double annualRatePercent,
    required int termMonths,
  }) {
    final r = annualRatePercent / 100 / 12;

    if (termMonths <= 0) {
      throw ArgumentError('termMonths must be > 0');
    }

    if (r == 0) {
      return amountFinanced / termMonths;
    }

    final factor = math.pow(1 + r, -termMonths);
    return (amountFinanced * r) / (1 - factor);
  }
}
