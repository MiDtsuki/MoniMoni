import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moni/app/app.dart';

void main() {
  testWidgets('Moni opens on login and enters the demo app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoniApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
  });
}
