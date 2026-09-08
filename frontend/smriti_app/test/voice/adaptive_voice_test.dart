import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/voice/intent_engine.dart';
import 'package:smriti_app/features/voice/stt_service.dart';
import 'package:smriti_app/features/voice/tts_service.dart';
import 'package:smriti_app/features/voice/voice_controller.dart';

void main() {
  group('Adaptive Voice Engine Tests', () {
    test('AdaptiveSttAdapter delegates to system STT when whisper fails initialization', () async {
      final mockWhisper = MockSttAdapter(mockPermissionGranted: false);
      final mockSystem = MockSttAdapter(mockPermissionGranted: true);

      final adaptive = AdaptiveSttAdapter(
        customWhisper: mockWhisper,
        customSystem: mockSystem,
      );

      final ok = await adaptive.initialize();
      expect(ok, isTrue);
      expect(adaptive.activeAdapter, equals(mockSystem));
    });

    test('AdaptiveSttAdapter delegates to Whisper STT when whisper succeeds initialization', () async {
      final mockWhisper = MockSttAdapter(mockPermissionGranted: true);
      final mockSystem = MockSttAdapter(mockPermissionGranted: false);

      final adaptive = AdaptiveSttAdapter(
        customWhisper: mockWhisper,
        customSystem: mockSystem,
      );

      final ok = await adaptive.initialize();
      expect(ok, isTrue);
      expect(adaptive.activeAdapter, equals(mockWhisper));
    });

    test('VoiceController.processTranscript triggers intent recognition directly', () async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();

      bool gameStarted = false;
      final controller = VoiceController(
        stt: mockStt,
        tts: mockTts,
        engine: engine,
        onStartGame: () {
          gameStarted = true;
        },
      );

      await controller.initialize();
      await controller.processTranscript('start memory game');

      expect(gameStarted, isTrue);
      expect(controller.state, equals(VoiceControllerState.idle));
      expect(mockTts.speakCallCount, equals(1));
    });

    test('VoiceController.processTranscript handles quick chips and manual text input', () async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();

      bool caregiverCalled = false;
      final controller = VoiceController(
        stt: mockStt,
        tts: mockTts,
        engine: engine,
        onCallCaregiver: () {
          caregiverCalled = true;
        },
      );

      await controller.initialize();
      await controller.processTranscript('call caregiver');

      expect(caregiverCalled, isTrue);
    });

    test('AdaptiveTtsAdapter initializes and speaks without throwing', () async {
      final mockTts = MockTtsAdapter();
      final adaptive = AdaptiveTtsAdapter(active: mockTts);

      await adaptive.initialize();
      expect(adaptive.status, equals(TtsStatus.ready));

      bool done = false;
      await adaptive.speak(
        text: 'Hello test',
        languageCode: 'en',
        onDone: () => done = true,
      );

      expect(done, isTrue);
      expect(mockTts.speakCallCount, equals(1));
    });
  });
}
