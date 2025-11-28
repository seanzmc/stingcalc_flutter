// lib/engine/core_calculators.dart
import 'dart:math' as math;

/// Core financial and income calculators for Stingcalc.
///
/// These functions are ports of your existing JavaScript logic:
/// - calculateMonthlyPayment
/// - calculateLoanAmount
/// - calculateInterestRate (Newton-Raphson + binary search fallback)
/// - calculateDocStamps (Florida doc stamps)
/// - calculateMonthlyIncome (YTD → monthly)
class LoanMath {
  /// Standard amortized monthly payment.
  ///
  /// [principal] = total amount financed, including any doc stamps etc.
  /// [termMonths] = number of months in the term.
  /// [annualRatePercent] = APR like 7.5 (NOT decimal).
  static double monthlyPayment({
    required double principal,
    required int termMonths,
    required double annualRatePercent,
  }) {
    if (termMonths <= 0) {
      throw ArgumentError('termMonths must be > 0');
    }

    final monthlyRate = annualRatePercent / 100 / 12;

    // Edge case: 0% APR => straight division.
    if (monthlyRate == 0) {
      return principal / termMonths;
    }

    final x = math.pow(1 + monthlyRate, termMonths);
    return (principal * (monthlyRate * x)) / (x - 1);
  }

  /// Inverse of [monthlyPayment]:
  /// Given [payment], [termMonths] and [annualRatePercent], return principal.
  static double loanAmount({
    required double payment,
    required int termMonths,
    required double annualRatePercent,
  }) {
    if (termMonths <= 0) {
      throw ArgumentError('termMonths must be > 0');
    }

    final monthlyRate = annualRatePercent / 100 / 12;

    // Edge case: 0% APR => payment * term.
    if (monthlyRate == 0) {
      return payment * termMonths;
    }

    final x = math.pow(1 + monthlyRate, termMonths);
    return (payment * (x - 1)) / (monthlyRate * x);
  }

  /// Solve for APR (annualRatePercent) that yields [targetPayment]
  /// for a given [principal] and [termMonths].
  ///
  /// Returns the APR as a percent (e.g. 7.25), or null if it fails to converge.
  static double? interestRate({
    required double principal,
    required int termMonths,
    required double targetPayment,
  }) {
    if (principal <= 0 || termMonths <= 0 || targetPayment <= 0) {
      return null;
    }

    // Minimum payment at 0% APR.
    final minPayment = principal / termMonths;
    if (targetPayment < minPayment - 0.01) {
      // Payment too low to amortize the loan.
      return null;
    }

    // Newton–Raphson method, mirroring your JS logic.
    double rateDecimal = 0.05; // 5% initial guess (0.05 decimal)
    const maxIterations = 100;

    for (var i = 0; i < maxIterations; i++) {
      final currentPayment = monthlyPayment(
        principal: principal,
        termMonths: termMonths,
        annualRatePercent: rateDecimal * 100,
      );

      if ((currentPayment - targetPayment).abs() < 0.01) {
        // Close enough: return APR in percent.
        return rateDecimal * 100;
      }

      // Numerical derivative via small perturbation
      const rateIncrement = 0.0001;
      final paymentWithIncrement = monthlyPayment(
        principal: principal,
        termMonths: termMonths,
        annualRatePercent: (rateDecimal + rateIncrement) * 100,
      );

      final derivative =
          (paymentWithIncrement - currentPayment) / rateIncrement;

      if (derivative.abs() < 1e-10) {
        break; // avoid division by zero
      }

      final adjustment = (currentPayment - targetPayment) / derivative;
      rateDecimal -= adjustment;

      // Clamp to a reasonable range [0, 1] in decimal (0–100% APR).
      if (rateDecimal < 0) rateDecimal = 0;
      if (rateDecimal > 1) rateDecimal = 1;
    }

    // Final check
    final finalPayment = monthlyPayment(
      principal: principal,
      termMonths: termMonths,
      annualRatePercent: rateDecimal * 100,
    );
    if ((finalPayment - targetPayment).abs() < 0.01) {
      return rateDecimal * 100;
    }

    // Fallback to binary search in 0–100% APR range.
    return _binarySearchInterestRate(
      principal: principal,
      termMonths: termMonths,
      targetPayment: targetPayment,
      lowRatePercent: 0,
      highRatePercent: 100,
    );
  }

  /// Binary search fallback between [lowRatePercent] and [highRatePercent].
  ///
  /// Rates here are passed as APR percent (0–100), NOT decimal.
  static double? _binarySearchInterestRate({
    required double principal,
    required int termMonths,
    required double targetPayment,
    required double lowRatePercent,
    required double highRatePercent,
  }) {
    const tolerance = 0.001;
    const maxIterations = 50;

    var low = lowRatePercent;
    var high = highRatePercent;

    for (var i = 0; i < maxIterations; i++) {
      final mid = (low + high) / 2;
      final payment = monthlyPayment(
        principal: principal,
        termMonths: termMonths,
        annualRatePercent: mid,
      );

      final diff = (payment - targetPayment).abs();
      if (diff < tolerance) {
        return mid;
      }

      if (payment < targetPayment) {
        // Payment too low at this rate => need higher rate.
        low = mid;
      } else {
        // Payment too high => lower rate.
        high = mid;
      }
    }

    return null; // failed to converge
  }

