import 'package:flutter/material.dart';
import 'engine/core_calculators.dart';

class AmountCalculatorScreen extends StatefulWidget {
  const AmountCalculatorScreen({super.key});

  @override
  State<AmountCalculatorScreen> createState() => _AmountCalculatorScreenState();
}

class _AmountCalculatorScreenState extends State<AmountCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _paymentController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();

  final _paymentFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();
  final _termFocusNode = FocusNode();

  bool _disableDocStamps = false;

  double? _loanAmount;
  double? _docStamps;
  double? _totalLoan;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rateController.text = '6.9';
    _termController.text = '72';
  }

  void _clearForm() {
    _paymentController.clear();
    _rateController.text = '6.9';
    _termController.text = '72';
    _paymentFocusNode.requestFocus();

    setState(() {
      _disableDocStamps = false;
      _loanAmount = null;
      _docStamps = null;
      _totalLoan = null;
      _errorMessage = null;
    });
  }

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

  String? _requiredNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final v = double.tryParse(value);
    if (v == null) return 'Enter a number';
    if (v <= 0) return 'Must be > 0';
    return null;
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

  void _calculate() {
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      setState(() {
        _errorMessage = 'Please fix the highlighted fields.';
      });
      return;
    }
    setState(() => _errorMessage = null);

    final payment = double.parse(_paymentController.text);
    final rate = double.parse(_rateController.text);
    final term = int.parse(_termController.text);

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'Loan Amount Calculator',
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
              controller: _paymentController,
              focusNode: _paymentFocusNode,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Desired Payment',
                prefixText: '\$',
              ),
              // Updated keyboard type
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _requiredNumberValidator,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_rateFocusNode);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rateController,
              focusNode: _rateFocusNode,
              decoration: const InputDecoration(
                labelText: 'APR',
                suffixText: '%',
              ),
              // Updated keyboard type
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _requiredNumberValidator,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_termFocusNode);
              },
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
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Disable Florida Doc Stamps'),
              value: _disableDocStamps,
              onChanged: (value) {
                setState(() {
                  _disableDocStamps = value;
                });
                if (_loanAmount != null) _calculate();
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Calculate Loan Amount'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _clearForm,
                  child: const Text('Clear'),
                ),
              ],
            ),
            if (_loanAmount != null) ...[
              const SizedBox(height: 24),
              Text(
                'Loan Amount (before doc stamps)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(_loanAmount!),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (_docStamps != null)
                Text(
                  'Documentary Stamp Tax: ${_formatCurrency(_docStamps!)}',
                ),
              if (_totalLoan != null)
                Text('Total Loan Amount: ${_formatCurrency(_totalLoan!)}'),
            ],
          ],
        ),
      ),
    );
  }
}
