import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boo/screens/splash_screen.dart';

void main() {
  testWidgets('routes after the splash animation without a fixed long delay',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(next: Text('next route')),
      ),
    );

    await tester.pump(const Duration(milliseconds: 801));
    expect(find.text('next route'), findsOneWidget);
  });

  testWidgets('disposed splash does not navigate later', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(next: Text('next route')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(const MaterialApp(home: Text('replacement')));
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('replacement'), findsOneWidget);
    expect(find.text('next route'), findsNothing);
  });
}
