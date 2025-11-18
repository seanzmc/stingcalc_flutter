import 'package:flutter/material.dart';
import 'payment_calculator_screen.dart';
import 'amount_calculator_screen.dart';
import 'rate_solver_screen.dart';
import 'income_calculator_screen.dart';
import 'quick_pencil_screen.dart';

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
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
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

class _StingcalcHomeState extends State<StingcalcHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  double? _qpAmount; // amount to finance from Quick Pencil

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleUseInPayment(double amount) {
    setState(() {
      _qpAmount = amount;
      _tabController.index = 0; // switch to Payment tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stingcalc v0.1.3'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Payment'),
            Tab(text: 'Amount'),
            Tab(text: 'Rate'),
            Tab(text: 'Income'),
            Tab(text: 'Quick Pencil'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PaymentCalculatorScreen(initialLoanAmount: _qpAmount),
          const AmountCalculatorScreen(),
          const RateSolverScreen(),
          const IncomeCalculatorScreen(),
          QuickPencilScreen(onUseInPayment: _handleUseInPayment),
        ],
      ),
    );
  }
}
