enum TrialType {
  go,
  noGo,
  distractor,
  ruleSwitch,
  sequence,
}

enum ResponseType {
  goCorrect,
  goMiss,
  noGoCorrectStop,
  noGoFalseAlarm,
  premature,
  wrongTarget,
}

enum PulseStepState {
  readyCue,
  flash,
  responseCentral,
  responseRing,
  finished,
}

enum RuleMode {
  standard,
  inverted,
  sequence2Step,
}

enum DifficultyLevel {
  simple,
  moderate,
  harder,
}

class StimulusItem {
  final String path;
  final String label;
  final String? shape;

  const StimulusItem({
    required this.path,
    required this.label,
    this.shape,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'label': label,
        'shape': shape,
      };

  factory StimulusItem.fromJson(Map<String, dynamic> json) => StimulusItem(
        path: json['path'] as String? ?? '',
        label: json['label'] as String? ?? '',
        shape: json['shape'] as String?,
      );
}

class StimulusPair {
  final String id;
  final StimulusItem imageA;
  final StimulusItem imageB;

  const StimulusPair({
    required this.id,
    required this.imageA,
    required this.imageB,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageA': imageA.toJson(),
        'imageB': imageB.toJson(),
      };
}

class TapEvent {
  final String tapId;
  final int timestamp; // Epoch MS
  final double tapX;
  final double tapY;
  final double targetX;
  final double targetY;
  final double targetSizeDp;
  final double missDistancePx;
  final bool isWrongTap;
  final bool isCorrectionTap;
  final int correctionTimeMs;
  final int interTapIntervalMs;
  final String targetIdentifier;

  TapEvent({
    required this.tapId,
    required this.timestamp,
    required this.tapX,
    required this.tapY,
    required this.targetX,
    required this.targetY,
    required this.targetSizeDp,
    required this.missDistancePx,
    required this.isWrongTap,
    required this.isCorrectionTap,
    required this.correctionTimeMs,
    required this.interTapIntervalMs,
    required this.targetIdentifier,
  });

  Map<String, dynamic> toJson() => {
        'tapId': tapId,
        'timestamp': timestamp,
        'tapX': tapX,
        'tapY': tapY,
        'targetX': targetX,
        'targetY': targetY,
        'targetSizeDp': targetSizeDp,
        'missDistancePx': missDistancePx,
        'isWrongTap': isWrongTap,
        'isCorrectionTap': isCorrectionTap,
        'correctionTimeMs': correctionTimeMs,
        'interTapIntervalMs': interTapIntervalMs,
        'targetIdentifier': targetIdentifier,
      };
}

class DifficultyParams {
  final int tierMs;
  final int isiMs;
  final double targetSizeDp;
  final int ringPositionDeg;
  final String? ruleName;
  final bool isDistractorPresent;

  DifficultyParams({
    required this.tierMs,
    required this.isiMs,
    required this.targetSizeDp,
    required this.ringPositionDeg,
    this.ruleName,
    this.isDistractorPresent = false,
  });

  Map<String, dynamic> toJson() => {
        'tierMs': tierMs,
        'isiMs': isiMs,
        'targetSizeDp': targetSizeDp,
        'ringPositionDeg': ringPositionDeg,
        'ruleName': ruleName,
        'isDistractorPresent': isDistractorPresent,
      };
}

class RawTrialEvent {
  final String sessionId;
  final String eventId;
  final int trialIndex;
  final String utcTimestamp;
  final int stimulusTimestamp;
  final int responseTimestamp;
  final int reactionTimeMs;
  final bool isCorrect;
  final ResponseType responseType;
  final bool timeoutOmission;
  final bool prematureResponse;
  final List<TapEvent> taps;
  final TrialType trialType;
  final DifficultyParams difficultyParams;
  final int sessionElapsedTimeMs;
  final List<String>? expectedSequence;
  final List<String>? actualSequence;
  final String? previousRule;
  final String? currentRule;
  final bool isPostRuleChangeTrial;

