import 'package:flutter/material.dart';
import 'engine/core_calculators.dart';

class PaymentCalculatorScreen extends StatefulWidget {
  final double? initialLoanAmount;

  const PaymentCalculatorScreen({
    super.key,
    this.initialLoanAmount,
  });

  @override
  State<PaymentCalculatorScreen> createState() =>
      _PaymentCalculatorScreenState();
}

class _PaymentCalculatorScreenState extends State<PaymentCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _loanAmountController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();

  bool _disableDocStamps = false;

  double? _payment;
  double? _docStamps;
  double? _totalLoan;
  double? _totalCost;

  @override
  void initState() {
    super.initState();
    if (widget.initialLoanAmount != null) {
      _loanAmountController.text =
          widget.initialLoanAmount!.toStringAsFixed(2);
    }
  }

  @override
  void didUpdateWidget(covariant PaymentCalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When a new amount comes from Quick Pencil, update the field
    if (widget.initialLoanAmount != null &&
        widget.initialLoanAmount != oldWidget.initialLoanAmount) {
      _loanAmountController.text =
          widget.initialLoanAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
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

    final loanAmount = double.parse(_loanAmountController.text);
    final rate = double.parse(_rateController.text);
    final term = int.parse(_termController.text);

    // Florida doc stamps on note, like your JS payment calc
    final docStamps =
        _disableDocStamps ? 0.0 : LoanMath.docStamps(loanAmount);
    final principalWithTax = loanAmount + docStamps;

    final monthly = LoanMath.monthlyPayment(
      principal: principalWithTax,
      termMonths: term,
      annualRatePercent: rate,
    );

    final totalInterest = monthly * term - principalWithTax;
    final totalCost = principalWithTax + totalInterest;

    setState(() {
      _payment = monthly;
      _docStamps = docStamps;
      _totalLoan = principalWithTax;
      _totalCost = totalCost;
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
              'Payment Calculator',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _loanAmountController,
              decoration: const InputDecoration(
                labelText: 'Loan Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
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
              title: const Text('Disable Documentary Stamps'),
              value: _disableDocStamps,
              onChanged: (value) {
                setState(() {
                  _disableDocStamps = value;
                });
                if (_payment != null) {
                  _calculate();
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Calculate Payment'),
            ),
            if (_payment != null) ...[
              const SizedBox(height: 24),
              Text(
                'Estimated Payment',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_payment!.toStringAsFixed(2)} / month',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (_docStamps != null)
                Text('Documentary Stamp Tax: \$${_docStamps!.toStringAsFixed(2)}'),
              if (_totalLoan != null)
                Text('Total Loan Amount: \$${_totalLoan!.toStringAsFixed(2)}'),
              if (_totalCost != null)
                Text('Total Cost of Loan: \$${_totalCost!.toStringAsFixed(2)}'),
            ],
          ],
        ),
      ),
    );
  }
}
