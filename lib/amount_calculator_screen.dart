import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/core_calculators.dart';
import 'widgets/data_readout.dart';

class AmountCalculatorScreen extends StatefulWidget {
  const AmountCalculatorScreen({super.key});

  @override
  State<AmountCalculatorScreen> createState() => _AmountCalculatorScreenState();
}

class _AmountCalculatorScreenState extends State<AmountCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _paymentController = TextEditingController();
  final _rateController = TextEditingController(text: '6.9');
  final _termController = TextEditingController(text: '72');

  final _paymentFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();
  final _termFocusNode = FocusNode();

  bool _disableDocStamps = false;

  double? _loanAmount;
  double? _docStamps;
  double? _totalLoan;

  @override
  void dispose() {
    _paymentController.dispose();
    _rateController.dispose();
    _termController.dispose();
    _paymentFocusNode.dispose();
    _rateFocusNode.dispose();
    _termFocusNode.dispose();
    super.dispose();
  }

  void _clearForm() {
    _paymentController.clear();
    _rateController.text = '6.9';
    _termController.text = '72';
    setState(() {
      _disableDocStamps = false;
      _loanAmount = null;
      _docStamps = null;
      _totalLoan = null;
    });
  }

  void _calculate() {
    final payment = double.tryParse(_paymentController.text);
    final rate = double.tryParse(_rateController.text);
    final term = int.tryParse(_termController.text);

    if (payment == null || rate == null || term == null || term <= 0) {
      setState(() {
        _loanAmount = null;
        _docStamps = null;
        _totalLoan = null;
      });
      return;
    }

    final loanAmount = LoanMath.loanAmount(
      payment: payment,
      termMonths: term,
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Text(
                'AMOUNT CALCULATOR',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _paymentController,
                          focusNode: _paymentFocusNode,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => _rateFocusNode.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'Desired Payment',
                            prefixText: '\$ ',
                            prefixIcon: Icon(Icons.payments),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => _calculate(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _rateController,
                          focusNode: _rateFocusNode,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => _termFocusNode.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'APR',
                            suffixText: '%',
                            prefixIcon: Icon(Icons.percent),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => _calculate(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _termController,
                          focusNode: _termFocusNode,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Term (Months)',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculate(),
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
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_loanAmount != null) ...[
                DataReadout(
                  label: 'LOAN AMOUNT (PRE-TAX)',
                  value: _formatCurrency(_loanAmount!),
                  isLarge: true,
                  valueColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}
