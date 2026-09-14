import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:abick_nc/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const AbickNcApp());

    // Verify the app renders a loading indicator while checking session
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
