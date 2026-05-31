import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moni/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('login page renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('forgot password dialog opens and pre-fills email', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'user@example.com',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    final dialogEmailField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextFormField, 'user@example.com'),
    );
    expect(dialogEmailField, findsOneWidget);
    expect(find.text('Send email'), findsOneWidget);
  });
}
