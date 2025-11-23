import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'engine/core_calculators.dart';
import 'utils/currency_input_formatter.dart';
import 'widgets/data_readout.dart';

class IncomeCalculatorScreen extends StatefulWidget {
  const IncomeCalculatorScreen({super.key});

  @override
  State<IncomeCalculatorScreen> createState() => _IncomeCalculatorScreenState();
}

class _IncomeCalculatorScreenState extends State<IncomeCalculatorScreen> {
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
    // Focus back on the first field
    _ytdFocusNode.requestFocus();
  }

  Future<void> _pickDate({required bool isCheckDate}) async {
    final now = DateTime.now();
    final initial =
        isCheckDate
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
    if (parts.length == 3) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final rawYear = int.tryParse(parts[2]);

      if (month != null && day != null && rawYear != null) {
        var year = rawYear;
        // Handle 2-digit years
        if (year < 100) {
          year += 2000;
        }

        if (month >= 1 &&
            month <= 12 &&
            day >= 1 &&
            day <= 31 &&
            year >= 1900) {
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
      setState(() {
        _checkDate = null;
        _calculate();
      });
    } else if (!isCheckDate && _hireDate != null) {
      setState(() {
        _hireDate = null;
        _calculate();
      });
    }
  }

  void _calculate() {
    if (_checkDate == null) {
      setState(() {
        _monthlyIncome = null;
        _annualIncome = null;
      });
      return;
    }

    final ytd = CurrencyInputFormatter.parse(_ytdController.text);
    if (ytd <= 0) return;

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
    return '\$${CurrencyInputFormatter.formatResult(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child:
          isDesktop
              ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(child: _buildInputs(context)),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(child: _buildResults(context)),
                  ),
                ],
              )
              : ListView(
                children: [
                  _buildInputs(context),
                  const SizedBox(height: 32),
                  _buildResults(context),
                ],
              ),
    );
  }

  Widget _buildInputs(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INCOME CALCULATOR (YTD)',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _ytdController,
            label: 'Year-to-Date Gross',
            icon: Icons.attach_money,
            focusNode: _ytdFocusNode,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _checkDateFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _checkDateController,
            label: 'Check Date',
            icon: Icons.calendar_today,
            focusNode: _checkDateFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _hireDateFocusNode.requestFocus(),
            hintText: 'MM/DD/YY',
            isDate: true,
            onIconPressed: () => _pickDate(isCheckDate: true),
            onChanged: (v) => _onDateTextChanged(v, true),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _hireDateController,
            label: 'Hire Date (Optional)',
            icon: Icons.work_outline,
            focusNode: _hireDateFocusNode,
            textInputAction: TextInputAction.done,
            hintText: 'MM/DD/YY',
            isDate: true,
            onIconPressed: () => _pickDate(isCheckDate: false),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    bool autofocus = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    String? hintText,
    bool isDate = false,
    VoidCallback? onIconPressed,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      keyboardType:
          isDate
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters:
          isDate
              ? [FilteringTextInputFormatter.digitsOnly, _DateTextFormatter()]
              : [CurrencyInputFormatter()],
      style: GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20),
        prefixText: isDate ? null : '\$ ',
        suffixIcon:
            isDate
                ? IconButton(
                  icon: const Icon(Icons.event),
                  onPressed: onIconPressed,
                )
                : null,
      ),
      onChanged: onChanged ?? (_) => _calculate(),
    );
  }

  Widget _buildResults(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    if (_monthlyIncome == null) {
      return Center(
        child: Text(
          'Enter values to calculate',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      children: [
        DataReadout(
          label: 'Monthly Gross',
          value: _formatCurrency(_monthlyIncome!),
          isLarge: true,
          icon: Icons.calendar_view_month,
          valueColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        DataReadout(
          label: 'Annual Salary',
          value: _formatCurrency(_annualIncome!),
          valueColor: theme.colorScheme.secondary,
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
    if (text.length > 6) return oldValue;

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
