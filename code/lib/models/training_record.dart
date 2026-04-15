import '../utils/uid_generator.dart';

// ---------------------------------------------------------------------------
// SetValues – raw recorded values for a single set
// ---------------------------------------------------------------------------

class SetValues {
  final List<double?>? loadValue;
  final String? loadUnit;
  final String? loadText;
  final List<double?>? rep;
  final List<double?>? duration;
  final String? durationUnit;
  final List<double?>? distance;
  final String? distanceUnit;
  final String? note;

  const SetValues({
    this.loadValue,
    this.loadUnit,
    this.loadText,
    this.rep,
    this.duration,
    this.durationUnit,
    this.distance,
    this.distanceUnit,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'loadValue': loadValue,
        'loadUnit': loadUnit,
        'loadText': loadText,
        'rep': rep,
        'duration': duration,
        'durationUnit': durationUnit,
        'distance': distance,
        'distanceUnit': distanceUnit,
        'note': note,
      };

  factory SetValues.fromJson(Map<String, dynamic> json) => SetValues(
        loadValue: _parseDoubleList(json['loadValue']),
        loadUnit: json['loadUnit'] as String?,
        loadText: json['loadText'] as String?,
        rep: _parseDoubleList(json['rep']),
        duration: _parseDoubleList(json['duration']),
        durationUnit: json['durationUnit'] as String?,
        distance: _parseDoubleList(json['distance']),
        distanceUnit: json['distanceUnit'] as String?,
        note: json['note'] as String?,
      );

  SetValues copyWith({
    List<double?>? loadValue,
    String? loadUnit,
    String? loadText,
    List<double?>? rep,
    List<double?>? duration,
    String? durationUnit,
    List<double?>? distance,
    String? distanceUnit,
    String? note,
  }) =>
      SetValues(
        loadValue: loadValue ?? this.loadValue,
        loadUnit: loadUnit ?? this.loadUnit,
        loadText: loadText ?? this.loadText,
        rep: rep ?? this.rep,
        duration: duration ?? this.duration,
        durationUnit: durationUnit ?? this.durationUnit,
        distance: distance ?? this.distance,
        distanceUnit: distanceUnit ?? this.distanceUnit,
        note: note ?? this.note,
      );
}

// ---------------------------------------------------------------------------
// EffortMetrics
// ---------------------------------------------------------------------------

class EffortMetrics {
  final List<double?>? rpe;

  const EffortMetrics({this.rpe});

  Map<String, dynamic> toJson() => {'rpe': rpe};

  factory EffortMetrics.fromJson(Map<String, dynamic> json) =>
      EffortMetrics(rpe: _parseDoubleList(json['rpe']));

  EffortMetrics copyWith({List<double?>? rpe}) =>
      EffortMetrics(rpe: rpe ?? this.rpe);
}

// ---------------------------------------------------------------------------
// TrainingSet
// ---------------------------------------------------------------------------

class TrainingSet {
  final String uid;
  final String state;
  final String sourceType;
  final bool workingPlanEditedDuringSession;
  final String? startedAt;
  final String? finishedAt;
  final SetValues? baselinePlan;
  final SetValues? workingPlan;
  final SetValues? actual;
  final EffortMetrics? effortMetrics;

  TrainingSet({
    String? uid,
    this.state = 'planning',
    this.sourceType = 'planned',
    this.workingPlanEditedDuringSession = false,
    this.startedAt,
    this.finishedAt,
    this.baselinePlan,
    this.workingPlan,
    this.actual,
    this.effortMetrics,
  }) : uid = uid ?? UidGenerator.generate();

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'state': state,
        'sourceType': sourceType,
        'workingPlanEditedDuringSession': workingPlanEditedDuringSession,
        'startedAt': startedAt,
        'finishedAt': finishedAt,
        'baselinePlan': baselinePlan?.toJson(),
        'workingPlan': workingPlan?.toJson(),
        'actual': actual?.toJson(),
        'effortMetrics': effortMetrics?.toJson(),
      };

