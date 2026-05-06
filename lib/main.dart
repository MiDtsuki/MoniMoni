import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uknaclwdyyfqwohzvica.supabase.co',
    anonKey: 'sb_publishable_SbGtVvVExSOEkNBp9r7fIg_oxATBmyn',
  );

  runApp(const ProviderScope(child: MoniApp()));
}
