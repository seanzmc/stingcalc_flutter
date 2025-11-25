import 'package:flutter_test/flutter_test.dart';
import 'package:stingcalc_flutter/engine/core_calculators.dart';
import 'package:stingcalc_flutter/engine/quick_pencil_engine.dart';

void main() {
  group('LoanMath Tests', () {
    test('monthlyPayment calculates correctly', () {
      // $30,000 loan, 60 months, 5% APR
      // Monthly rate = 0.05 / 12 = 0.0041666...
      // Payment should be around $566.14
      final payment = LoanMath.monthlyPayment(
        principal: 30000,
        termMonths: 60,
        annualRatePercent: 5,
      );
      expect(payment, closeTo(566.14, 0.01));
    });

    test('loanAmount calculates correctly', () {
      // Inverse of the above
      final principal = LoanMath.loanAmount(
        payment: 566.14,
        termMonths: 60,
        annualRatePercent: 5,
      );
      expect(principal, closeTo(30000, 1.0)); // Allow slight rounding diff
    });

    test('interestRate calculates correctly', () {
      // Inverse again
      final rate = LoanMath.interestRate(
        principal: 30000,
        termMonths: 60,
        targetPayment: 566.14,
      );
      expect(rate, closeTo(5.0, 0.01));
    });

    test('docStamps calculates correctly', () {
      // $100 principal -> 1 unit -> $0.35
      expect(LoanMath.docStamps(100), 0.35);
      // $101 principal -> 2 units -> $0.70
      expect(LoanMath.docStamps(101), 0.70);
      // Max cap check (huge principal)
      expect(LoanMath.docStamps(1000000), 2450.0);
    });
  });

  group('IncomeCalculator Tests', () {
    test('monthlyIncome calculates correctly for full year', () {
      // $60,000 YTD, check date is July 1st (half year)
      // Should be around $10,000 / month if it was Jan 1 to July 1?
      // Wait, logic is: months = monthDiff + checkPartial - startPartial
      // Jan 1 to July 1 is exactly 6 months.
      // $60,000 / 6 = $10,000/mo.
      final income = IncomeCalculator.monthlyIncome(
        ytdAmount: 60000,
        checkDate: DateTime(2023, 7, 1),
        hireDate: null, // Assumes Jan 1 start
      );
      // Note: Logic uses day fractions.
      // Jan 1 to July 1:
      // monthDiff = (2023-2023)*12 + (7-1) = 6
      // startPartial = 0
      // checkPartial = 1 / 31 = 0.032...
      // months = 6.032...
      // 60000 / 6.032 = ~9946
      expect(income, closeTo(9946, 100));
    });
  });

  group('QuickPencilEngine Tests', () {
    test('calculate returns valid result for New Car', () {
      final result = QuickPencilEngine.calculate(
        saleType: SaleType.newVehicle,
        clientName: 'Test Client',
        msrp: 30000,
        sellingPriceInput: 0, // Unused for new
        additionalEquipment: 0,
        discount: 0,
        rebates: 0,
        tradeAllowance: 0,
        tradePayoff: 0,
        downPayment: 0,
        tagType: TagType.newTag,
        taxOutsideFl: false,
        selectedState: 'FL',
        customTaxRatePercent: 0,
        rebatesReduceTaxable: false,
      );

      expect(result.msrp, 30000);
      expect(result.tagFee, 450.0);
      // Verify total delivered is > msrp (tax + fees)
      expect(result.totalDelivered, greaterThan(30000));
    });
  });
}
