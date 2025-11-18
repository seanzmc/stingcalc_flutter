import 'package:flutter/material.dart';
import 'engine/core_calculators.dart';

class RateSolverScreen extends StatefulWidget {
  const RateSolverScreen({super.key});

  @override
  State<RateSolverScreen> createState() => _RateSolverScreenState();
}

class _RateSolverScreenState extends State<RateSolverScreen> {
  final _formKey = GlobalKey<FormState>();

  final _principalController = TextEditingController();
  final _paymentController = TextEditingController();
  final _termController = TextEditingController();

  // Define unique FocusNodes for the input fields
  final _principalFocusNode = FocusNode();
  final _paymentFocusNode = FocusNode();
  final _termFocusNode = FocusNode();

  double? _ratePercent;
  String? _message;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _termController.text = '72';
  }

  void _clearForm() {
    _principalController.clear();
    _paymentController.clear();
    _termController.text = '72';

    // Reset focus to the first field when clearing
    _principalFocusNode.requestFocus();

    setState(() {
      _ratePercent = null;
      _message = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _principalController.dispose();
    _paymentController.dispose();
    _termController.dispose();

    // Dispose of FocusNodes
    _principalFocusNode.dispose();
    _paymentFocusNode.dispose();
    _termFocusNode.dispose();
    super.dispose();
  }

  String? _requiredNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final v = double.tryParse(value);
    if (v == null) return 'Enter a number';
    if (v <= 0) return 'Must be > 0';
    return null;
  }

  void _calculate() {
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      setState(() {
        _errorMessage = 'Please fix the highlighted fields.';
        _ratePercent = null;
      });
      return;
    }

    final principal = double.parse(_principalController.text);
    final payment = double.parse(_paymentController.text);
    final term = int.parse(_termController.text);

    final minPayment = principal / term;
    if (payment < minPayment) {
      setState(() {
        _errorMessage = null;
        _ratePercent = null;
        _message =
            'Payment too low to amortize loan. Minimum possible payment is '
            '\$${minPayment.toStringAsFixed(2)}.';
      });
      return;
    }

    final rate = LoanMath.interestRate(
      principal: principal,
      termMonths: term,
      targetPayment: payment,
    );

    setState(() {
      _errorMessage = null;
      _ratePercent = rate;
      _message =
          rate == null
              ? 'Unable to calculate a valid rate. Check the payment and term.'
              : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'Interest Rate Solver',
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
            TextFormField(
              controller: _principalController,
              focusNode: _principalFocusNode,
              decoration: const InputDecoration(
                labelText: 'Loan Amount / Principal',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_paymentFocusNode);
              },
              validator: _requiredNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paymentController,
              focusNode: _paymentFocusNode,
              decoration: const InputDecoration(
                labelText: 'Target Payment',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_termFocusNode);
              },
              validator: _requiredNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _termController,
              focusNode: _termFocusNode,
              decoration: const InputDecoration(labelText: 'Term (months)'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: (value) {
                final basic = _requiredNumberValidator(value);
                if (basic != null) return basic;
                final v = int.tryParse(value!.trim());
                if (v == null) return 'Enter a whole number';
                if (v <= 0) return 'Term must be > 0';
                return null;
              },
              onFieldSubmitted: (_) => _calculate(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Solve for Rate'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _clearForm,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_ratePercent != null) ...[
              Text(
                'Required APR',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${_ratePercent!.toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ] else if (_message != null) ...[
              Text(
                _message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
