import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moni/app/app.dart';

void main() {
  testWidgets('Moni opens on the Logs tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoniApp()));
    await tester.pumpAndSettle();

    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
  });
}
