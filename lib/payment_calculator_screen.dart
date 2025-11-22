import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/core_calculators.dart';
import 'utils/currency_input_formatter.dart';
import 'widgets/data_readout.dart';
import 'widgets/terminal_chart.dart';
import 'widgets/terminal_slider.dart';

class PaymentCalculatorScreen extends StatefulWidget {
  final double? initialLoanAmount;

  const PaymentCalculatorScreen({super.key, this.initialLoanAmount});

  @override
  State<PaymentCalculatorScreen> createState() =>
      _PaymentCalculatorScreenState();
}

class _PaymentCalculatorScreenState extends State<PaymentCalculatorScreen> {
  // Inputs
  final _loanAmountController = TextEditingController();
  final _rateController = TextEditingController();

  final _loanAmountFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();

  double _rate = 6.9;
  int _term = 60;
  bool _disableDocStamps = false;

  // Results
  double _monthlyPayment = 0;
  double _totalInterest = 0;
  double _totalPrincipal = 0;
  double _totalCost = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialLoanAmount != null) {
      _loanAmountController.text = widget.initialLoanAmount!.toStringAsFixed(2);
    }
    _rateController.text = _rate.toStringAsFixed(1);
    _calculate();
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _rateController.dispose();
    _loanAmountFocusNode.dispose();
    _rateFocusNode.dispose();
    super.dispose();
  }

  void _calculate() {
    final loanAmount = CurrencyInputFormatter.parse(_loanAmountController.text);

    final netLoanAmount = loanAmount;

    if (netLoanAmount <= 0) {
      setState(() {
        _monthlyPayment = 0;
        _totalInterest = 0;
        _totalPrincipal = 0;
        _totalCost = 0;
      });
      return;
    }

    final docStamps =
        _disableDocStamps ? 0.0 : LoanMath.docStamps(netLoanAmount);
    final principalWithTax = netLoanAmount + docStamps;

    final monthly = LoanMath.monthlyPayment(
      principal: principalWithTax,
      termMonths: _term,
      annualRatePercent: _rate,
    );

    final totalInterest = monthly * _term - principalWithTax;
    final totalCost = principalWithTax + totalInterest;

    setState(() {
      _monthlyPayment = monthly;
      _totalPrincipal = principalWithTax;
      _totalInterest = totalInterest;
      _totalCost = totalCost;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOAN DETAILS',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _loanAmountController,
          label: 'Vehicle Price',
          icon: Icons.directions_car,
          focusNode: _loanAmountFocusNode,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _rateFocusNode.requestFocus(),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: _rateController,
                focusNode: _rateFocusNode,
                textInputAction: TextInputAction.done,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Rate (%)',
                  prefixIcon: Icon(Icons.percent, size: 20),
                ),
                onChanged: (value) {
                  final newRate = double.tryParse(value);
                  if (newRate != null && newRate >= 0 && newRate <= 25) {
                    setState(() {
                      _rate = newRate;
                    });
                    _calculate();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TerminalSlider(
                value: _rate,
                min: 0.0,
                max: 25.0,
                onChanged: (value) {
                  setState(() {
                    _rate = value;
                    _rateController.text = _rate.toStringAsFixed(1);
                  });
                  _calculate();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TerminalSlider(
          label: 'TERM: $_term MONTHS',
          value: _term.toDouble(),
          min: 36,
          max: 84,
          divisions: 4,
          onChanged: (value) {
            setState(() {
              _term = value.round();
            });
            _calculate();
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Disable Documentary Stamps'),
          value: _disableDocStamps,
          onChanged: (value) {
            setState(() => _disableDocStamps = value);
            _calculate();
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
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
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [CurrencyInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        prefixText: '\$ ',
      ),
      onChanged: (_) => _calculate(),
    );
  }

  Widget _buildVisualization(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        DataReadout(
          label: 'Monthly Payment',
          value: _formatCurrency(_monthlyPayment),
          isLarge: true,
          valueColor: colorScheme.primary,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 300,
          child: TerminalChart(
            centerText: _formatCurrency(_totalCost),
            subCenterText: 'Total Cost',
            sections: [
              PieChartSectionData(
                color: colorScheme.primary,
                value: _totalPrincipal,
                title:
                    '${((_totalPrincipal / _totalCost) * 100).toStringAsFixed(0)}%',
                radius: 25,
                titleStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
              PieChartSectionData(
                color: colorScheme.secondary,
                value: _totalInterest,
                title:
                    '${((_totalInterest / _totalCost) * 100).toStringAsFixed(0)}%',
                radius: 25,
                titleStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              context,
              color: colorScheme.primary,
              label: 'Principal',
              value: _formatCurrency(_totalPrincipal),
            ),
            const SizedBox(width: 24),
            _buildLegendItem(
              context,
              color: colorScheme.secondary,
              label: 'Interest',
              value: _formatCurrency(_totalInterest),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
