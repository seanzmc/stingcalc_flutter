import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingcalc_flutter/payment_calculator_screen.dart';
import 'package:stingcalc_flutter/widgets/terminal_slider.dart';

void main() {
  testWidgets('PaymentCalculatorScreen refactor verification', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: PaymentCalculatorScreen())),
    );

    // 1. Verify Down Payment and Trade Value fields are GONE
    expect(find.text('Down Payment'), findsNothing);
    expect(find.text('Trade-in Value'), findsNothing);

    // 2. Verify Interest Rate input (TextField only, no Slider)
    expect(find.text('Rate (%)'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Loan Amount + Rate
    expect(find.byType(TerminalSlider), findsOneWidget); // Term only

    // Test Rate TextField interaction
    await tester.enterText(find.widgetWithText(TextField, 'Rate (%)'), '10.0');
    await tester.pump();

    // 3. Verify Term Selection (Slider)
    expect(find.text('TERM: 60 MONTHS'), findsOneWidget); // Default

    // Find the term slider
    final termSliderFinder = find.byType(TerminalSlider);
    expect(termSliderFinder, findsOneWidget);

    // Verify it is interactive
    await tester.tap(termSliderFinder); // Tapping center should change value
    await tester.pump();
  });
}
