import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moni/app/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemoryAsyncStorage(),
      ),
    );
  });

  testWidgets('Moni opens on login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoniApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('Forgot password opens reset dialog', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoniApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Forgot password dialog pre-fills email field', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoniApp()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email').first,
      'user@example.com',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    final dialogEmailField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextFormField, 'user@example.com'),
    );
    expect(dialogEmailField, findsOneWidget);
  });

  testWidgets('Forgot password dialog dismisses on cancel', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoniApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsNothing);
  });
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  _MemoryAsyncStorage();

  final _values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }
}