  factory TrainingSet.fromJson(Map<String, dynamic> json) => TrainingSet(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        state: json['state'] as String? ?? 'planning',
        sourceType: json['sourceType'] as String? ?? 'planned',
        workingPlanEditedDuringSession:
            json['workingPlanEditedDuringSession'] as bool? ?? false,
        startedAt: json['startedAt'] as String?,
        finishedAt: json['finishedAt'] as String?,
        baselinePlan: json['baselinePlan'] != null
            ? SetValues.fromJson(
                json['baselinePlan'] as Map<String, dynamic>)
            : null,
        workingPlan: json['workingPlan'] != null
            ? SetValues.fromJson(
                json['workingPlan'] as Map<String, dynamic>)
            : null,
        actual: json['actual'] != null
            ? SetValues.fromJson(json['actual'] as Map<String, dynamic>)
            : null,
        effortMetrics: json['effortMetrics'] != null
            ? EffortMetrics.fromJson(
                json['effortMetrics'] as Map<String, dynamic>)
            : null,
      );

  TrainingSet copyWith({
    String? uid,
    String? state,
    String? sourceType,
    bool? workingPlanEditedDuringSession,
    String? startedAt,
    String? finishedAt,
    SetValues? baselinePlan,
    SetValues? workingPlan,
    SetValues? actual,
    EffortMetrics? effortMetrics,
  }) =>
      TrainingSet(
        uid: uid ?? this.uid,
        state: state ?? this.state,
        sourceType: sourceType ?? this.sourceType,
        workingPlanEditedDuringSession: workingPlanEditedDuringSession ??
            this.workingPlanEditedDuringSession,
        startedAt: startedAt ?? this.startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        baselinePlan: baselinePlan ?? this.baselinePlan,
        workingPlan: workingPlan ?? this.workingPlan,
        actual: actual ?? this.actual,
        effortMetrics: effortMetrics ?? this.effortMetrics,
      );
}

// ---------------------------------------------------------------------------
// ExerciseBlock
// ---------------------------------------------------------------------------

class ExerciseBlock {
  final String uid;
  final String name;
  final String exerciseCategory;
  final String sourceType;
  final List<String> displayColumns;
  final String? note;
  final List<TrainingSet> sets;

