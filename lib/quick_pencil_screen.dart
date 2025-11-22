import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/quick_pencil_engine.dart';
import 'widgets/data_readout.dart';

class QuickPencilScreen extends StatefulWidget {
  final void Function(double amountToFinance)? onUseInPayment;

  const QuickPencilScreen({super.key, this.onUseInPayment});

  @override
  State<QuickPencilScreen> createState() => _QuickPencilScreenState();
}

class _QuickPencilScreenState extends State<QuickPencilScreen> {
  final _scrollController = ScrollController();

  // Basic info
  final _clientNameController = TextEditingController();

  // New car inputs
  final _msrpController = TextEditingController();
  final _discountController = TextEditingController();
  final _rebatesController = TextEditingController();

  // Used car / shared inputs
  final _sellingPriceController = TextEditingController();
  final _additionalEqController = TextEditingController();
  final _tradeAllowanceController = TextEditingController();
  final _tradePayoffController = TextEditingController();
  final _downPaymentController = TextEditingController();

  final _msrpFocusNode = FocusNode();
  final _sellingPriceFocusNode = FocusNode();

  // Tag & tax
  SaleType _saleType = SaleType.newVehicle;
  TagType _tagType = TagType.newTag;
  final _customTagFeeController = TextEditingController();

  bool _taxOutsideFl = false;
  final _stateController = TextEditingController();
  final _customTaxRateController = TextEditingController(text: '6.0');

  bool _rebatesReduceTaxable = false;

  QuickPencilResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    _msrpFocusNode.dispose();
    _sellingPriceFocusNode.dispose();
    super.dispose();
  }

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

    setState(() {
      _saleType = SaleType.newVehicle;
      _tagType = TagType.newTag;
      _taxOutsideFl = false;
      _rebatesReduceTaxable = false;
      _result = null;
    });
    _calculate();
  }

  void _calculate() {
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

    final customTagFee =
        _tagType == TagType.custom
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
      });
    } catch (_) {
      // Silent fail for reactive updates
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
    final theme = Theme.of(context);
    final isNew = _saleType == SaleType.newVehicle;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'QUICK PENCIL',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _clearForm,
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Clear Form',
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
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
                      });
                      _calculate();
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('VEHICLE & PRICING'),
              if (isNew) ...[
                _buildRow(
                  'M.S.R.P.',
                  _msrpController,
                  focusNode: _msrpFocusNode,
                  autofocus: true,
                ),
                _buildRow('Discount', _discountController, isNegative: true),
                _buildRow('Rebates', _rebatesController, isNegative: true),
              ] else ...[
                _buildRow(
                  'Selling Price',
                  _sellingPriceController,
                  focusNode: _sellingPriceFocusNode,
                  autofocus: true,
                ),
              ],
              _buildRow('Additional Equipment', _additionalEqController),
              const SizedBox(height: 24),
              _buildSectionHeader('TRADE & DOWN'),
              _buildRow(
                'Trade Allowance',
                _tradeAllowanceController,
                isNegative: true,
              ),
              _buildRow('Trade Payoff', _tradePayoffController),
              _buildRow(
                'Down Payment',
                _downPaymentController,
                isNegative: true,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('TAX & TAG'),
              DropdownButtonFormField<TagType>(
                key: ValueKey(_tagType),
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
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _tagType = v);
                    _calculate();
                  }
                },
                decoration: const InputDecoration(labelText: 'Tag Type'),
              ),
              if (_tagType == TagType.custom)
                _buildRow('Custom Tag Fee', _customTagFeeController),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Tax Outside Florida'),
                value: _taxOutsideFl,
                onChanged: (v) {
                  setState(() => _taxOutsideFl = v);
                  _calculate();
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_taxOutsideFl) ...[
                _buildRow('Tax Rate (%)', _customTaxRateController),
                if (isNew)
                  CheckboxListTile(
                    title: const Text('Rebates reduce taxable amount'),
                    value: _rebatesReduceTaxable,
                    onChanged: (v) {
                      setState(() => _rebatesReduceTaxable = v ?? false);
                      _calculate();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
              const SizedBox(height: 100), // Space for footer
            ],
          ),
        ),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    TextEditingController controller, {
    bool isNegative = false,
    FocusNode? focusNode,
    bool autofocus = false,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: isNegative ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              textInputAction: textInputAction,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: isNegative ? '- \$ ' : '\$ ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => _calculate(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final amountToFinance = _result?.amountToFinance ?? 0.0;
    final totalDelivered = _result?.totalDelivered ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Delivered Price',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  _formatMoney(totalDelivered),
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DataReadout(
                    label: 'AMOUNT TO FINANCE',
                    value: _formatMoney(amountToFinance),
                    isLarge: true,
                    valueColor: theme.colorScheme.primary,
                  ),
                ),
                if (widget.onUseInPayment != null) ...[
                  const SizedBox(width: 16),
                  IconButton.filled(
                    onPressed: () => widget.onUseInPayment!(amountToFinance),
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Use in Payment Calculator',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
