import 'package:flutter/material.dart';
import 'engine/core_calculators.dart';

class IncomeCalculatorScreen extends StatefulWidget {
  const IncomeCalculatorScreen({super.key});

  @override
  State<IncomeCalculatorScreen> createState() => _IncomeCalculatorScreenState();
}

class _IncomeCalculatorScreenState extends State<IncomeCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ytdController = TextEditingController();

  DateTime? _checkDate;
  DateTime? _hireDate;

  double? _monthlyIncome;
  double? _annualIncome;
  String? _error;

  void _clearForm() {
    _ytdController.clear();
    setState(() {
      _checkDate = null;
      _hireDate = null;
      _monthlyIncome = null;
      _annualIncome = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    _ytdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required bool isCheckDate,
  }) async {
    final now = DateTime.now();
    final initial = isCheckDate
        ? (_checkDate ?? now)
        : (_hireDate ?? DateTime(now.year, 1, 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 3),
    );

    if (picked != null) {
      setState(() {
        if (isCheckDate) {
          _checkDate = picked;
        } else {
          _hireDate = picked;
        }
      });
    }
  }

  String? _requiredNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final v = double.tryParse(value);
    if (v == null) return 'Enter a number';
    if (v < 0) return 'Must be ≥ 0';
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    if (_checkDate == null) {
      setState(() {
        _error = 'Please select the date of the latest paystub.';
        _monthlyIncome = null;
        _annualIncome = null;
      });
      return;
    }

    final ytd = double.parse(_ytdController.text);

    final monthly = IncomeCalculator.monthlyIncome(
      ytdAmount: ytd,
      checkDate: _checkDate!,
      hireDate: _hireDate,
    );

    if (monthly == null) {
      setState(() {
        _error = 'Unable to determine income. Check dates and YTD amount.';
        _monthlyIncome = null;
        _annualIncome = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _monthlyIncome = monthly;
      _annualIncome = monthly * 12;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
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
              'Income Calculator',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ytdController,
              decoration: const InputDecoration(
                labelText: 'Year-to-Date Gross Income',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: _requiredNumberValidator,
            ),
            const SizedBox(height: 12),
            Text('Check Date'),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: () => _pickDate(isCheckDate: true),
              child: Text(_formatDate(_checkDate)),
            ),
            const SizedBox(height: 12),
            Text('Hire Date (optional)'),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: () => _pickDate(isCheckDate: false),
              child: Text(_formatDate(_hireDate)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Estimate Income'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _clearForm,
              child: const Text('Clear'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            if (_monthlyIncome != null && _annualIncome != null) ...[
              Text(
                'Estimated Monthly Gross Income',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_monthlyIncome!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Estimated Annual Gross Income',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_annualIncome!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
