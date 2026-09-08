import '../models/pulse_trainer_models.dart';

class StimulusPairManager {
  static int _sessionCounter = 0;
  final List<StimulusPair> _pairs;

  StimulusPairManager([List<StimulusPair>? customPairs])
      : _pairs = customPairs ?? defaultPairs;

  static const List<StimulusPair> defaultPairs = [
    StimulusPair(
      id: 'circle-square',
      imageA: StimulusItem(
        path: 'assets/pairs/circle.png',
        label: 'Circle',
        shape: 'circle',
      ),
      imageB: StimulusItem(
        path: 'assets/pairs/square.png',
        label: 'Square',
        shape: 'square',
      ),
    ),
    StimulusPair(
      id: 'tiger-rasmalai',
      imageA: StimulusItem(
        path: 'assets/pairs/tiger.png',
        label: 'Tiger',
      ),
      imageB: StimulusItem(
        path: 'assets/pairs/rasmalai.png',
        label: 'Rasmalai',
      ),
    ),
    StimulusPair(
      id: 'star-triangle',
      imageA: StimulusItem(
        path: 'assets/pairs/star.png',
        label: 'Star',
        shape: 'star',
      ),
      imageB: StimulusItem(
        path: 'assets/pairs/triangle.png',
        label: 'Triangle',
        shape: 'triangle',
      ),
    ),
  ];

  StimulusPair getNextSessionPair() {
    if (_pairs.isEmpty) {
      throw Exception('No stimulus pairs available in configuration.');
    }
    final index = _sessionCounter % _pairs.length;
    _sessionCounter += 1;
    return _pairs[index];
  }

  StimulusPair? getPairById(String id) {
    try {
      return _pairs.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
