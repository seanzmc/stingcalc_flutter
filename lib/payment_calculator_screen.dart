import 'package:flutter/material.dart';
import 'engine/core_calculators.dart';

class PaymentCalculatorScreen extends StatefulWidget {
  final double? initialLoanAmount;

  const PaymentCalculatorScreen({super.key, this.initialLoanAmount});

  @override
  State<PaymentCalculatorScreen> createState() =>
      _PaymentCalculatorScreenState();
}

class _PaymentCalculatorScreenState extends State<PaymentCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _loanAmountController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();

  final _loanFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();
  final _termFocusNode = FocusNode();

  bool _disableDocStamps = false;

  double? _payment;
  double? _docStamps;
  double? _totalLoan;
  double? _totalCost;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialLoanAmount != null) {
      _loanAmountController.text = widget.initialLoanAmount!.toStringAsFixed(2);
    }
    // sensible defaults
    _rateController.text = '6.9';
    _termController.text = '72';
  }

  @override
  void didUpdateWidget(covariant PaymentCalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When a new amount comes from Quick Pencil, update the field
    if (widget.initialLoanAmount != null &&
        widget.initialLoanAmount != oldWidget.initialLoanAmount) {
      _loanAmountController.text = widget.initialLoanAmount!.toStringAsFixed(2);
    }
  }

  void _clearForm() {
    _loanAmountController.clear();
    _rateController.text = '6.9';
    _termController.text = '72';

    setState(() {
      _disableDocStamps = false;
      _payment = null;
      _docStamps = null;
      _totalLoan = null;
      _totalCost = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _rateController.dispose();
    _termController.dispose();

    _loanFocusNode.dispose();
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

  void _calculate() {
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      setState(() {
        _errorMessage = 'Please fix the highlighted fields.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final loanAmount = double.parse(_loanAmountController.text);
    final rate = double.parse(_rateController.text);
    final term = int.parse(_termController.text);

    // Florida doc stamps on note, like your JS payment calc
    final docStamps = _disableDocStamps ? 0.0 : LoanMath.docStamps(loanAmount);
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
              controller: _loanAmountController,
              focusNode: _loanFocusNode,
              decoration: const InputDecoration(
                labelText: 'Loan Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
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
              keyboardType: TextInputType.number,
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
            Row(
              children: [
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Calculate Payment'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _clearForm,
                  child: const Text('Clear'),
                ),
              ],
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
                Text(
                  'Documentary Stamp Tax: \$${_docStamps!.toStringAsFixed(2)}',
                ),
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
