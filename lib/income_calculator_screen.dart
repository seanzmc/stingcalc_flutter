import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/core_calculators.dart';
import 'widgets/data_readout.dart';

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

  DateTime? _checkDate;
  DateTime? _hireDate;

  double? _monthlyIncome;
  double? _annualIncome;
  String? _error;

  @override
  void dispose() {
    _ytdController.dispose();
    _checkDateController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _ytdController.clear();
    _checkDateController.clear();
    _hireDateController.clear();
    setState(() {
      _checkDate = null;
      _hireDate = null;
      _monthlyIncome = null;
      _annualIncome = null;
      _error = null;
    });
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final formatted = _formatDate(picked);
        if (isCheckDate) {
          _checkDate = picked;
          _checkDateController.text = formatted;
        } else {
          _hireDate = picked;
          _hireDateController.text = formatted;
        }
        _calculate();
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
            _calculate();
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

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    if (_checkDate == null) {
      setState(() {
        _monthlyIncome = null;
        _annualIncome = null;
      });
      return;
    }

    final ytd = double.tryParse(_ytdController.text);
    if (ytd == null) return;

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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INCOME CALCULATOR (YTD)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildInputs(context)),
                      const SizedBox(width: 32),
                      Expanded(child: _buildResults(context)),
                    ],
                  )
                else ...[
                  _buildInputs(context),
                  const SizedBox(height: 32),
                  _buildResults(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputs(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextFormField(
              controller: _ytdController,
              decoration: const InputDecoration(
                labelText: 'Year-to-Date Gross',
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calculate(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _checkDateController,
              decoration: InputDecoration(
                labelText: 'Check Date',
                hintText: 'MM/DD/YYYY',
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.event),
                  onPressed: () => _pickDate(isCheckDate: true),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _DateTextFormatter(),
              ],
              onChanged: (v) => _onDateTextChanged(v, true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hireDateController,
              decoration: InputDecoration(
                labelText: 'Hire Date (Optional)',
                hintText: 'MM/DD/YYYY',
                prefixIcon: const Icon(Icons.work_outline),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.event),
                  onPressed: () => _pickDate(isCheckDate: false),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _DateTextFormatter(),
              ],
              onChanged: (v) => _onDateTextChanged(v, false),
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
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        DataReadout(
          label: 'Monthly Gross',
          value: _monthlyIncome != null
              ? _formatCurrency(_monthlyIncome!)
              : '---',
          isLarge: true,
          icon: Icons.calendar_view_month,
        ),
        const SizedBox(height: 16),
        DataReadout(
          label: 'Annual Salary',
          value: _annualIncome != null
              ? _formatCurrency(_annualIncome!)
              : '---',
          valueColor: Theme.of(context).colorScheme.secondary,
          icon: Icons.calendar_today,
        ),
      ],
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