  /// Florida documentary stamp tax:
  /// - 0.35 per $100 of principal, rounded up to next $100
  /// - capped at 2450
  static double docStamps(double principal) {
    if (principal.isNaN || principal <= 0) return 0.0;
    final units = (principal / 100).ceil();
    final tax = units * 0.35;
    return tax > 2450 ? 2450 : tax.toDouble();
  }

  /// Calculates a biweekly amortization schedule and summary.
  ///
  /// [principal] = total loan amount.
  /// [annualRatePercent] = APR (e.g. 7.5).
  /// [monthlyPayment] = The standard monthly payment amount to base the biweekly payment on.
  /// [startDate] = The date the loan starts (defaults to now if null).
  static BiweeklyResult calculateBiweeklyAmortization({
    required double principal,
    required double annualRatePercent,
    required double monthlyPayment,
    DateTime? startDate,
  }) {
    final start = startDate ?? DateTime.now();
    final dailyRate = annualRatePercent / 100 / 365;
    final biweeklyPayment = monthlyPayment / 2;

    double currentBalance = principal;
    double totalInterest = 0;
    double totalPrincipalPaid = 0;

    // We'll track the schedule.
    // For performance, maybe we only store payment dates, but let's store all for now.
    final schedule = <AmortizationEntry>[];

    DateTime currentDate = start;
    double accruedInterest = 0;

    // Safety break to prevent infinite loops if payment is too low (though it shouldn't be if based on amortized monthly).
    int days = 0;
    const maxDays = 365 * 50; // 50 years limit

    while (currentBalance > 0.01 && days < maxDays) {
      // Daily interest accrual
      final dailyInterest = currentBalance * dailyRate;
      accruedInterest += dailyInterest;

      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
      days++;

      // Payment every 14 days
      if (days % 14 == 0) {
        double payment = biweeklyPayment;

        // If final payment is less than scheduled
        double interestToPay = accruedInterest;
        double principalToPay = payment - interestToPay;

        // Handle final payoff scenario
        if (currentBalance + interestToPay < payment) {
          payment = currentBalance + interestToPay;
          principalToPay = currentBalance;
        }

        if (principalToPay < 0) {
          // Payment doesn't cover interest - negative amortization or just interest only
          principalToPay = 0;
          interestToPay = payment;
          // Remaining interest stays in accrued? Or is capitalized?
          // Simple interest usually just keeps accruing.
          // For this calc, let's assume we pay what we can of interest.
          accruedInterest -= interestToPay;
        } else {
          accruedInterest = 0; // Interest fully paid
          currentBalance -= principalToPay;
          totalPrincipalPaid += principalToPay;
        }

        totalInterest += interestToPay;

        schedule.add(
          AmortizationEntry(
            date: currentDate,
            payment: payment,
            interest: interestToPay,
            principal: principalToPay,
            balance: currentBalance,
          ),
        );
      }
    }

    // Compare with standard monthly
    // We need to know the standard term to calculate savings.
    // But we can just return the raw biweekly data and let the UI compare.

    return BiweeklyResult(
      totalInterest: totalInterest,
      totalPrincipal: totalPrincipalPaid,
      payoffDate: currentDate,
      schedule: schedule,
    );
  }
}

class BiweeklyResult {
  final double totalInterest;
  final double totalPrincipal;
  final DateTime payoffDate;
  final List<AmortizationEntry> schedule;

  BiweeklyResult({
    required this.totalInterest,
    required this.totalPrincipal,
    required this.payoffDate,
    required this.schedule,
  });

  double get totalCost => totalPrincipal + totalInterest;
}

class AmortizationEntry {
  final DateTime date;
  final double payment;
  final double interest;
  final double principal;
  final double balance;

  AmortizationEntry({
    required this.date,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.balance,
  });
}

/// YTD income → monthly + annual, port of calculateMonthlyIncome.
///
/// This version expects you to pass already-parsed [DateTime] objects,
/// which is more natural in Flutter (we can later add string parsing if needed).
class IncomeCalculator {
  /// Returns monthly income, or null if the dates are invalid.
  static double? monthlyIncome({
    required double ytdAmount,
    required DateTime checkDate,
    DateTime? hireDate,
  }) {
    if (ytdAmount < 0) return null;

    final today = DateTime.now();
    final maxYear = today.year + 2;

    if (checkDate.year > maxYear) {
      // In JS version this shows an alert; here the caller can display a message.
      return null;
    }
    if (hireDate != null && hireDate.year > maxYear) {
      return null;
    }

    final year = checkDate.year;

    // Start date: Jan 1 of the year, or hire date if hired this year.
    final startDate =
        (hireDate != null && hireDate.year == year)
            ? hireDate
            : DateTime(year, 1, 1);

    // Check date before hire date? Not allowed.
    if (hireDate != null && checkDate.isBefore(hireDate)) {
      return null;
    }

    // Month difference ignoring partials.
    final monthDiff =
        (checkDate.year - startDate.year) * 12 +
        (checkDate.month - startDate.month);

    final daysInStartMonth =
        DateTime(startDate.year, startDate.month + 1, 0).day;
    final daysInCheckMonth =
        DateTime(checkDate.year, checkDate.month + 1, 0).day;

    // Partial month fractions.
    final startPartial =
        (hireDate != null && hireDate.year == year)
            ? (startDate.day - 1) / daysInStartMonth
            : 0.0;
    final checkPartial = checkDate.day / daysInCheckMonth;

    var months = monthDiff + checkPartial - startPartial;

    if (months <= 0) {
      return null;
    }

    return ytdAmount / months;
  }
}
