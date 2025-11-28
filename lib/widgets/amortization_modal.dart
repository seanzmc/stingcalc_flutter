import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../engine/core_calculators.dart';

class AmortizationModal extends StatefulWidget {
  final List<AmortizationEntry> biweeklySchedule;
  final double monthlyPayment;
  final double principal;
  final double rate;
  final int termMonths;

  const AmortizationModal({
    super.key,
    required this.biweeklySchedule,
    required this.monthlyPayment,
    required this.principal,
    required this.rate,
    required this.termMonths,
  });

  @override
  State<AmortizationModal> createState() => _AmortizationModalState();
}

class _AmortizationModalState extends State<AmortizationModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<AmortizationEntry> _monthlySchedule;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _monthlySchedule = _generateMonthlySchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AmortizationEntry> _generateMonthlySchedule() {
    final schedule = <AmortizationEntry>[];
    double balance = widget.principal;
    final monthlyRate = widget.rate / 100 / 12;
    DateTime date = DateTime.now();

    for (int i = 0; i < widget.termMonths; i++) {
      final interest = balance * monthlyRate;
      final principal = widget.monthlyPayment - interest;
      balance -= principal;
      if (balance < 0) balance = 0;

      date = DateTime(date.year, date.month + 1, date.day);

      schedule.add(
        AmortizationEntry(
          date: date,
          payment: widget.monthlyPayment,
          interest: interest,
          principal: principal,
          balance: balance,
        ),
      );
    }
    return schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Amortization Schedule',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Monthly (Standard)'),
              Tab(text: 'Biweekly (Accelerated)'),
            ],
            labelStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.jetBrainsMono(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleList(_monthlySchedule),
                _buildScheduleList(widget.biweeklySchedule),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<AmortizationEntry> schedule) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child: _buildHeader('Date')),
              Expanded(child: _buildHeader('Payment')),
              Expanded(child: _buildHeader('Interest')),
              Expanded(child: _buildHeader('Principal')),
              Expanded(child: _buildHeader('Balance')),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: schedule.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = schedule[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MMM yyyy').format(entry.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '\$${entry.payment.toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '\$${entry.interest.toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.red[300],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '\$${entry.principal.toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.green[300],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '\$${entry.balance.toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }
}
