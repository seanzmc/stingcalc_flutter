// lib/engine/quick_pencil_engine.dart

enum SaleType { newVehicle, usedVehicle }
enum TagType { newTag, transfer, custom }

class QuickPencilResult {
  final SaleType saleType;

  final double msrp;
  final double sellingPriceInput;
  final double additionalEquipment;
  final double discount;
  final double rebates;
  final double tradeAllowance;
  final double tradePayoff;
  final double downPayment;

  final TagType tagType;
  final double tagFee;

  final bool taxOutsideFl;
  final String stateAbbrev;
  final double taxRatePercent;
  final bool rebatesReduceTaxable;

  final double floridaWasteTireFee;
  final double floridaBatteryFee;
  final double dealerFee;
  final double privateTagAgencyFee;
  final double lemonLawFee;
  final double docStampFlat;

  final double sellPrice;      // after msrp/addEq/discount for NEW, or selling+addEq for USED
  final double totalTaxable;
  final double salesTax;
  final double totalDelivered;
  final double amountToFinance;

  QuickPencilResult({
    required this.saleType,
    required this.msrp,
    required this.sellingPriceInput,
    required this.additionalEquipment,
    required this.discount,
    required this.rebates,
    required this.tradeAllowance,
    required this.tradePayoff,
    required this.downPayment,
    required this.tagType,
    required this.tagFee,
    required this.taxOutsideFl,
    required this.stateAbbrev,
    required this.taxRatePercent,
    required this.rebatesReduceTaxable,
    required this.floridaWasteTireFee,
    required this.floridaBatteryFee,
    required this.dealerFee,
    required this.privateTagAgencyFee,
    required this.lemonLawFee,
    required this.docStampFlat,
    required this.sellPrice,
    required this.totalTaxable,
    required this.salesTax,
    required this.totalDelivered,
    required this.amountToFinance,
  });
}

class QuickPencilEngine {
  static const double _floridaWasteTireFee = 5.0;
  static const double _floridaBatteryFee = 1.5;
  static const double _dealerFee = 999.0;
  static const double _privateTagAgencyFee = 289.52;
  static const double _lemonLawFee = 2.0;
  static const double _salesTaxRateFL = 0.06; // 6%
  static const double _docStampFlat = 75.0;

  /// Main calculation entry point.
  ///
  /// Mirrors the JS quick pencil logic:
  /// - saleType: NEW vs USED
  /// - tagType: new / transfer / custom (customTagFee required)
  /// - taxOutsideFl: if true, uses [customTaxRatePercent] and optionally [rebatesReduceTaxable]
  /// - selectedState: used for label only, not math
  static QuickPencilResult calculate({
    required SaleType saleType,
    required String clientName, // currently unused in math, but kept for parity
    required double msrp,
    required double sellingPriceInput,
    required double additionalEquipment,
    required double discount,
    required double rebates,
    required double tradeAllowance,
    required double tradePayoff,
    required double downPayment,
    required TagType tagType,
    double? customTagFee,
    required bool taxOutsideFl,
    required String selectedState,
    required double customTaxRatePercent,
    required bool rebatesReduceTaxable,
  }) {
    // Tag fee logic (matches JS)
    final double tagFee;
    switch (tagType) {
      case TagType.custom:
        if (customTagFee == null || customTagFee < 0) {
          throw ArgumentError('Custom tag fee must be a non-negative number.');
        }
        tagFee = customTagFee;
        break;
      case TagType.transfer:
        tagFee = 350.0;
        break;
      case TagType.newTag:
        tagFee = 450.0;
        break;
    }

    // Normalized state abbrev for display (math only uses rate)
    final stateAbbrev = (taxOutsideFl && selectedState.trim().isNotEmpty)
        ? selectedState.trim()
        : 'FL';

    // Clamp custom tax rate between 0 and 100 just like JS does
    final taxRatePercent = taxOutsideFl
        ? customTaxRatePercent.clamp(0.0, 100.0)
        : _salesTaxRateFL * 100.0;

    final isNew = saleType == SaleType.newVehicle;

    double sellPrice;
    double totalTaxable;
    double salesTax;
    double totalDelivered;
    double finalAmount;

    if (isNew) {
      // NEW car flow
      sellPrice = msrp + additionalEquipment - discount;

      totalTaxable = sellPrice -
          tradeAllowance +
          _floridaWasteTireFee +
          _floridaBatteryFee +
          _dealerFee +
          _privateTagAgencyFee;

      if (taxOutsideFl) {
        // Custom tax state
        if (rebatesReduceTaxable) {
          totalTaxable = totalTaxable - rebates;
        }
        if (totalTaxable < 0) totalTaxable = 0;
        salesTax = totalTaxable * (taxRatePercent / 100.0);
      } else {
        // Florida tax + doc stamp flat
        if (totalTaxable < 0) totalTaxable = 0;
        salesTax = totalTaxable * _salesTaxRateFL + _docStampFlat;
      }

      totalDelivered = totalTaxable +
          salesTax +
          _lemonLawFee +
          tagFee +
          tradePayoff;

      if (taxOutsideFl && rebatesReduceTaxable) {
        finalAmount = totalDelivered - downPayment;
      } else {
        finalAmount = totalDelivered - rebates - downPayment;
      }
    } else {
      // USED car flow
      sellPrice = sellingPriceInput + additionalEquipment;

      totalTaxable = sellPrice -
          tradeAllowance +
          _dealerFee +
          _privateTagAgencyFee;

      if (taxOutsideFl) {
        if (totalTaxable < 0) totalTaxable = 0;
        salesTax = totalTaxable * (taxRatePercent / 100.0);
      } else {
        if (totalTaxable < 0) totalTaxable = 0;
        salesTax = totalTaxable * _salesTaxRateFL + _docStampFlat;
      }

      totalDelivered = totalTaxable +
          salesTax +
          tagFee +
          tradePayoff;

      finalAmount = totalDelivered - downPayment;
    }

    return QuickPencilResult(
      saleType: saleType,
      msrp: msrp,
      sellingPriceInput: sellingPriceInput,
      additionalEquipment: additionalEquipment,
      discount: discount,
      rebates: rebates,
      tradeAllowance: tradeAllowance,
      tradePayoff: tradePayoff,
      downPayment: downPayment,
      tagType: tagType,
      tagFee: tagFee,
      taxOutsideFl: taxOutsideFl,
      stateAbbrev: stateAbbrev,
      taxRatePercent: taxRatePercent,
      rebatesReduceTaxable: rebatesReduceTaxable,
      floridaWasteTireFee: _floridaWasteTireFee,
      floridaBatteryFee: _floridaBatteryFee,
      dealerFee: _dealerFee,
      privateTagAgencyFee: _privateTagAgencyFee,
      lemonLawFee: _lemonLawFee,
      docStampFlat: _docStampFlat,
      sellPrice: sellPrice,
      totalTaxable: totalTaxable,
      salesTax: salesTax,
      totalDelivered: totalDelivered,
      amountToFinance: finalAmount,
    );
  }
}
