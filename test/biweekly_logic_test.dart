import 'package:flutter_test/flutter_test.dart';
import 'package:stingcalc_flutter/engine/core_calculators.dart';

void main() {
  group('Biweekly Amortization Tests', () {
    test('Calculates biweekly amortization correctly', () {
      // Scenario: $10,000 loan, 5% interest, 3 years (36 months).
      // Monthly Payment: ~$300 (approx)
      // Biweekly Payment: ~$150 every 14 days.

      const principal = 10000.0;
      const rate = 5.0;
      const termMonths = 36;

      final monthlyPayment = LoanMath.monthlyPayment(
        principal: principal,
        termMonths: termMonths,
        annualRatePercent: rate,
      );

      // Standard monthly total interest
      final standardTotalInterest = (monthlyPayment * termMonths) - principal;

      final biweeklyResult = LoanMath.calculateBiweeklyAmortization(
        principal: principal,
        annualRatePercent: rate,
        monthlyPayment: monthlyPayment,
      );

      // Biweekly should save money and time
      expect(biweeklyResult.totalInterest, lessThan(standardTotalInterest));
      expect(biweeklyResult.totalPrincipal, closeTo(principal, 0.01));

      // Check schedule integrity
      double calculatedPrincipal = 0;
      for (var entry in biweeklyResult.schedule) {
        calculatedPrincipal += entry.principal;
      }
      expect(calculatedPrincipal, closeTo(principal, 0.01));

      // Check that payments are 14 days apart
      for (int i = 1; i < biweeklyResult.schedule.length; i++) {
        final diff =
            biweeklyResult.schedule[i].date
                .difference(biweeklyResult.schedule[i - 1].date)
                .inDays;
        expect(diff, equals(14));
      }
    });

    test('Handles payoff correctly', () {
      // Small loan to ensure it finishes quickly
      const principal = 1000.0;
      const rate = 10.0;
      const monthlyPayment = 100.0; // High payment to pay off fast

      final result = LoanMath.calculateBiweeklyAmortization(
        principal: principal,
        annualRatePercent: rate,
        monthlyPayment: monthlyPayment,
      );

      expect(result.schedule.last.balance, closeTo(0, 0.01));
      expect(result.totalPrincipal, closeTo(principal, 0.01));
    });
  });
}
