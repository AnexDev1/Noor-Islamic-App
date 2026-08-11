// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noor/core/providers/app_providers.dart';
import 'package:noor/main.dart';

void main() {
  testWidgets('app starts inside its provider scope', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MyApp), findsOneWidget);
  });
}
