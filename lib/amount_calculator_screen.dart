import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/core_calculators.dart';
import 'utils/currency_input_formatter.dart';
import 'widgets/data_readout.dart';
import 'widgets/terminal_slider.dart';

class AmountCalculatorScreen extends StatefulWidget {
  const AmountCalculatorScreen({super.key});

  @override
  State<AmountCalculatorScreen> createState() => _AmountCalculatorScreenState();
}

class _AmountCalculatorScreenState extends State<AmountCalculatorScreen> {
  final _paymentController = TextEditingController();
  final _rateController = TextEditingController(text: '6.9');

  final _paymentFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();
  final _termFocusNode = FocusNode();

  int _term = 72;
  bool _disableDocStamps = false;

  double? _loanAmount;
  double? _docStamps;
  double? _totalLoan;

  @override
  void initState() {
    super.initState();
    // Add listeners for select-all on focus
    _paymentFocusNode.addListener(
      () => _selectAllOnFocus(_paymentFocusNode, _paymentController),
    );
    _rateFocusNode.addListener(
      () => _selectAllOnFocus(_rateFocusNode, _rateController),
    );
  }

  void _selectAllOnFocus(FocusNode node, TextEditingController controller) {
    if (node.hasFocus) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _paymentController.dispose();
    _rateController.dispose();
    _paymentFocusNode.dispose();
    _rateFocusNode.dispose();
    _termFocusNode.dispose();
    super.dispose();
  }

  void _clearForm() {
    _paymentController.clear();
    _rateController.text = '6.9';
    setState(() {
      _term = 72;
      _disableDocStamps = false;
      _loanAmount = null;
      _docStamps = null;
      _totalLoan = null;
    });
    // Focus back on the first field
    _paymentFocusNode.requestFocus();
  }

  void _calculate() {
    final payment = CurrencyInputFormatter.parse(_paymentController.text);
    final rate = double.tryParse(_rateController.text);

    if (payment <= 0 || rate == null) {
      setState(() {
        _loanAmount = null;
        _docStamps = null;
        _totalLoan = null;
      });
      return;
    }

    final loanAmount = LoanMath.loanAmount(
      payment: payment,
      termMonths: _term,
      annualRatePercent: rate,
    );

    final docStamps = _disableDocStamps ? 0.0 : LoanMath.docStamps(loanAmount);
    final totalLoan = loanAmount + docStamps;

    setState(() {
      _loanAmount = loanAmount;
      _docStamps = docStamps;
      _totalLoan = totalLoan;
    });
  }

  String _formatCurrency(double value) {
    return '\$${CurrencyInputFormatter.formatResult(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child:
          isDesktop
              ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(child: _buildInputs(context)),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: _buildVisualization(context),
                    ),
                  ),
                ],
              )
              : ListView(
                children: [
                  _buildInputs(context),
                  const SizedBox(height: 32),
                  _buildVisualization(context),
                ],
              ),
    );
  }

  Widget _buildInputs(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AMOUNT CALCULATOR',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _paymentController,
            label: 'Desired Payment',
            icon: Icons.payments,
            focusNode: _paymentFocusNode,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _rateFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _rateController,
            label: 'APR (%)',
            icon: Icons.percent,
            focusNode: _rateFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _termFocusNode.requestFocus(),
          ),
          const SizedBox(height: 24),
          TerminalSlider(
            labelWidget: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'TERM: '),
                  TextSpan(
                    text: '$_term',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: ' MONTHS'),
                ],
              ),
            ),
            value: _term.toDouble(),
            min: 36,
            max: 84,
            divisions: 4,
            focusNode: _termFocusNode,
            onChanged: (value) {
              setState(() {
                _term = value.round();
              });
              _calculate();
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Disable Florida Doc Stamps'),
            value: _disableDocStamps,
            onChanged: (value) {
              setState(() {
                _disableDocStamps = value;
              });
              _calculate();
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearForm,
              icon: const Icon(Icons.refresh),
              label: const Text('RESET'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    bool autofocus = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    bool isCurrency = true,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isCurrency ? [CurrencyInputFormatter()] : [],
      style: GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        prefixText: isCurrency ? '\$ ' : null,
      ),
      onChanged: (_) => _calculate(),
    );
  }

  Widget _buildVisualization(BuildContext context) {
    final theme = Theme.of(context);

    if (_loanAmount == null) {
      return Center(
        child: Text(
          'Enter values to calculate',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      children: [
        DataReadout(
          label: 'LOAN AMOUNT (PRE-TAX)',
          value: _formatCurrency(_loanAmount!),
          isLarge: true,
          valueColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: DataReadout(
                label: 'DOC STAMPS',
                value: _formatCurrency(_docStamps ?? 0.0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DataReadout(
                label: 'TOTAL LOAN',
                value: _formatCurrency(_totalLoan ?? 0.0),
                valueColor: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
