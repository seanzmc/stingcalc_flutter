import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingcalc_flutter/payment_calculator_screen.dart';
import 'package:stingcalc_flutter/widgets/main_scaffold.dart';

void main() {
  testWidgets('Reverse tab navigation should go to previous field', (
    WidgetTester tester,
  ) async {
    // Build the app structure with sidebar (MainScaffold) and PaymentCalculatorScreen
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              // Dummy sidebar
              Container(
                width: 200,
                child: Column(
                  children: [
                    TextField(
                      key: Key('sidebar_input'),
                    ), // Focusable item in sidebar
                  ],
                ),
              ),
              Expanded(child: PaymentCalculatorScreen()),
            ],
          ),
        ),
      ),
    );

    // Wait for autofocus
    await tester.pump();

    // Find the fields
    final vehiclePriceFinder = find.widgetWithText(TextField, 'Vehicle Price');
    final rateFinder = find.widgetWithText(TextField, 'Rate (%)');

    // Ensure Vehicle Price is focused initially (due to autofocus)
    // Note: autofocus might not work in tester without pump, but let's check.
    // Actually, let's manually focus Rate to simulate the user being there.
    await tester.tap(rateFinder);
    await tester.pump();

    // Verify Rate has focus
    final rateField = tester.widget<TextField>(rateFinder);
    expect(rateField.focusNode!.hasFocus, isTrue);

    // Simulate Shift+Tab
    // In widget tests, we can simulate focus traversal.
    // tester.sendKeyEvent(LogicalKeyboardKey.tab) works for forward.
    // For reverse, we might need to use FocusManager or simulate the key combo.

    // Using nextFocus/previousFocus directly is more reliable for unit testing traversal logic
    // than simulating raw key events which depend on the embedding.
    FocusManager.instance.primaryFocus!.previousFocus();
    await tester.pump();

    // Verify Vehicle Price has focus
    final vehiclePriceField = tester.widget<TextField>(vehiclePriceFinder);

    // If the bug exists, this might fail (it might focus sidebar or nothing)
    expect(
      vehiclePriceField.focusNode!.hasFocus,
      isTrue,
      reason: 'Vehicle Price should be focused after Shift+Tab from Rate',
    );
  });
}
