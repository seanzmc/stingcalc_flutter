import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_calculator_screen.dart';
import 'amount_calculator_screen.dart';
import 'rate_solver_screen.dart';
import 'income_calculator_screen.dart';
import 'quick_pencil_screen.dart';
import 'widgets/main_scaffold.dart';

void main() {
  runApp(const StingcalcApp());
}

class StingcalcApp extends StatelessWidget {
  const StingcalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stingcalc',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark Slate
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8), // Sky Blue
          secondary: Color(0xFF818CF8), // Indigo
          surface: Color(0xFF1E293B), // Darker Slate
          onSurface: Color(0xFFCBD5E1), // Light Grey
          onSurfaceVariant: Color(0xFFF8FAFC), // White (Headers)
        ),
        textTheme: GoogleFonts.urbanistTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.urbanist(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
          ),
          displayMedium: GoogleFonts.urbanist(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
          ),
          displaySmall: GoogleFonts.urbanist(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
          ),
          headlineLarge: GoogleFonts.urbanist(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: GoogleFonts.urbanist(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: GoogleFonts.urbanist(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.urbanist(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
          ),
          titleMedium: GoogleFonts.urbanist(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
          ),
          titleSmall: GoogleFonts.urbanist(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: GoogleFonts.urbanist(
            color: const Color(0xFFCBD5E1),
          ),
          bodyMedium: GoogleFonts.urbanist(
            color: const Color(0xFFCBD5E1),
          ),
          labelLarge: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
          ),
          labelStyle: GoogleFonts.urbanist(color: const Color(0xFFCBD5E1)),
          hintStyle: GoogleFonts.urbanist(color: const Color(0xFF64748B)),
        ),
      ),
      home: const StingcalcHome(),
    );
  }
}

class StingcalcHome extends StatefulWidget {
  const StingcalcHome({super.key});

  @override
  State<StingcalcHome> createState() => _StingcalcHomeState();
}

class _StingcalcHomeState extends State<StingcalcHome> {
  int _selectedIndex = 0;
  double? _qpAmount; // amount to finance from Quick Pencil

  void _handleUseInPayment(double amount) {
    setState(() {
      _qpAmount = amount;
      _selectedIndex = 0; // switch to Payment tab
    });
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (_selectedIndex) {
      case 0:
        page = PaymentCalculatorScreen(initialLoanAmount: _qpAmount);
        break;
      case 1:
        page = const AmountCalculatorScreen();
        break;
      case 2:
        page = const RateSolverScreen();
        break;
      case 3:
        page = const IncomeCalculatorScreen();
        break;
      case 4:
        page = QuickPencilScreen(onUseInPayment: _handleUseInPayment);
        break;
      default:
        page = const Center(child: Text('Unknown Page'));
    }

    return MainScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      body: page,
    );
  }
}
