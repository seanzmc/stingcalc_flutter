import 'package:flutter/material.dart';
import 'engine/quick_pencil_engine.dart';

class QuickPencilScreen extends StatefulWidget {
  final void Function(double amountToFinance)? onUseInPayment;

  const QuickPencilScreen({
    super.key,
    this.onUseInPayment,
  });

  @override
  State<QuickPencilScreen> createState() => _QuickPencilScreenState();
}

class _QuickPencilScreenState extends State<QuickPencilScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  final _clientNameController = TextEditingController();
  final _clientNameFocus = FocusNode();

  // New car inputs
  final _msrpController = TextEditingController();
  final _discountController = TextEditingController();
  final _rebatesController = TextEditingController();

  final _msrpFocus = FocusNode();
  final _discountFocus = FocusNode();
  final _rebatesFocus = FocusNode();

  // Used car / shared inputs
  final _sellingPriceController = TextEditingController();
  final _additionalEqController = TextEditingController();
  final _tradeAllowanceController = TextEditingController();
  final _tradePayoffController = TextEditingController();
  final _downPaymentController = TextEditingController();

  final _sellingPriceFocus = FocusNode();
  final _additionalEqFocus = FocusNode();
  final _tradeAllowanceFocus = FocusNode();
  final _tradePayoffFocus = FocusNode();
  final _downPaymentFocus = FocusNode();

  // Tag & tax
  SaleType _saleType = SaleType.newVehicle;
  TagType _tagType = TagType.newTag;
  final _customTagFeeController = TextEditingController();
  final _customTagFeeFocus = FocusNode();

  bool _taxOutsideFl = false;
  final _stateController = TextEditingController();
  final _customTaxRateController = TextEditingController(text: '6.0');

  final _stateFocus = FocusNode();
  final _customTaxRateFocus = FocusNode();

  bool _rebatesReduceTaxable = false;

  QuickPencilResult? _result;
  String? _errorMessage;

  void _clearForm() {
    _clientNameController.clear();
    _msrpController.clear();
    _discountController.clear();
    _rebatesController.clear();
    _sellingPriceController.clear();
    _additionalEqController.clear();
    _tradeAllowanceController.clear();
    _tradePayoffController.clear();
    _downPaymentController.clear();
    _customTagFeeController.clear();
    _stateController.clear();
    _customTaxRateController.text = '6.0';

    _clientNameFocus.requestFocus();

    setState(() {
      _saleType = SaleType.newVehicle;
      _tagType = TagType.newTag;
      _taxOutsideFl = false;
      _rebatesReduceTaxable = false;
      _result = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _msrpController.dispose();
    _discountController.dispose();
    _rebatesController.dispose();
    _sellingPriceController.dispose();
    _additionalEqController.dispose();
    _tradeAllowanceController.dispose();
    _tradePayoffController.dispose();
    _downPaymentController.dispose();
    _customTagFeeController.dispose();
    _stateController.dispose();
    _customTaxRateController.dispose();

    _clientNameFocus.dispose();
    _msrpFocus.dispose();
    _discountFocus.dispose();
    _rebatesFocus.dispose();
    _sellingPriceFocus.dispose();
    _additionalEqFocus.dispose();
    _tradeAllowanceFocus.dispose();
    _tradePayoffFocus.dispose();
    _downPaymentFocus.dispose();
    _customTagFeeFocus.dispose();
    _stateFocus.dispose();
    _customTaxRateFocus.dispose();

    super.dispose();
  }

  String? _nonNegativeValidator(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Required' : null;
    }
    final v = double.tryParse(value);
    if (v == null) return 'Enter a number';
    if (v < 0) return 'Must be ≥ 0';
    return null;
  }

  void _calculate() {
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      setState(() {
        _errorMessage = 'Please fix the highlighted fields.';
        _result = null;
      });
      return;
    }

    double parseOrZero(TextEditingController c) =>
        double.tryParse(c.text.trim()) ?? 0.0;

    final clientName = _clientNameController.text.trim();

    final msrp = parseOrZero(_msrpController);
    final sellingPriceInput = parseOrZero(_sellingPriceController);
    final additionalEq = parseOrZero(_additionalEqController);
    final discount = parseOrZero(_discountController);
    final rebates = parseOrZero(_rebatesController);
    final tradeAllowance = parseOrZero(_tradeAllowanceController);
    final tradePayoff = parseOrZero(_tradePayoffController);
    final downPayment = parseOrZero(_downPaymentController);

    final customTagFee = _tagType == TagType.custom
        ? double.tryParse(_customTagFeeController.text.trim())
        : null;

    final customTaxRate =
        double.tryParse(_customTaxRateController.text.trim()) ?? 0.0;

    final selectedState = _stateController.text.trim();

    try {
      final result = QuickPencilEngine.calculate(
        saleType: _saleType,
        clientName: clientName,
        msrp: msrp,
        sellingPriceInput: sellingPriceInput,
        additionalEquipment: additionalEq,
        discount: discount,
        rebates: rebates,
        tradeAllowance: tradeAllowance,
        tradePayoff: tradePayoff,
        downPayment: downPayment,
        tagType: _tagType,
        customTagFee: customTagFee,
        taxOutsideFl: _taxOutsideFl,
        selectedState: selectedState,
        customTaxRatePercent: customTaxRate,
        rebatesReduceTaxable: _rebatesReduceTaxable,
      );

      setState(() {
        _result = result;
        _errorMessage = null;
      });
    } on ArgumentError catch (e) {
      setState(() {
        _errorMessage = e.message?.toString() ?? 'Invalid input value.';
        _result = null;
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'Something went wrong while calculating. Please check your inputs.';
        _result = null;
      });
    }
  }

  String _formatMoney(double value) {
    final numberStr = value.toStringAsFixed(2);
    final parts = numberStr.split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '\$$integerPart.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _saleType == SaleType.newVehicle;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'Quick Pencil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Sale type toggle
            SegmentedButton<SaleType>(
              segments: const [
                ButtonSegment(
                  value: SaleType.newVehicle,
                  label: Text('NEW'),
                ),
                ButtonSegment(
                  value: SaleType.usedVehicle,
                  label: Text('USED'),
                ),
              ],
              selected: <SaleType>{_saleType},
              onSelectionChanged: (set) {
                setState(() {
                  _saleType = set.first;
                  _result = null; // clear prior result
                });
              },
            ),
            const SizedBox(height: 16),

            // Client name
            TextFormField(
              controller: _clientNameController,
              focusNode: _clientNameFocus,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Client Name (optional)',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                if (isNew) {
                  _msrpFocus.requestFocus();
                } else {
                  _sellingPriceFocus.requestFocus();
                }
              },
            ),
            const SizedBox(height: 16),

            // New vs Used inputs
            if (isNew) ...[
              TextFormField(
                controller: _msrpController,
                focusNode: _msrpFocus,
                decoration: const InputDecoration(
                  labelText: 'M.S.R.P.',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: (v) => _nonNegativeValidator(v, required: true),
                onFieldSubmitted: (_) => _additionalEqFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _additionalEqController,
                focusNode: _additionalEqFocus,
                decoration: const InputDecoration(
                  labelText: 'Additional Equipment',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: _nonNegativeValidator,
                onFieldSubmitted: (_) => _discountFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountController,
                focusNode: _discountFocus,
                decoration: const InputDecoration(
                  labelText: 'Discount',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: _nonNegativeValidator,
                onFieldSubmitted: (_) => _rebatesFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rebatesController,
                focusNode: _rebatesFocus,
                decoration: const InputDecoration(
                  labelText: 'Rebates',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: _nonNegativeValidator,
                onFieldSubmitted: (_) => _tradeAllowanceFocus.requestFocus(),
              ),
            ] else ...[
              TextFormField(
                controller: _sellingPriceController,
                focusNode: _sellingPriceFocus,
                decoration: const InputDecoration(
                  labelText: 'Selling Price',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: (v) => _nonNegativeValidator(v, required: true),
                onFieldSubmitted: (_) => _additionalEqFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _additionalEqController,
                focusNode: _additionalEqFocus,
                decoration: const InputDecoration(
                  labelText: 'Additional Equipment',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: _nonNegativeValidator,
                onFieldSubmitted: (_) => _tradeAllowanceFocus.requestFocus(),
              ),
            ],

            const SizedBox(height: 12),

            // Trade / down
            TextFormField(
              controller: _tradeAllowanceController,
              focusNode: _tradeAllowanceFocus,
              decoration: const InputDecoration(
                labelText: 'Trade Allowance',
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _nonNegativeValidator,
              onFieldSubmitted: (_) => _tradePayoffFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tradePayoffController,
              focusNode: _tradePayoffFocus,
              decoration: const InputDecoration(
                labelText: 'Trade Payoff',
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _nonNegativeValidator,
              onFieldSubmitted: (_) => _downPaymentFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _downPaymentController,
              focusNode: _downPaymentFocus,
              decoration: const InputDecoration(
                labelText: 'Customer Cash / Down Payment',
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _nonNegativeValidator,
              onFieldSubmitted: (_) {
                if (_tagType == TagType.custom) {
                  _customTagFeeFocus.requestFocus();
                } else if (_taxOutsideFl) {
                  _stateFocus.requestFocus();
                } else {
                  _calculate();
                }
              },
            ),

            const SizedBox(height: 16),

            // Tag type
            DropdownButtonFormField<TagType>(
              initialValue: _tagType,
              items: const [
                DropdownMenuItem(
                  value: TagType.newTag,
                  child: Text('New Tag'),
                ),
                DropdownMenuItem(
                  value: TagType.transfer,
                  child: Text('Transfer Tag'),
                ),
                DropdownMenuItem(
                  value: TagType.custom,
                  child: Text('Custom Tag Fee'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _tagType = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Tag & Title Type',
              ),
            ),
            if (_tagType == TagType.custom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customTagFeeController,
                focusNode: _customTagFeeFocus,
                decoration: const InputDecoration(
                  labelText: 'Custom Tag Fee',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: (v) => _tagType == TagType.custom
                    ? _nonNegativeValidator(v, required: true)
                    : null,
                onFieldSubmitted: (_) {
                  if (_taxOutsideFl) {
                    _stateFocus.requestFocus();
                  } else {
                    _calculate();
                  }
                },
              ),
            ],

            const SizedBox(height: 16),

            // Tax outside FL toggle
            SwitchListTile(
              title: const Text('Tax Outside Florida'),
              value: _taxOutsideFl,
              onChanged: (value) {
                setState(() {
                  _taxOutsideFl = value;
                  if (!value) {
                    _rebatesReduceTaxable = false;
                  }
                });
              },
            ),

            if (_taxOutsideFl) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _stateController,
                focusNode: _stateFocus,
                decoration: const InputDecoration(
                  labelText: 'Tax State (e.g., GA, NY)',
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _customTaxRateFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customTaxRateController,
                focusNode: _customTaxRateFocus,
                decoration: const InputDecoration(
                  labelText: 'Custom Tax Rate',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (!_taxOutsideFl) return null;
                  final basic = _nonNegativeValidator(v, required: true);
                  if (basic != null) return basic;
                  final rate = double.tryParse(v!.trim()) ?? 0;
                  if (rate > 100) return 'Must be ≤ 100';
                  return null;
                },
                onFieldSubmitted: (_) => _calculate(),
              ),
              if (isNew) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Rebates reduce taxable amount'),
                  value: _rebatesReduceTaxable,
                  onChanged: (value) {
                    setState(() {
                      _rebatesReduceTaxable = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Calculate Amount to Finance'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _clearForm,
                  child: const Text('Clear'),
                ),
              ],
            ),
            if (_result != null) _buildResultSummary(_result!),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary(QuickPencilResult result) {
    final isNew = result.saleType == SaleType.newVehicle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Itemized Summary',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        if (isNew) ...[
          _row('M.S.R.P.', _formatMoney(result.msrp)),
          _row('+ Additional Equipment', _formatMoney(result.additionalEquipment)),
          _row('- Discount', _formatMoney(result.discount)),
          _totalRow('= Selling Price', _formatMoney(result.sellPrice)),
          const Divider(),
          _row('- Trade Allowance', _formatMoney(result.tradeAllowance)),
          _row('+ FL Waste Tire Fee', _formatMoney(result.floridaWasteTireFee)),
          _row('+ FL Battery Fee', _formatMoney(result.floridaBatteryFee)),
          _row('+ Dealer Fee', _formatMoney(result.dealerFee)),
          _row('+ Private Tag Agency Fee', _formatMoney(result.privateTagAgencyFee)),
          _totalRow('= Total Taxable', _formatMoney(result.totalTaxable)),
          const Divider(),
          _row(
            '+ ${result.stateAbbrev} Sales Tax (${result.taxRatePercent.toStringAsFixed(2)}%)',
            _formatMoney(result.salesTax),
          ),
          _row('+ FL Lemon Law Fee', _formatMoney(result.lemonLawFee)),
          _row('+ Tag & Title Fee', _formatMoney(result.tagFee)),
          _row('+ Trade Payoff', _formatMoney(result.tradePayoff)),
          _totalRow('= Delivered Price', _formatMoney(result.totalDelivered)),
          const Divider(),
          _row('- Rebates', _formatMoney(result.rebates)),
          if (result.taxOutsideFl && result.rebatesReduceTaxable)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'Rebates reduce the taxable amount',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          _row('- Down Payment', _formatMoney(result.downPayment)),
        ] else ...[
          _row('Selling Price', _formatMoney(result.sellingPriceInput)),
          _row('+ Additional Equipment', _formatMoney(result.additionalEquipment)),
          _row('- Trade Allowance', _formatMoney(result.tradeAllowance)),
          _row('+ Dealer Fee', _formatMoney(result.dealerFee)),
          _row('+ Private Tag Agency Fee', _formatMoney(result.privateTagAgencyFee)),
          _totalRow('= Total Taxable', _formatMoney(result.totalTaxable)),
          const Divider(),
          _row(
            '+ ${result.stateAbbrev} Sales Tax (${result.taxRatePercent.toStringAsFixed(2)}%)',
            _formatMoney(result.salesTax),
          ),
          _row('+ Tag & Title Fee', _formatMoney(result.tagFee)),
          _row('+ Trade Payoff', _formatMoney(result.tradePayoff)),
          _totalRow('= Delivered Price', _formatMoney(result.totalDelivered)),
          const Divider(),
          _row('- Down Payment', _formatMoney(result.downPayment)),
        ],

        const SizedBox(height: 12),
        const Divider(),
        _totalRow(
          'Amount to Finance',
          _formatMoney(result.amountToFinance),
        ),
        const SizedBox(height: 16),
        if (widget.onUseInPayment != null)
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () {
                widget.onUseInPayment!(result.amountToFinance);
              },
              child: const Text('Use in Payment Calculator'),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
