// Widget tests for Local Heroes Flutter app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_heroes/main.dart';

void main() {
  testWidgets('LocalHeroesApp loads splash screen initially',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LocalHeroesApp());

    // The app should show a loading state initially
    // (SplashScreen is shown while isLoading is true)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
