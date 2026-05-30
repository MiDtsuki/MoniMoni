import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/observability/crash_reporter.dart';
import 'core/providers/session_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  await guestSession.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await crashReporter.initialize();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashReporter.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(
      crashReporter.recordError(
        error,
        stackTrace,
        fatal: true,
        reason: 'platform_dispatcher',
      ),
    );
    return true;
  };

  await runZonedGuarded(
    () async {
      runApp(const ProviderScope(child: MoniApp()));
    },
    (error, stackTrace) {
      unawaited(
        crashReporter.recordError(
          error,
          stackTrace,
          fatal: true,
          reason: 'run_zoned_guarded',
        ),
      );
    },
  );
}
