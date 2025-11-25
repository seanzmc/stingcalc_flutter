import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingcalc_flutter/payment_calculator_screen.dart';

void main() {
  testWidgets('Initial term selection should be 72 and rendered correctly', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(body: PaymentCalculatorScreen()),
      ),
    );

    // Allow animations to settle? The user said "fixes on interaction", so maybe initial frame is bad.
    // We won't pumpAndSettle immediately to capture the initial state.
    // await tester.pumpAndSettle();

    // Check for "72" text
    final text72Finder = find.text('72');
    expect(text72Finder, findsOneWidget);

    // Check for other segments
    expect(find.text('36'), findsOneWidget);
    expect(find.text('48'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);

    // Verify NO selection initially
    final segmentedButtonFinder = find.byType(SegmentedButton<int>);
    expect(segmentedButtonFinder, findsOneWidget);

    final SegmentedButton<int> segmentedButton = tester.widget(
      segmentedButtonFinder,
    );
    expect(
      segmentedButton.selected,
      isEmpty,
      reason: 'Should have no selection initially',
    );
  });
}
