import '../utils/uid_generator.dart';

// ---------------------------------------------------------------------------
// PlanFieldValue – single value, range, or lower-bound for plan targets
// ---------------------------------------------------------------------------

class PlanFieldValue {
  final List<double?>? value;
  final String? unit;
  final String? text;
  final String origin;
  final double? percentRm;
  final String? referenceLiftKey;

  const PlanFieldValue({
    this.value,
    this.unit,
    this.text,
    this.origin = 'empty',
    this.percentRm,
    this.referenceLiftKey,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'unit': unit,
        'text': text,
        'origin': origin,
        'percentRm': percentRm,
        'referenceLiftKey': referenceLiftKey,
      };

  factory PlanFieldValue.fromJson(Map<String, dynamic> json) =>
      PlanFieldValue(
        value: (json['value'] as List<dynamic>?)
            ?.map((e) => e == null ? null : (e as num).toDouble())
            .toList(),
        unit: json['unit'] as String?,
        text: json['text'] as String?,
        origin: json['origin'] as String? ?? 'empty',
        percentRm: (json['percentRm'] as num?)?.toDouble(),
        referenceLiftKey: json['referenceLiftKey'] as String?,
      );

  PlanFieldValue copyWith({
    List<double?>? value,
    String? unit,
    String? text,
    String? origin,
    double? percentRm,
    String? referenceLiftKey,
  }) =>
      PlanFieldValue(
        value: value ?? this.value,
        unit: unit ?? this.unit,
        text: text ?? this.text,
        origin: origin ?? this.origin,
        percentRm: percentRm ?? this.percentRm,
        referenceLiftKey: referenceLiftKey ?? this.referenceLiftKey,
      );

  static const PlanFieldValue empty = PlanFieldValue();
}

// ---------------------------------------------------------------------------
// PlanSetTarget
// ---------------------------------------------------------------------------

class PlanSetTarget {
  final PlanFieldValue load;
  final PlanFieldValue intensity;
  final PlanFieldValue rep;
  final PlanFieldValue rpe;
  final PlanFieldValue duration;
  final PlanFieldValue distance;
  final PlanFieldValue note;

  const PlanSetTarget({
    this.load = PlanFieldValue.empty,
    this.intensity = PlanFieldValue.empty,
    this.rep = PlanFieldValue.empty,
    this.rpe = PlanFieldValue.empty,
    this.duration = PlanFieldValue.empty,
    this.distance = PlanFieldValue.empty,
    this.note = PlanFieldValue.empty,
  });

  Map<String, dynamic> toJson() => {
        'load': load.toJson(),
        'intensity': intensity.toJson(),
        'rep': rep.toJson(),
        'rpe': rpe.toJson(),
        'duration': duration.toJson(),
        'distance': distance.toJson(),
        'note': note.toJson(),
      };

  factory PlanSetTarget.fromJson(Map<String, dynamic> json) => PlanSetTarget(
        load: json['load'] != null
            ? PlanFieldValue.fromJson(json['load'] as Map<String, dynamic>)
            : PlanFieldValue.empty,
        intensity: json['intensity'] != null
            ? PlanFieldValue.fromJson(
                json['intensity'] as Map<String, dynamic>)
            : PlanFieldValue.empty,
        rep: json['rep'] != null
            ? PlanFieldValue.fromJson(json['rep'] as Map<String, dynamic>)
            : PlanFieldValue.empty,
        rpe: json['rpe'] != null
            ? PlanFieldValue.fromJson(json['rpe'] as Map<String, dynamic>)
            : PlanFieldValue.empty,
        duration: json['duration'] != null
            ? PlanFieldValue.fromJson(
                json['duration'] as Map<String, dynamic>)
            : PlanFieldValue.empty,
        distance: json['distance'] != null
            ? PlanFieldValue.fromJson(
                json['distance'] as Map<String, dynamic>)
            : PlanFieldValue.empty,
        note: json['note'] != null
            ? PlanFieldValue.fromJson(json['note'] as Map<String, dynamic>)
            : PlanFieldValue.empty,
      );

  PlanSetTarget copyWith({
    PlanFieldValue? load,
    PlanFieldValue? intensity,
    PlanFieldValue? rep,
    PlanFieldValue? rpe,
    PlanFieldValue? duration,
    PlanFieldValue? distance,
    PlanFieldValue? note,
  }) =>
      PlanSetTarget(
        load: load ?? this.load,
        intensity: intensity ?? this.intensity,
        rep: rep ?? this.rep,
        rpe: rpe ?? this.rpe,
        duration: duration ?? this.duration,
        distance: distance ?? this.distance,
        note: note ?? this.note,
      );
}

// ---------------------------------------------------------------------------
// PlanSet
// ---------------------------------------------------------------------------

class PlanSet {
  final String uid;
  final String exerciseItemUid;
  final int setOrderInItem;
  final List<String> tags;
  final bool isOptional;
  final PlanSetTarget target;

