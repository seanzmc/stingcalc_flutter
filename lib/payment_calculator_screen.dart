import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/core_calculators.dart';
import 'utils/currency_input_formatter.dart';
import 'widgets/data_readout.dart';
import 'widgets/terminal_chart.dart';
import 'widgets/terminal_slider.dart';
import 'widgets/amortization_modal.dart';

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
  final _termFocusNode = FocusNode();

  double _rate = 6.9;
  int _term = 60;

  // Focus Nodes

  // Results
  double _monthlyPayment = 0;
  double _totalInterest = 0;
  double _totalPrincipal = 0;
  double _totalCost = 0;

  // Biweekly Comparison
  // Biweekly Comparison
  BiweeklyResult? _biweeklyResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialLoanAmount != null) {
      _loanAmountController.text = widget.initialLoanAmount!.toStringAsFixed(2);
    }
    _rateController.text = _rate.toStringAsFixed(1);

    // Add listeners for select-all on focus
    _loanAmountFocusNode.addListener(
      () => _selectAllOnFocus(_loanAmountFocusNode, _loanAmountController),
    );
    _rateFocusNode.addListener(
      () => _selectAllOnFocus(_rateFocusNode, _rateController),
    );

    _calculate();
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
    _loanAmountController.dispose();
    _rateController.dispose();
    _loanAmountFocusNode.dispose();
    _rateFocusNode.dispose();
    _termFocusNode.dispose();
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

    final principalWithTax = netLoanAmount;

    final monthly = LoanMath.monthlyPayment(
      principal: principalWithTax,
      termMonths: _term,
      annualRatePercent: _rate,
    );

    final totalInterest = monthly * _term - principalWithTax;
    final totalCost = principalWithTax + totalInterest;

    BiweeklyResult? biweeklyResult;
    biweeklyResult = LoanMath.calculateBiweeklyAmortization(
      principal: principalWithTax,
      annualRatePercent: _rate,
      monthlyPayment: monthly,
    );

    setState(() {
      _monthlyPayment = monthly;
      _totalPrincipal = principalWithTax;
      _totalInterest = totalInterest;
      _totalCost = totalCost;
      _biweeklyResult = biweeklyResult;
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
          const SizedBox(height: 16),
          TextField(
            controller: _rateController,
            focusNode: _rateFocusNode,
            textInputAction: TextInputAction.next,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
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
          const SizedBox(height: 24),
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
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [CurrencyInputFormatter()],
      style: GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
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
        // Standard Monthly Payment
        DataReadout(
          label: 'Monthly Payment',
          value: _formatCurrency(_monthlyPayment),
          isLarge: true,
          valueColor: colorScheme.primary,
        ),
        const SizedBox(height: 32),

        // Side-by-Side Charts
        LayoutBuilder(
          builder: (context, constraints) {
            // Check if we have enough width for side-by-side
            final isWide = constraints.maxWidth > 600;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildChartSection(
                      context,
                      'Standard',
                      _totalCost,
                      _totalPrincipal,
                      _totalInterest,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildChartSection(
                      context,
                      'Biweekly',
                      _biweeklyResult?.totalCost ?? 0,
                      _totalPrincipal,
                      _biweeklyResult?.totalInterest ?? 0,
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildChartSection(
                    context,
                    'Standard',
                    _totalCost,
                    _totalPrincipal,
                    _totalInterest,
                  ),
                  const SizedBox(height: 32),
                  _buildChartSection(
                    context,
                    'Biweekly',
                    _biweeklyResult?.totalCost ?? 0,
                    _totalPrincipal,
                    _biweeklyResult?.totalInterest ?? 0,
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 32),

        // Combined Summary
        if (_biweeklyResult != null) _buildCombinedSummary(context),
      ],
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    String title,
    double totalCost,
    double principal,
    double interest,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
            color: colorScheme.secondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200, // Slightly smaller height for side-by-side
          child: TerminalChart(
            centerText: _formatCurrency(totalCost),
            subCenterText: 'Total Cost',
            sections: [
              PieChartSectionData(
                color: colorScheme.primary,
                value: principal,
                title: '${((principal / totalCost) * 100).toStringAsFixed(0)}%',
                radius: 20,
                titleStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
              PieChartSectionData(
                color: colorScheme.secondary,
                value: interest,
                title: '${((interest / totalCost) * 100).toStringAsFixed(0)}%',
                radius: 20,
                titleStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Simplified Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              context,
              color: colorScheme.secondary,
              label: 'Interest',
              value: _formatCurrency(interest),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCombinedSummary(BuildContext context) {
    final savings = _totalInterest - (_biweeklyResult?.totalInterest ?? 0);
    final monthsSaved =
        _term -
        ((_biweeklyResult?.payoffDate.difference(DateTime.now()).inDays ?? 0) /
                30)
            .round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.savings_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'BIWEEKLY SAVINGS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  context,
                  'Interest Saved',
                  _formatCurrency(savings),
                  isPositive: true,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: _buildSummaryMetric(
                  context,
                  'Time Saved',
                  '$monthsSaved months',
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder:
                      (context) => AmortizationModal(
                        biweeklySchedule: _biweeklyResult!.schedule,
                        monthlyPayment: _monthlyPayment,
                        principal: _totalPrincipal,
                        rate: _rate,
                        termMonths: _term,
                      ),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('View Amortization Schedule'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context,
    String label,
    String value, {
    bool isPositive = false,
  }) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : null,
          ),
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
