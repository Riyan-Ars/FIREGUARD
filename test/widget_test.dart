import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fireguard/app/app.dart';

void main() {
  testWidgets('FireguardApp smoke test - mounts and displays wordmark', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FireguardApp()));

    // Initial pump
    await tester.pump();

    // Verify wordmark is present
    expect(find.text('FIREGUARD'), findsOneWidget);

    // Verify navigation tabs exist
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Air Quality'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