  PlanSet({
    String? uid,
    required this.exerciseItemUid,
    this.setOrderInItem = 0,
    List<String>? tags,
    this.isOptional = false,
    PlanSetTarget? target,
  })  : uid = uid ?? UidGenerator.generate(),
        tags = tags ?? const [],
        target = target ?? const PlanSetTarget();

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'exerciseItemUid': exerciseItemUid,
        'setOrderInItem': setOrderInItem,
        'tags': tags,
        'isOptional': isOptional,
        'target': target.toJson(),
      };

  factory PlanSet.fromJson(Map<String, dynamic> json) => PlanSet(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        exerciseItemUid: json['exerciseItemUid'] as String? ?? '',
        setOrderInItem: json['setOrderInItem'] as int? ?? 0,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        isOptional: json['isOptional'] as bool? ?? false,
        target: json['target'] != null
            ? PlanSetTarget.fromJson(json['target'] as Map<String, dynamic>)
            : const PlanSetTarget(),
      );

  PlanSet copyWith({
    String? uid,
    String? exerciseItemUid,
    int? setOrderInItem,
    List<String>? tags,
    bool? isOptional,
    PlanSetTarget? target,
  }) =>
      PlanSet(
        uid: uid ?? this.uid,
        exerciseItemUid: exerciseItemUid ?? this.exerciseItemUid,
        setOrderInItem: setOrderInItem ?? this.setOrderInItem,
        tags: tags ?? this.tags,
        isOptional: isOptional ?? this.isOptional,
        target: target ?? this.target,
      );
}

// ---------------------------------------------------------------------------
// PlanExerciseItem
// ---------------------------------------------------------------------------

class PlanExerciseItem {
  final String uid;
  final String planDayUid;
  final int orderInDay;
  final String exerciseTypeKey;
  final String? displayNameOverride;
  final String? note;
  final String recordProfileKey;
  final Map<String, bool> fieldVisibility;
  final List<PlanSet> sets;

  PlanExerciseItem({
    String? uid,
    required this.planDayUid,
    this.orderInDay = 0,
    required this.exerciseTypeKey,
    this.displayNameOverride,
    this.note,
    this.recordProfileKey = 'load_reps_profile',
    Map<String, bool>? fieldVisibility,
    List<PlanSet>? sets,
  })  : uid = uid ?? UidGenerator.generate(),
        fieldVisibility = fieldVisibility ??
            const {
              'load': true,
              'intensity': false,
              'rep': true,
              'rpe': false,
              'duration': false,
              'distance': false,
              'note': false,
            },
        sets = sets ?? const [];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'planDayUid': planDayUid,
        'orderInDay': orderInDay,
        'exerciseTypeKey': exerciseTypeKey,
        'displayNameOverride': displayNameOverride,
        'note': note,
        'recordProfileKey': recordProfileKey,
        'fieldVisibility': Map<String, dynamic>.from(fieldVisibility),
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory PlanExerciseItem.fromJson(Map<String, dynamic> json) =>
      PlanExerciseItem(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        planDayUid: json['planDayUid'] as String? ?? '',
        orderInDay: json['orderInDay'] as int? ?? 0,
        exerciseTypeKey: json['exerciseTypeKey'] as String? ?? '',
        displayNameOverride: json['displayNameOverride'] as String?,
        note: json['note'] as String?,
        recordProfileKey:
            json['recordProfileKey'] as String? ?? 'load_reps_profile',
        fieldVisibility:
            (json['fieldVisibility'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, v as bool)) ??
                const {
                  'load': true,
                  'intensity': false,
                  'rep': true,
                  'rpe': false,
                  'duration': false,
                  'distance': false,
                  'note': false,
                },
        sets: (json['sets'] as List<dynamic>?)
                ?.map(
                    (e) => PlanSet.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  PlanExerciseItem copyWith({
    String? uid,
    String? planDayUid,
    int? orderInDay,
    String? exerciseTypeKey,
    String? displayNameOverride,
    String? note,
    String? recordProfileKey,
    Map<String, bool>? fieldVisibility,
    List<PlanSet>? sets,
  }) =>
      PlanExerciseItem(
        uid: uid ?? this.uid,
        planDayUid: planDayUid ?? this.planDayUid,
        orderInDay: orderInDay ?? this.orderInDay,
        exerciseTypeKey: exerciseTypeKey ?? this.exerciseTypeKey,
        displayNameOverride: displayNameOverride ?? this.displayNameOverride,
        note: note ?? this.note,
        recordProfileKey: recordProfileKey ?? this.recordProfileKey,
        fieldVisibility: fieldVisibility ?? this.fieldVisibility,
        sets: sets ?? this.sets,
      );
}

// ---------------------------------------------------------------------------
// PlanDay
// ---------------------------------------------------------------------------

class PlanDay {
  final String uid;
  final String microcycleUid;
  final int dayIndex;
  final String label;
  final String? dayTitle;
  final List<PlanExerciseItem> exerciseItems;
  final String? notes;

  PlanDay({
    String? uid,
    required this.microcycleUid,
    this.dayIndex = 0,
    this.label = 'D1',
    this.dayTitle,
    List<PlanExerciseItem>? exerciseItems,
    this.notes,
  })  : uid = uid ?? UidGenerator.generate(),
        exerciseItems = exerciseItems ?? const [];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'microcycleUid': microcycleUid,
        'dayIndex': dayIndex,
        'label': label,
        'dayTitle': dayTitle,
        'exerciseItems': exerciseItems.map((e) => e.toJson()).toList(),
        'notes': notes,
      };

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        microcycleUid: json['microcycleUid'] as String? ?? '',
        dayIndex: json['dayIndex'] as int? ?? 0,
        label: json['label'] as String? ?? 'D1',
        dayTitle: json['dayTitle'] as String?,
        exerciseItems: (json['exerciseItems'] as List<dynamic>?)
                ?.map((e) =>
                    PlanExerciseItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: json['notes'] as String?,
      );

  PlanDay copyWith({
    String? uid,
    String? microcycleUid,
    int? dayIndex,
    String? label,
    String? dayTitle,
    List<PlanExerciseItem>? exerciseItems,
    String? notes,
  }) =>
      PlanDay(
        uid: uid ?? this.uid,
        microcycleUid: microcycleUid ?? this.microcycleUid,
        dayIndex: dayIndex ?? this.dayIndex,
        label: label ?? this.label,
        dayTitle: dayTitle ?? this.dayTitle,
        exerciseItems: exerciseItems ?? this.exerciseItems,
        notes: notes ?? this.notes,
      );
}

// ---------------------------------------------------------------------------
// PlanMicrocycle
// ---------------------------------------------------------------------------

class PlanMicrocycle {
  final String uid;
  final String mesocycleUid;
  final int weekIndex;
  final String label;
  final String status;
  final List<PlanDay> days;
  final String? notes;

