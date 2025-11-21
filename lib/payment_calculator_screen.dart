import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/core_calculators.dart';
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
  final _downPaymentController = TextEditingController();
  final _tradeInController = TextEditingController();

  double _rate = 6.9;
  int? _term;
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
    _calculate();
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _downPaymentController.dispose();
    _tradeInController.dispose();
    super.dispose();
  }

  void _calculate() {
    final loanAmount = double.tryParse(_loanAmountController.text) ?? 0.0;
    final downPayment = double.tryParse(_downPaymentController.text) ?? 0.0;
    final tradeIn = double.tryParse(_tradeInController.text) ?? 0.0;

    final netLoanAmount = loanAmount - downPayment - tradeIn;

    if (netLoanAmount <= 0) {
      setState(() {
        _monthlyPayment = 0;
        _totalInterest = 0;
        _totalPrincipal = 0;
        _totalCost = 0;
      });
      return;
    }

    if (_term == null) {
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
      termMonths: _term!,
      annualRatePercent: _rate,
    );

    final totalInterest = monthly * _term! - principalWithTax;
    final totalCost = principalWithTax + totalInterest;

    setState(() {
      _monthlyPayment = monthly;
      _totalPrincipal = principalWithTax;
      _totalInterest = totalInterest;
      _totalCost = totalCost;
    });
  }

  String _formatCurrency(double value) {
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child:
          isDesktop
              ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildInputs(context)),
                  const SizedBox(width: 32),
                  Expanded(flex: 5, child: _buildVisualization(context)),
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
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _downPaymentController,
                label: 'Down Payment',
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _tradeInController,
                label: 'Trade-in Value',
                icon: Icons.swap_horiz,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TerminalSlider(
          label: 'INTEREST RATE: ${_rate.toStringAsFixed(1)}%',
          value: _rate,
          min: 0.0,
          max: 25.0,
          onChanged: (value) {
            setState(() => _rate = value);
            _calculate();
          },
        ),
        const SizedBox(height: 24),
        Text('TERM (MONTHS)', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 36, label: Text('36')),
            ButtonSegment(value: 48, label: Text('48')),
            ButtonSegment(value: 60, label: Text('60')),
            ButtonSegment(value: 72, label: Text('72')),
            ButtonSegment(value: 84, label: Text('84')),
          ],
          selected: _term != null ? {_term!} : <int>{},
          onSelectionChanged: (Set<int> newSelection) {
            setState(() {
              _term = newSelection.isEmpty ? null : newSelection.first;
            });
            _calculate();
          },
          multiSelectionEnabled: false,
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: WidgetStateProperty.all(
              BorderSide(color: Theme.of(context).colorScheme.surface),
            ),
          ),
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
