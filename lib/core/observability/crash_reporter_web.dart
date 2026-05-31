import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'crash_reporter.dart';

class WebCrashReporter implements CrashReporter {
  @override
  bool get isSupported => false;

  @override
  Future<void> initialize() async {
    debugPrint(
      'Crashlytics is not available on Flutter web. '
      'Web errors stay local unless a separate web-capable reporter is added.',
    );
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {
    debugPrint(
      'Web crash reporter captured framework error: ${details.exception}',
    );
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    debugPrint(
      'Web crash reporter captured ${fatal ? 'fatal' : 'non-fatal'} error'
      '${reason == null ? '' : ' ($reason)'}: $error\n$stackTrace',
    );
  }

  @override
  Future<void> log(String message) async {
    debugPrint(message);
  }
}

CrashReporter createCrashReporter() => WebCrashReporter();