  PlanMicrocycle({
    String? uid,
    required this.mesocycleUid,
    this.weekIndex = 0,
    this.label = 'W1',
    this.status = 'planned',
    List<PlanDay>? days,
    this.notes,
  })  : uid = uid ?? UidGenerator.generate(),
        days = days ?? const [];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'mesocycleUid': mesocycleUid,
        'weekIndex': weekIndex,
        'label': label,
        'status': status,
        'days': days.map((d) => d.toJson()).toList(),
        'notes': notes,
      };

  factory PlanMicrocycle.fromJson(Map<String, dynamic> json) =>
      PlanMicrocycle(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        mesocycleUid: json['mesocycleUid'] as String? ?? '',
        weekIndex: json['weekIndex'] as int? ?? 0,
        label: json['label'] as String? ?? 'W1',
        status: json['status'] as String? ?? 'planned',
        days: (json['days'] as List<dynamic>?)
                ?.map((e) => PlanDay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: json['notes'] as String?,
      );

  PlanMicrocycle copyWith({
    String? uid,
    String? mesocycleUid,
    int? weekIndex,
    String? label,
    String? status,
    List<PlanDay>? days,
    String? notes,
  }) =>
      PlanMicrocycle(
        uid: uid ?? this.uid,
        mesocycleUid: mesocycleUid ?? this.mesocycleUid,
        weekIndex: weekIndex ?? this.weekIndex,
        label: label ?? this.label,
        status: status ?? this.status,
        days: days ?? this.days,
        notes: notes ?? this.notes,
      );
}

// ---------------------------------------------------------------------------
// PlanMesocycle
// ---------------------------------------------------------------------------

class PlanMesocycle {
  final String uid;
  final String name;
  final String status;
  final String? goal;
  final String? startDate;
  final List<PlanMicrocycle> microcycles;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  PlanMesocycle({
    String? uid,
    required this.name,
    this.status = 'draft',
    this.goal,
    this.startDate,
    List<PlanMicrocycle>? microcycles,
    this.notes,
    String? createdAt,
    String? updatedAt,
  })  : uid = uid ?? UidGenerator.generate(),
        microcycles = microcycles ?? const [],
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'status': status,
        'goal': goal,
        'startDate': startDate,
        'microcycles': microcycles.map((m) => m.toJson()).toList(),
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory PlanMesocycle.fromJson(Map<String, dynamic> json) => PlanMesocycle(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        goal: json['goal'] as String?,
        startDate: json['startDate'] as String?,
        microcycles: (json['microcycles'] as List<dynamic>?)
                ?.map((e) =>
                    PlanMicrocycle.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  PlanMesocycle copyWith({
    String? uid,
    String? name,
    String? status,
    String? goal,
    String? startDate,
    List<PlanMicrocycle>? microcycles,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) =>
      PlanMesocycle(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        status: status ?? this.status,
        goal: goal ?? this.goal,
        startDate: startDate ?? this.startDate,
        microcycles: microcycles ?? this.microcycles,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
