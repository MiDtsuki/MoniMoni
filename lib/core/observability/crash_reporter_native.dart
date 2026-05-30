import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

class NativeCrashReporter implements CrashReporter {
  static const _supportedPlatforms = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.iOS,
  };

  @override
  bool get isSupported => _supportedPlatforms.contains(defaultTargetPlatform);

  @override
  Future<void> initialize() async {
    if (!isSupported) {
      return;
    }

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    await FirebaseCrashlytics.instance.setCustomKey(
      'target_platform',
      defaultTargetPlatform.name,
    );
    await FirebaseCrashlytics.instance.log('Crashlytics initialized');
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {
    if (!isSupported) {
      debugPrint('CrashReporter unsupported platform: ${details.exception}');
      return;
    }

    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    if (!isSupported) {
      debugPrint('CrashReporter unsupported platform: $error');
      return;
    }

    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: fatal,
      reason: reason,
    );
  }

  @override
  Future<void> log(String message) async {
    if (!isSupported) {
      debugPrint(message);
      return;
    }

    await FirebaseCrashlytics.instance.log(message);
  }
}

CrashReporter createCrashReporter() => NativeCrashReporter();
