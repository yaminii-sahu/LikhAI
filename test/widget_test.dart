import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likh_ai/main.dart';
import 'package:likh_ai/widgets/likh_logo.dart';

void main() {
  testWidgets('LikhBrandLogo light and dark variants render correctly', (WidgetTester tester) async {
    // 1. Test Light Mode Logo Variant
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LikhBrandLogo.light(
            showTagline: true,
          ),
        ),
      ),
    );

    expect(find.text('LIKH'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Your handwriting. Digitized.'), findsOneWidget);

    // 2. Test Dark Mode Logo Variant
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LikhBrandLogo.dark(
            showTagline: true,
          ),
        ),
      ),
    );

    expect(find.text('LIKH'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Your handwriting. Digitized.'), findsOneWidget);
  });

  testWidgets('LIKH AI App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LikhAIApp());
    // Initial splash frame
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('LIKH'), findsWidgets);
    expect(find.text('AI'), findsWidgets);

    // Pump past splash timer to transition to home
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify LIKH AI branding is present on home
    expect(find.text('LIKH'), findsWidgets);
    expect(find.text('AI'), findsWidgets);
    expect(find.text('Your handwriting. Digitized.'), findsWidgets);
  });
}
