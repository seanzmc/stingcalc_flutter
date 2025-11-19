import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'engine/core_calculators.dart';

class IncomeCalculatorScreen extends StatefulWidget {
  const IncomeCalculatorScreen({super.key});

  @override
  State<IncomeCalculatorScreen> createState() => _IncomeCalculatorScreenState();
}

class _IncomeCalculatorScreenState extends State<IncomeCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ytdController = TextEditingController();
  final _checkDateController = TextEditingController();
  final _hireDateController = TextEditingController();

  final _ytdFocusNode = FocusNode();
  final _checkDateFocusNode = FocusNode();
  final _hireDateFocusNode = FocusNode();

  DateTime? _checkDate;
  DateTime? _hireDate;

  double? _monthlyIncome;
  double? _annualIncome;
  String? _error;

  void _clearForm() {
    _ytdController.clear();
    _checkDateController.clear();
    _hireDateController.clear();

    _ytdFocusNode.requestFocus();

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
    _checkDateController.dispose();
    _hireDateController.dispose();

    _ytdFocusNode.dispose();
    _checkDateFocusNode.dispose();
    _hireDateFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isCheckDate}) async {
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
        final formatted = _formatDate(picked);
        if (isCheckDate) {
          _checkDate = picked;
          _checkDateController.text = formatted;
          FocusScope.of(context).requestFocus(_hireDateFocusNode);
        } else {
          _hireDate = picked;
          _hireDateController.text = formatted;
        }
      });
    }
  }

  void _onDateTextChanged(String value, bool isCheckDate) {
    final parts = value.split('/');
    if (parts.length == 3 && parts[2].length == 4) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (month != null && day != null && year != null) {
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          setState(() {
            final date = DateTime(year, month, day);
            if (isCheckDate) {
              _checkDate = date;
            } else {
              _hireDate = date;
            }
          });
          return;
        }
      }
    }

    if (isCheckDate && _checkDate != null) {
      setState(() => _checkDate = null);
    } else if (!isCheckDate && _hireDate != null) {
      setState(() => _hireDate = null);
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

  String? _dateValidator(String? value, bool required) {
    if (!required && (value == null || value.isEmpty)) return null;
    if (required && (value == null || value.isEmpty)) return 'Required';
    if (value!.length != 10) return 'Enter MM/DD/YYYY';
    if (required && _checkDate == null) return 'Invalid date';
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
    if (!_formKey.currentState!.validate()) return;

    if (_checkDate == null) {
      setState(() {
        _error = 'Please enter a valid check date.';
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

  String _formatDate(DateTime date) {
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
              focusNode: _ytdFocusNode,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Year-to-Date Gross Income',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              // Updated keyboard type
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_checkDateFocusNode);
              },
              validator: _requiredNumberValidator,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _checkDateController,
              focusNode: _checkDateFocusNode,
              decoration: InputDecoration(
                labelText: 'Check Date (MM/DD/YYYY)',
                hintText: 'MM/DD/YYYY',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(isCheckDate: true),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _DateTextFormatter(),
              ],
              onChanged: (v) => _onDateTextChanged(v, true),
              validator: (v) => _dateValidator(v, true),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_hireDateFocusNode);
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _hireDateController,
              focusNode: _hireDateFocusNode,
              decoration: InputDecoration(
                labelText: 'Hire Date (optional)',
                hintText: 'MM/DD/YYYY',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(isCheckDate: false),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _DateTextFormatter(),
              ],
              onChanged: (v) => _onDateTextChanged(v, false),
              validator: (v) => _dateValidator(v, false),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _calculate(),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Estimate Income'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _clearForm,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_monthlyIncome != null && _annualIncome != null) ...[
              Text(
                'Estimated Monthly Gross Income',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(_monthlyIncome!),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Estimated Annual Gross Income',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(_annualIncome!),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) {
        buffer.write('/');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
