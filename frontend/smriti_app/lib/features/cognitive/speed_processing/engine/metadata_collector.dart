import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import '../models/pulse_trainer_models.dart';

class MetadataCollector {
  int interruptionsCount = 0;
  int resumeEventsCount = 0;
  final String sessionStartUtc;

  MetadataCollector() : sessionStartUtc = DateTime.now().toUtc().toIso8601String();

  void recordInterruption() {
    interruptionsCount += 1;
  }

  void recordResume() {
    resumeEventsCount += 1;
  }

  SessionMetadata collectMetadata(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final pixelRatio = mediaQuery.devicePixelRatio;

    String osName = 'unknown';
    try {
      if (Platform.isAndroid) osName = 'android';
      if (Platform.isIOS) osName = 'ios';
      if (Platform.isWindows) osName = 'windows';
      if (Platform.isMacOS) osName = 'macos';
      if (Platform.isLinux) osName = 'linux';
    } catch (_) {
      osName = 'web';
    }

    return SessionMetadata(
      deviceModel: 'Mobile Target Device ($osName)',
      os: osName,
      osVersion: '1.0.0',
      appVersion: '1.0.0',
      screenWidthDp: size.width.round(),
      screenHeightDp: size.height.round(),
      devicePixelRatio: pixelRatio,
      timezone: DateTime.now().timeZoneName,
      gameVersion: 'PulseTrainer_v2.0_Research',
      sessionStartUtc: sessionStartUtc,
      sessionEndUtc: DateTime.now().toUtc().toIso8601String(),
      interruptionsCount: interruptionsCount,
      resumeEventsCount: resumeEventsCount,
    );
  }
}
