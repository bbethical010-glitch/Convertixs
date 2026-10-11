import 'package:flutter_test/flutter_test.dart';
import 'package:convertix/app/app.dart';
import 'package:convertix/core/providers/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ConvertixApp(hasSeenOnboarding: true),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the app loads with the title
    expect(find.text('Convertix'), findsOneWidget);
  });
}