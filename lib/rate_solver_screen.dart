import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/core_calculators.dart';
import 'utils/currency_input_formatter.dart';
import 'widgets/data_readout.dart';
import 'widgets/terminal_slider.dart';

class RateSolverScreen extends StatefulWidget {
  const RateSolverScreen({super.key});

  @override
  State<RateSolverScreen> createState() => _RateSolverScreenState();
}

class _RateSolverScreenState extends State<RateSolverScreen> {
  final _principalController = TextEditingController();
  final _paymentController = TextEditingController();

  final _principalFocusNode = FocusNode();
  final _paymentFocusNode = FocusNode();
  final _termFocusNode = FocusNode();

  int _term = 72;
  double? _ratePercent;
  double? _minPayment;
  String? _message;

  @override
  void initState() {
    super.initState();
    // Add listeners for select-all on focus
    _principalFocusNode.addListener(
      () => _selectAllOnFocus(_principalFocusNode, _principalController),
    );
    _paymentFocusNode.addListener(
      () => _selectAllOnFocus(_paymentFocusNode, _paymentController),
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
    _principalController.dispose();
    _paymentController.dispose();
    _principalFocusNode.dispose();
    _paymentFocusNode.dispose();
    _termFocusNode.dispose();
    super.dispose();
  }

  void _clearForm() {
    _principalController.clear();
    _paymentController.clear();
    setState(() {
      _term = 72;
      _ratePercent = null;
      _minPayment = null;
      _message = null;
    });
    // Focus back on the first field
    _principalFocusNode.requestFocus();
  }

  void _calculate() {
    final principal = CurrencyInputFormatter.parse(_principalController.text);
    final payment = CurrencyInputFormatter.parse(_paymentController.text);

    if (principal <= 0 || payment <= 0) {
      setState(() {
        _ratePercent = null;
        _minPayment = null;
        _message = null;
      });
      return;
    }

    final minPayment = principal / _term;
    if (payment < minPayment) {
      setState(() {
        _ratePercent = null;
        _minPayment = minPayment;
        _message = 'Payment too low';
      });
      return;
    }

    final rate = LoanMath.interestRate(
      principal: principal,
      termMonths: _term,
      targetPayment: payment,
    );

    setState(() {
      _ratePercent = rate;
      _minPayment = null;
      _message = rate == null ? 'Unable to solve' : null;
    });
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
            'RATE SOLVER',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _principalController,
            label: 'Loan Amount',
            icon: Icons.account_balance,
            focusNode: _principalFocusNode,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _paymentFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _paymentController,
            label: 'Target Payment',
            icon: Icons.payments,
            focusNode: _paymentFocusNode,
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

    if (_minPayment != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _message ?? 'Error',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DataReadout(
            label: 'MINIMUM PAYMENT',
            value: '\$${CurrencyInputFormatter.formatResult(_minPayment!)}',
            isLarge: true,
            valueColor: theme.colorScheme.error,
            icon: Icons.warning_amber_rounded,
          ),
        ],
      );
    }

    if (_message != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _message!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    if (_ratePercent == null) {
      return Center(
        child: Text(
          'Enter values to calculate',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return DataReadout(
      label: 'REQUIRED APR',
      value: '${_ratePercent!.toStringAsFixed(2)}%',
      isLarge: true,
      valueColor: theme.colorScheme.primary,
      icon: Icons.percent,
    );
  }
}
