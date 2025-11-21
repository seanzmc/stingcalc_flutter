import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/core_calculators.dart';
import 'widgets/data_readout.dart';

class RateSolverScreen extends StatefulWidget {
  const RateSolverScreen({super.key});

  @override
  State<RateSolverScreen> createState() => _RateSolverScreenState();
}

class _RateSolverScreenState extends State<RateSolverScreen> {
  final _formKey = GlobalKey<FormState>();

  final _principalController = TextEditingController();
  final _paymentController = TextEditingController();
  final _termController = TextEditingController(text: '72');

  double? _ratePercent;
  String? _message;

  @override
  void dispose() {
    _principalController.dispose();
    _paymentController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _principalController.clear();
    _paymentController.clear();
    _termController.text = '72';
    setState(() {
      _ratePercent = null;
      _message = null;
    });
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text);
    final payment = double.tryParse(_paymentController.text);
    final term = int.tryParse(_termController.text);

    if (principal == null || payment == null || term == null || term <= 0) {
      setState(() {
        _ratePercent = null;
        _message = null;
      });
      return;
    }

    final minPayment = principal / term;
    if (payment < minPayment) {
      setState(() {
        _ratePercent = null;
        _message =
            'Payment too low. Min: \$${minPayment.toStringAsFixed(2)}';
      });
      return;
    }

    final rate = LoanMath.interestRate(
      principal: principal,
      termMonths: term,
      targetPayment: payment,
    );

    setState(() {
      _ratePercent = rate;
      _message = rate == null ? 'Unable to solve' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RATE SOLVER',
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
                          controller: _principalController,
                          decoration: const InputDecoration(
                            labelText: 'Loan Amount',
                            prefixText: '\$ ',
                            prefixIcon: Icon(Icons.account_balance),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _calculate(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _paymentController,
                          decoration: const InputDecoration(
                            labelText: 'Target Payment',
                            prefixText: '\$ ',
                            prefixIcon: Icon(Icons.payments),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _calculate(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _termController,
                          decoration: const InputDecoration(
                            labelText: 'Term (Months)',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculate(),
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
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DataReadout(
                  label: 'REQUIRED APR',
                  value: _ratePercent != null
                      ? '${_ratePercent!.toStringAsFixed(2)}%'
                      : '---',
                  isLarge: true,
                  valueColor: theme.colorScheme.primary,
                  icon: Icons.percent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