  RawTrialEvent({
    required this.sessionId,
    required this.eventId,
    required this.trialIndex,
    required this.utcTimestamp,
    required this.stimulusTimestamp,
    required this.responseTimestamp,
    required this.reactionTimeMs,
    required this.isCorrect,
    required this.responseType,
    required this.timeoutOmission,
    required this.prematureResponse,
    required this.taps,
    required this.trialType,
    required this.difficultyParams,
    required this.sessionElapsedTimeMs,
    this.expectedSequence,
    this.actualSequence,
    this.previousRule,
    this.currentRule,
    this.isPostRuleChangeTrial = false,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'eventId': eventId,
        'trialIndex': trialIndex,
        'utcTimestamp': utcTimestamp,
        'stimulusTimestamp': stimulusTimestamp,
        'responseTimestamp': responseTimestamp,
        'reactionTimeMs': reactionTimeMs,
        'isCorrect': isCorrect,
        'responseType': responseType.name,
        'timeoutOmission': timeoutOmission,
        'prematureResponse': prematureResponse,
        'taps': taps.map((t) => t.toJson()).toList(),
        'trialType': trialType.name,
        'difficultyParams': difficultyParams.toJson(),
        'sessionElapsedTimeMs': sessionElapsedTimeMs,
        'expectedSequence': expectedSequence,
        'actualSequence': actualSequence,
        'previousRule': previousRule,
        'currentRule': currentRule,
        'isPostRuleChangeTrial': isPostRuleChangeTrial,
      };
}

class SessionMetadata {
  final String deviceModel;
  final String os;
  final String osVersion;
  final String appVersion;
  final int screenWidthDp;
  final int screenHeightDp;
  final double devicePixelRatio;
  final String timezone;
  final String gameVersion;
  final String sessionStartUtc;
  final String sessionEndUtc;
  final int interruptionsCount;
  final int resumeEventsCount;

  SessionMetadata({
    required this.deviceModel,
    required this.os,
    required this.osVersion,
    required this.appVersion,
    required this.screenWidthDp,
    required this.screenHeightDp,
    required this.devicePixelRatio,
    required this.timezone,
    required this.gameVersion,
    required this.sessionStartUtc,
    required this.sessionEndUtc,
    required this.interruptionsCount,
    required this.resumeEventsCount,
  });

  Map<String, dynamic> toJson() => {
        'deviceModel': deviceModel,
        'os': os,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'screenWidthDp': screenWidthDp,
        'screenHeightDp': screenHeightDp,
        'devicePixelRatio': devicePixelRatio,
        'timezone': timezone,
        'gameVersion': gameVersion,
        'sessionStartUtc': sessionStartUtc,
        'sessionEndUtc': sessionEndUtc,
        'interruptionsCount': interruptionsCount,
        'resumeEventsCount': resumeEventsCount,
      };
}

class PulseTrainerSessionData {
  final String sessionId;
  final String userId;
  final SessionMetadata metadata;
  final String pairId;
  final List<RawTrialEvent> trials;
  final int thresholdMs;
  final bool researchConsentGiven;
  final DifficultyLevel difficultyLevel;

  PulseTrainerSessionData({
    required this.sessionId,
    required this.userId,
    required this.metadata,
    required this.pairId,
    required this.trials,
    required this.thresholdMs,
    required this.researchConsentGiven,
    this.difficultyLevel = DifficultyLevel.moderate,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'userId': userId,
        'metadata': metadata.toJson(),
        'pairId': pairId,
        'trials': trials.map((t) => t.toJson()).toList(),
        'thresholdMs': thresholdMs,
        'researchConsentGiven': researchConsentGiven,
        'difficultyLevel': difficultyLevel.name,
      };
}

class TrialConfig {
  final int trialIndex;
  final TrialType trialType;
  final DifficultyParams difficultyParams;
  final StimulusItem targetCentralItem;
  final int targetRingIndex;
  final int targetRingDeg;
  final bool isNoGo;
  final bool isDistractorPresent;
  final int? distractorRingIndex;
  final RuleMode ruleName;
  final RuleMode? previousRuleName;
  final List<String> expectedSequence;

  TrialConfig({
    required this.trialIndex,
    required this.trialType,
    required this.difficultyParams,
    required this.targetCentralItem,
    required this.targetRingIndex,
    required this.targetRingDeg,
    required this.isNoGo,
    required this.isDistractorPresent,
    this.distractorRingIndex,
    required this.ruleName,
    this.previousRuleName,
    required this.expectedSequence,
  });
}
