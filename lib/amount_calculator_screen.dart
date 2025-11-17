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

  bool _disableDocStamps = false;

  double? _loanAmount;
  double? _docStamps;
  double? _totalLoan;

  @override
  void initState() {
    super.initState();
    _rateController.text = '6.9';
    _termController.text = '72';
  }

  @override
  void dispose() {
    _paymentController.dispose();
    _rateController.dispose();
    _termController.dispose();
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
    if (!_formKey.currentState!.validate()) return;

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
            const SizedBox(height: 12),
            TextFormField(
              controller: _paymentController,
              decoration: const InputDecoration(
                labelText: 'Desired Payment',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              validator: _requiredNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rateController,
              decoration: const InputDecoration(
                labelText: 'APR',
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              validator: _requiredNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _termController,
              decoration: const InputDecoration(
                labelText: 'Term (months)',
              ),
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
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Calculate Loan Amount'),
            ),
            if (_loanAmount != null) ...[
              const SizedBox(height: 24),
              Text(
                'Loan Amount (before doc stamps)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_loanAmount!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (_docStamps != null)
                Text('Documentary Stamp Tax: \$${_docStamps!.toStringAsFixed(2)}'),
              if (_totalLoan != null)
                Text('Total Loan Amount: \$${_totalLoan!.toStringAsFixed(2)}'),
            ],
          ],
        ),
      ),
    );
  }
}
