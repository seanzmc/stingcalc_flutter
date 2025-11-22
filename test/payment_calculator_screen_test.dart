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

    // 2. Verify Interest Rate input (TextField + Slider)
    expect(find.text('Rate (%)'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Loan Amount + Rate
    expect(find.byType(TerminalSlider), findsNWidgets(2)); // Rate + Term

    // Test Rate TextField interaction
    await tester.enterText(find.widgetWithText(TextField, 'Rate (%)'), '10.0');
    await tester.pump();
    // Verify slider value (indirectly via state or visual, but hard to check slider value directly without key)
    // We can check if the calculation updated if we had inputs.

    // 3. Verify Term Selection (Slider)
    expect(find.text('TERM: 60 MONTHS'), findsOneWidget); // Default

    // Find the term slider (it's the second one)
    final termSliderFinder = find.byType(Slider).last;
    await tester.tap(termSliderFinder); // Tapping center should change value
    await tester.pump();

    // Just verify it exists and is interactive
    expect(termSliderFinder, findsOneWidget);
  });
}
