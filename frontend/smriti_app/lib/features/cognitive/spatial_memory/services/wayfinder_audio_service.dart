import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum SoundscapeType {
  silent,
  alphaBinaural, // 10Hz Alpha brainwave focus tone (200Hz + 210Hz)
  calmHarmonies, // Soft warm ambient chord drone
  oceanWaves,    // Synthesized ocean wave swell
  gentleRain,    // Soft rain noise soundscape
}

/// Offline PCM Soundscape Synthesizer and Haptic Feedback Manager.
class WayfinderAudioService {
  static final WayfinderAudioService _instance = WayfinderAudioService._internal();
  factory WayfinderAudioService() => _instance;
  WayfinderAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  SoundscapeType _currentSoundscape = SoundscapeType.alphaBinaural;
  double _volume = 0.6; // 0.0 to 1.0
  bool _hapticsEnabled = true;
  bool _isPlaying = false;

  SoundscapeType get currentSoundscape => _currentSoundscape;
  double get volume => _volume;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get isPlaying => _isPlaying;

  /// Initializes audio player loop settings and starts soundscape
  Future<void> initAndPlay({SoundscapeType? initialType}) async {
    if (initialType != null) {
      _currentSoundscape = initialType;
    }
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_volume);
    await playSoundscape(_currentSoundscape);
  }

  /// Synthesizes PCM wave bytes and plays soundscape offline
  Future<void> playSoundscape(SoundscapeType type) async {
    _currentSoundscape = type;
    if (type == SoundscapeType.silent) {
      await _player.stop();
      _isPlaying = false;
      return;
    }

    try {
      final wavBytes = _generateWavBuffer(type);
      await _player.setVolume(_volume);
      await _player.play(BytesSource(wavBytes));
      _isPlaying = true;
    } catch (e) {
      // Audio playback fallback
    }
  }

  /// Sets audio volume level (0.0 to 1.0) smoothly
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
  }

  /// Sets haptics enabled status
  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  /// Changes current soundscape
  Future<void> setSoundscape(SoundscapeType type) async {
    await playSoundscape(type);
  }

  /// Stops audio playback when leaving game
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  /// Triggers subtle haptic feedback for landmark tap
  Future<void> triggerTapHaptic({bool isCorrect = true}) async {
    if (!_hapticsEnabled) return;
    try {
      if (isCorrect) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Haptics fallback
    }
  }

  /// Triggers feedback on target node arrival
  Future<void> triggerTargetReachedHaptic() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Fallback
    }
  }

  /// Returns user-friendly description of soundscape
  String getSoundscapeLabel(SoundscapeType type) {
    switch (type) {
      case SoundscapeType.silent:
        return 'Silent (Off)';
      case SoundscapeType.alphaBinaural:
        return 'Alpha Waves (10Hz Focus)';
      case SoundscapeType.calmHarmonies:
        return 'Calm Harmonies';
      case SoundscapeType.oceanWaves:
        return 'Ocean Waves';
      case SoundscapeType.gentleRain:
        return 'Gentle Rain';
    }
  }

  /// Pure Dart 16-bit 22.05kHz PCM WAV audio buffer synthesizer
  Uint8List _generateWavBuffer(SoundscapeType type) {
    const sampleRate = 22050;
    const numChannels = 2; // Stereo
    const durationSec = 4; // 4 second loopable soundscape buffer
    const numSamples = sampleRate * durationSec;
    final dataSize = numSamples * numChannels * 2;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF Header
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57); // W
    buffer.setUint8(9, 0x41); // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt chunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6d); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, numChannels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * numChannels * 2, Endian.little);
    buffer.setUint16(32, numChannels * 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little); // 16 bit

    // data chunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataSize, Endian.little);

    final rand = Random();
    int offset = 44;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      double sampleL = 0.0;
      double sampleR = 0.0;

      switch (type) {
        case SoundscapeType.alphaBinaural:
          // 200Hz Left, 210Hz Right -> 10Hz Alpha Brainwave Entrainment
          sampleL = sin(2 * pi * 200 * t) * 0.45;
          sampleR = sin(2 * pi * 210 * t) * 0.45;
          break;

        case SoundscapeType.calmHarmonies:
          // Ambient warm chord drone (220Hz, 277Hz, 329Hz)
          sampleL = (sin(2 * pi * 220 * t) + sin(2 * pi * 277.18 * t) + sin(2 * pi * 329.63 * t)) * 0.18;
          sampleR = (sin(2 * pi * 220 * t) + sin(2 * pi * 329.63 * t) + sin(2 * pi * 440 * t)) * 0.18;
          break;

        case SoundscapeType.oceanWaves:
          // Modulated ocean swell
          final swell = (sin(2 * pi * 0.25 * t) + 1.0) / 2.0;
          final noiseL = (rand.nextDouble() * 2 - 1) * 0.25 * swell;
          final noiseR = (rand.nextDouble() * 2 - 1) * 0.25 * swell;
          sampleL = noiseL + sin(2 * pi * 100 * t) * 0.18 * swell;
          sampleR = noiseR + sin(2 * pi * 100 * t) * 0.18 * swell;
          break;

        case SoundscapeType.gentleRain:
          // Soft pink rain noise
          sampleL = (rand.nextDouble() * 2 - 1) * 0.15;
          sampleR = (rand.nextDouble() * 2 - 1) * 0.15;
          break;

        case SoundscapeType.silent:
          sampleL = 0.0;
          sampleR = 0.0;
          break;
      }

      int intValL = (sampleL.clamp(-1.0, 1.0) * 32767).round();
      int intValR = (sampleR.clamp(-1.0, 1.0) * 32767).round();

      buffer.setInt16(offset, intValL, Endian.little);
      buffer.setInt16(offset + 2, intValR, Endian.little);
      offset += 4;
    }

    return buffer.buffer.asUint8List();
  }
}
