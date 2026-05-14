import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/providers/session_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  await guestSession.load();

  await Supabase.initialize(
    url: 'https://uknaclwdyyfqwohzvica.supabase.co',
    anonKey: 'sb_publishable_SbGtVvVExSOEkNBp9r7fIg_oxATBmyn',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const ProviderScope(child: MoniApp()));
}
