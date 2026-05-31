import 'package:flutter/material.dart';

import 'crash_reporter_native.dart'
    if (dart.library.js_interop) 'crash_reporter_web.dart';

abstract class CrashReporter {
  bool get isSupported;

  Future<void> initialize();

  void recordFlutterFatalError(FlutterErrorDetails details);

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  });

  Future<void> log(String message);
}

final CrashReporter crashReporter = createCrashReporter();
