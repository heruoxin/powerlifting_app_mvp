import '../utils/uid_generator.dart';

class ExerciseType {
  static const Map<String, bool> defaultVisibility = {
    'load': true,
    'intensity': false,
    'rep': true,
    'rpe': false,
    'duration': false,
    'distance': false,
    'note': false,
  };

  final String uid;
  final String key;
  final String displayName;
  final String category;
  final String recordProfileKey;
  final Map<String, bool> defaultFieldVisibility;

  ExerciseType({
    String? uid,
    required this.key,
    required this.displayName,
    required this.category,
    required this.recordProfileKey,
    Map<String, bool>? defaultFieldVisibility,
  })  : uid = uid ?? UidGenerator.generate(),
        defaultFieldVisibility =
            defaultFieldVisibility ?? defaultVisibility;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'key': key,
        'displayName': displayName,
        'category': category,
        'recordProfileKey': recordProfileKey,
        'defaultFieldVisibility':
            Map<String, dynamic>.from(defaultFieldVisibility),
      };

  factory ExerciseType.fromJson(Map<String, dynamic> json) => ExerciseType(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        key: json['key'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        category: json['category'] as String? ?? 'accessory',
        recordProfileKey:
            json['recordProfileKey'] as String? ?? 'load_reps_profile',
        defaultFieldVisibility:
            (json['defaultFieldVisibility'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, v as bool)) ??
                defaultVisibility,
      );

  ExerciseType copyWith({
    String? uid,
    String? key,
    String? displayName,
    String? category,
    String? recordProfileKey,
    Map<String, bool>? defaultFieldVisibility,
  }) =>
      ExerciseType(
        uid: uid ?? this.uid,
        key: key ?? this.key,
        displayName: displayName ?? this.displayName,
        category: category ?? this.category,
        recordProfileKey: recordProfileKey ?? this.recordProfileKey,
        defaultFieldVisibility:
            defaultFieldVisibility ?? this.defaultFieldVisibility,
      );

  // ---------------------------------------------------------------------------
  // Default exercise types
  // ---------------------------------------------------------------------------

  static const _loadReps = 'load_reps_profile';
  static const _bodyweightReps = 'bodyweight_reps_profile';
  static const _timedHold = 'timed_hold_profile';
  static const _distanceTime = 'distance_time_cardio_profile';

  static const Map<String, bool> _loadRepsVisibility = {
    'load': true,
    'intensity': false,
    'rep': true,
    'rpe': true,
    'duration': false,
    'distance': false,
    'note': false,
  };

  static const Map<String, bool> _bodyweightRepsVisibility = {
    'load': false,
    'intensity': false,
    'rep': true,
    'rpe': false,
    'duration': false,
    'distance': false,
    'note': false,
  };

  static const Map<String, bool> _timedHoldVisibility = {
    'load': false,
    'intensity': false,
    'rep': false,
    'rpe': false,
    'duration': true,
    'distance': false,
    'note': false,
  };

  static const Map<String, bool> _distanceTimeVisibility = {
    'load': false,
    'intensity': false,
    'rep': false,
    'rpe': false,
    'duration': true,
    'distance': true,
    'note': false,
  };

  static List<ExerciseType> defaultExerciseTypes() => [
        // ── Main (主项) ──
        ExerciseType(
          key: 'squat',
          displayName: '深蹲',
          category: 'main',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'bench_press',
          displayName: '卧推',
          category: 'main',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'deadlift',
          displayName: '硬拉',
          category: 'main',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),

        // ── Main Variant (主项变式) ──
        ExerciseType(
          key: 'pause_squat',
          displayName: '暂停深蹲',
          category: 'main_variant',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'close_grip_bench',
          displayName: '窄握卧推',
          category: 'main_variant',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'sumo_deadlift',
          displayName: '相扑硬拉',
          category: 'main_variant',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'front_squat',
          displayName: '前蹲',
          category: 'main_variant',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),

        // ── Accessory (辅助项) ──
        ExerciseType(
          key: 'cable_row',
          displayName: '绳索划船',
          category: 'accessory',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'pull_up',
          displayName: '引体向上',
          category: 'accessory',
          recordProfileKey: _bodyweightReps,
          defaultFieldVisibility: _bodyweightRepsVisibility,
        ),
        ExerciseType(
          key: 'dumbbell_press',
          displayName: '哑铃推举',
          category: 'accessory',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'leg_press',
          displayName: '腿举',
          category: 'accessory',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'lunges',
          displayName: '弓步',
          category: 'accessory',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'lat_pulldown',
          displayName: '高位下拉',
          category: 'accessory',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),
        ExerciseType(
          key: 'face_pull',
          displayName: '面拉',
          category: 'accessory',
          recordProfileKey: _loadReps,
          defaultFieldVisibility: _loadRepsVisibility,
        ),

        // ── Accessory – Timed ──
        ExerciseType(
          key: 'plank',
          displayName: '平板支撑',
          category: 'accessory',
          recordProfileKey: _timedHold,
          defaultFieldVisibility: _timedHoldVisibility,
        ),
        ExerciseType(
          key: 'side_plank',
          displayName: '侧平板支撑',
          category: 'accessory',
          recordProfileKey: _timedHold,
          defaultFieldVisibility: _timedHoldVisibility,
        ),

        // ── Cardio (有氧运动) ──
        ExerciseType(
          key: 'running',
          displayName: '跑步',
          category: 'cardio',
          recordProfileKey: _distanceTime,
          defaultFieldVisibility: _distanceTimeVisibility,
        ),
        ExerciseType(
          key: 'swimming',
          displayName: '游泳',
          category: 'cardio',
          recordProfileKey: _distanceTime,
          defaultFieldVisibility: _distanceTimeVisibility,
        ),
        ExerciseType(
          key: 'cycling',
          displayName: '骑行',
          category: 'cardio',
          recordProfileKey: _distanceTime,
          defaultFieldVisibility: _distanceTimeVisibility,
        ),
      ];
}
