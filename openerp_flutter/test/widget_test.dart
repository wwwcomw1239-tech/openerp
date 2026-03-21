// OpenERP Flutter Widget Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openerp_flutter/main.dart';

void main() {
  testWidgets('OpenERP App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: OpenERPApp(),
      ),
    );

    // Allow async operations to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify the app shows the login screen or splash screen
    // The app should render without errors
    expect(find.byType(OpenERPApp), findsOneWidget);
  });
}