  ExerciseBlock({
    String? uid,
    required this.name,
    this.exerciseCategory = '辅助项',
    this.sourceType = 'planned',
    List<String>? displayColumns,
    this.note,
    List<TrainingSet>? sets,
  })  : uid = uid ?? UidGenerator.generate(),
        displayColumns = displayColumns ?? const ['load', 'rep'],
        sets = sets ?? const [];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'exerciseCategory': exerciseCategory,
        'sourceType': sourceType,
        'displayColumns': displayColumns,
        'note': note,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory ExerciseBlock.fromJson(Map<String, dynamic> json) => ExerciseBlock(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        name: json['name'] as String? ?? '',
        exerciseCategory: json['exerciseCategory'] as String? ?? '辅助项',
        sourceType: json['sourceType'] as String? ?? 'planned',
        displayColumns: (json['displayColumns'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const ['load', 'rep'],
        note: json['note'] as String?,
        sets: (json['sets'] as List<dynamic>?)
                ?.map(
                    (e) => TrainingSet.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  ExerciseBlock copyWith({
    String? uid,
    String? name,
    String? exerciseCategory,
    String? sourceType,
    List<String>? displayColumns,
    String? note,
    List<TrainingSet>? sets,
  }) =>
      ExerciseBlock(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        exerciseCategory: exerciseCategory ?? this.exerciseCategory,
        sourceType: sourceType ?? this.sourceType,
        displayColumns: displayColumns ?? this.displayColumns,
        note: note ?? this.note,
        sets: sets ?? this.sets,
      );
}

// ---------------------------------------------------------------------------
// PauseEvent
// ---------------------------------------------------------------------------

class PauseEvent {
  final String uid;
  final String pauseType;
  final String startedAt;
  final String? finishedAt;
  final String? description;

  PauseEvent({
    String? uid,
    this.pauseType = 'manual_pause',
    String? startedAt,
    this.finishedAt,
    this.description,
  })  : uid = uid ?? UidGenerator.generate(),
        startedAt = startedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'pauseType': pauseType,
        'startedAt': startedAt,
        'finishedAt': finishedAt,
        'description': description,
      };

  factory PauseEvent.fromJson(Map<String, dynamic> json) => PauseEvent(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        pauseType: json['pauseType'] as String? ?? 'manual_pause',
        startedAt: json['startedAt'] as String?,
        finishedAt: json['finishedAt'] as String?,
        description: json['description'] as String?,
      );

  PauseEvent copyWith({
    String? uid,
    String? pauseType,
    String? startedAt,
    String? finishedAt,
    String? description,
  }) =>
      PauseEvent(
        uid: uid ?? this.uid,
        pauseType: pauseType ?? this.pauseType,
        startedAt: startedAt ?? this.startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        description: description ?? this.description,
      );
}

// ---------------------------------------------------------------------------
// TrainingRecord
// ---------------------------------------------------------------------------

class TrainingRecord {
  final String uid;
  final String date;
  final String state;
  final String? endedReason;
  final String? dayLabel;
  final int weekIndex;
  final String daySlotType;
  final int daySlotIndex;
  final String daySlotLabel;
  final String? sourcePlanDayUid;
  final String? startedAt;
  final String? finishedAt;
  final List<ExerciseBlock> exerciseBlocks;
  final List<PauseEvent> pauseEvents;

  TrainingRecord({
    String? uid,
    String? date,
    this.state = 'in_progress',
    this.endedReason,
    this.dayLabel,
    this.weekIndex = 0,
    this.daySlotType = 'planned_day',
    this.daySlotIndex = 0,
    this.daySlotLabel = 'D1',
    this.sourcePlanDayUid,
    this.startedAt,
    this.finishedAt,
    List<ExerciseBlock>? exerciseBlocks,
    List<PauseEvent>? pauseEvents,
  })  : uid = uid ?? UidGenerator.generate(),
        date = date ?? DateTime.now().toIso8601String().substring(0, 10),
        exerciseBlocks = exerciseBlocks ?? const [],
        pauseEvents = pauseEvents ?? const [];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'date': date,
        'state': state,
        'endedReason': endedReason,
        'dayLabel': dayLabel,
        'weekIndex': weekIndex,
        'daySlotType': daySlotType,
        'daySlotIndex': daySlotIndex,
        'daySlotLabel': daySlotLabel,
        'sourcePlanDayUid': sourcePlanDayUid,
        'startedAt': startedAt,
        'finishedAt': finishedAt,
        'exerciseBlocks':
            exerciseBlocks.map((b) => b.toJson()).toList(),
        'pauseEvents': pauseEvents.map((p) => p.toJson()).toList(),
      };

  factory TrainingRecord.fromJson(Map<String, dynamic> json) =>
      TrainingRecord(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        date: json['date'] as String?,
        state: json['state'] as String? ?? 'in_progress',
        endedReason: json['endedReason'] as String?,
        dayLabel: json['dayLabel'] as String?,
        weekIndex: json['weekIndex'] as int? ?? 0,
        daySlotType: json['daySlotType'] as String? ?? 'planned_day',
        daySlotIndex: json['daySlotIndex'] as int? ?? 0,
        daySlotLabel: json['daySlotLabel'] as String? ?? 'D1',
        sourcePlanDayUid: json['sourcePlanDayUid'] as String?,
        startedAt: json['startedAt'] as String?,
        finishedAt: json['finishedAt'] as String?,
        exerciseBlocks: (json['exerciseBlocks'] as List<dynamic>?)
                ?.map((e) =>
                    ExerciseBlock.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        pauseEvents: (json['pauseEvents'] as List<dynamic>?)
                ?.map(
                    (e) => PauseEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  TrainingRecord copyWith({
    String? uid,
    String? date,
    String? state,
    String? endedReason,
    String? dayLabel,
    int? weekIndex,
    String? daySlotType,
    int? daySlotIndex,
    String? daySlotLabel,
    String? sourcePlanDayUid,
    String? startedAt,
    String? finishedAt,
    List<ExerciseBlock>? exerciseBlocks,
    List<PauseEvent>? pauseEvents,
  }) =>
      TrainingRecord(
        uid: uid ?? this.uid,
        date: date ?? this.date,
        state: state ?? this.state,
        endedReason: endedReason ?? this.endedReason,
        dayLabel: dayLabel ?? this.dayLabel,
        weekIndex: weekIndex ?? this.weekIndex,
        daySlotType: daySlotType ?? this.daySlotType,
        daySlotIndex: daySlotIndex ?? this.daySlotIndex,
        daySlotLabel: daySlotLabel ?? this.daySlotLabel,
        sourcePlanDayUid: sourcePlanDayUid ?? this.sourcePlanDayUid,
        startedAt: startedAt ?? this.startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        exerciseBlocks: exerciseBlocks ?? this.exerciseBlocks,
        pauseEvents: pauseEvents ?? this.pauseEvents,
      );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<double?>? _parseDoubleList(dynamic raw) {
  if (raw == null) return null;
  return (raw as List<dynamic>)
      .map((e) => e == null ? null : (e as num).toDouble())
      .toList();
}
