import 'package:intl/intl.dart';

import '../models/ai_memory.dart';
import '../models/ai_topic.dart';
import '../models/athlete_profile.dart';
import '../models/exercise_type.dart';
import '../models/plan_models.dart';
import '../models/training_note.dart';
import '../models/training_record.dart';
import '../models/user_settings.dart';
import '../utils/uid_generator.dart';

/// Generates realistic demo data for a powerlifting training app.
class DemoDataService {
  // ── Mesocycle ──

  static PlanMesocycle generateDemoMesocycle() {
    final mesoUid = UidGenerator.generate();
    final startDate = DateTime.now().subtract(const Duration(days: 14));
    final fmt = DateFormat('yyyy-MM-dd');

    final microcycles = <PlanMicrocycle>[];
    for (var w = 0; w < 4; w++) {
      final microUid = UidGenerator.generate();
      final days = <PlanDay>[];

      for (var d = 0; d < 4; d++) {
        final dayUid = UidGenerator.generate();
        final items = _buildDayItems(dayUid, d, w);
        days.add(PlanDay(
          uid: dayUid,
          microcycleUid: microUid,
          dayIndex: d,
          label: 'D${d + 1}',
          dayTitle: _dayTitle(d),
          exerciseItems: items,
        ));
      }

      microcycles.add(PlanMicrocycle(
        uid: microUid,
        mesocycleUid: mesoUid,
        weekIndex: w,
        label: 'W${w + 1}',
        status: w < 2 ? 'completed' : 'planned',
        days: days,
      ));
    }

    return PlanMesocycle(
      uid: mesoUid,
      name: '力量举基础周期 - 4周',
      status: 'active',
      goal: '提升三大项绝对力量',
      startDate: fmt.format(startDate),
      microcycles: microcycles,
      notes: '4周力量积累周期，前2周适应，后2周增加强度',
    );
  }

  static String _dayTitle(int dayIndex) {
    const titles = ['深蹲日', '卧推日', '硬拉日', '上肢辅助日'];
    return titles[dayIndex];
  }

  static List<PlanExerciseItem> _buildDayItems(
    String dayUid,
    int dayIndex,
    int weekIndex,
  ) {
    switch (dayIndex) {
      case 0:
        return _squatDayItems(dayUid, weekIndex);
      case 1:
        return _benchDayItems(dayUid, weekIndex);
      case 2:
        return _deadliftDayItems(dayUid, weekIndex);
      case 3:
        return _accessoryDayItems(dayUid, weekIndex);
      default:
        return [];
    }
  }

  static List<PlanExerciseItem> _squatDayItems(String dayUid, int week) {
    final baseLoad = 100.0 + week * 5;
    return [
      _buildItem(dayUid, 0, 'squat', '深蹲', 5, baseLoad + 40, 5, 7.0),
      _buildItem(dayUid, 1, 'pause_squat', '暂停深蹲', 3, baseLoad + 20, 4, 7.5),
      _buildItem(dayUid, 2, 'leg_press', '腿举', 3, baseLoad + 60, 10, null),
      _buildItem(dayUid, 3, 'plank', '平板支撑', 3, null, null, null,
          isDuration: true, durationSec: 60),
    ];
  }

  static List<PlanExerciseItem> _benchDayItems(String dayUid, int week) {
    final baseLoad = 70.0 + week * 2.5;
    return [
      _buildItem(dayUid, 0, 'bench_press', '卧推', 5, baseLoad + 30, 5, 7.0),
      _buildItem(
          dayUid, 1, 'close_grip_bench', '窄握卧推', 3, baseLoad + 15, 6, 7.5),
      _buildItem(
          dayUid, 2, 'dumbbell_press', '哑铃推举', 3, baseLoad - 40, 10, null),
      _buildItem(dayUid, 3, 'face_pull', '面拉', 3, baseLoad - 50, 15, null),
    ];
  }

  static List<PlanExerciseItem> _deadliftDayItems(String dayUid, int week) {
    final baseLoad = 140.0 + week * 5;
    return [
      _buildItem(dayUid, 0, 'deadlift', '硬拉', 4, baseLoad + 40, 4, 7.5),
      _buildItem(
          dayUid, 1, 'sumo_deadlift', '相扑硬拉', 3, baseLoad + 10, 5, 7.0),
      _buildItem(dayUid, 2, 'cable_row', '绳索划船', 3, baseLoad - 80, 10, null),
      _buildItem(
          dayUid, 3, 'lat_pulldown', '高位下拉', 3, baseLoad - 90, 12, null),
    ];
  }

  static List<PlanExerciseItem> _accessoryDayItems(String dayUid, int week) {
    final baseLoad = 60.0 + week * 2.5;
    return [
      _buildItem(dayUid, 0, 'front_squat', '前蹲', 4, baseLoad + 30, 6, 7.0),
      _buildItem(dayUid, 1, 'dumbbell_press', '哑铃推举', 4, baseLoad - 30, 10, null),
      _buildItem(dayUid, 2, 'cable_row', '绳索划船', 3, baseLoad - 10, 12, null),
      _buildItem(dayUid, 3, 'pull_up', '引体向上', 3, null, 8, null,
          isBodyweight: true),
      _buildItem(dayUid, 4, 'face_pull', '面拉', 3, baseLoad - 45, 15, null),
    ];
  }

  static PlanExerciseItem _buildItem(
    String dayUid,
    int order,
    String exKey,
    String name,
    int numSets,
    double? load,
    int? reps,
    double? rpe, {
    bool isDuration = false,
    int? durationSec,
    bool isBodyweight = false,
  }) {
    final itemUid = UidGenerator.generate();
    String profileKey;
    Map<String, bool> vis;

    if (isDuration) {
      profileKey = 'timed_hold_profile';
      vis = const {
        'load': false, 'intensity': false, 'rep': false,
        'rpe': false, 'duration': true, 'distance': false, 'note': false,
      };
    } else if (isBodyweight) {
      profileKey = 'bodyweight_reps_profile';
      vis = const {
        'load': false, 'intensity': false, 'rep': true,
        'rpe': false, 'duration': false, 'distance': false, 'note': false,
      };
    } else {
      profileKey = 'load_reps_profile';
      vis = const {
        'load': true, 'intensity': false, 'rep': true,
        'rpe': true, 'duration': false, 'distance': false, 'note': false,
      };
    }

    final sets = List.generate(numSets, (i) {
      PlanSetTarget target;
      if (isDuration) {
        target = PlanSetTarget(
          duration: PlanFieldValue(
            value: [durationSec?.toDouble()],
            unit: 's',
            origin: 'coach',
          ),
        );
      } else if (isBodyweight) {
        target = PlanSetTarget(
          rep: PlanFieldValue(value: [reps?.toDouble()], origin: 'coach'),
        );
      } else {
        target = PlanSetTarget(
          load: PlanFieldValue(
            value: [load],
            unit: 'kg',
            origin: 'coach',
          ),
          rep: PlanFieldValue(value: [reps?.toDouble()], origin: 'coach'),
          rpe: rpe != null
              ? PlanFieldValue(value: [rpe], origin: 'coach')
              : PlanFieldValue.empty,
        );
      }

      return PlanSet(
        exerciseItemUid: itemUid,
        setOrderInItem: i,
        target: target,
      );
    });

    return PlanExerciseItem(
      uid: itemUid,
      planDayUid: dayUid,
      orderInDay: order,
      exerciseTypeKey: exKey,
      displayNameOverride: name,
      recordProfileKey: profileKey,
      fieldVisibility: vis,
      sets: sets,
    );
  }

  // ── Training Records ──

  static List<TrainingRecord> generateDemoRecords(PlanMesocycle meso) {
    final records = <TrainingRecord>[];
    final baseDate = DateTime.now().subtract(const Duration(days: 14));
    final fmt = DateFormat('yyyy-MM-dd');

    // Generate records for first 2 weeks (completed)
    for (var w = 0; w < 2; w++) {
      final micro = meso.microcycles[w];
      for (var d = 0; d < micro.days.length; d++) {
        final day = micro.days[d];
        final recordDate = baseDate.add(Duration(days: w * 7 + d * 2));
        final startTime = recordDate.add(const Duration(hours: 9));
        final endTime = startTime.add(const Duration(hours: 1, minutes: 30));

        final blocks = day.exerciseItems.map((item) {
          final sets = item.sets.map((planSet) {
            final target = planSet.target;
            // Add small variance to make data realistic
            final loadVariance = (d + w).isEven ? 0.0 : 2.5;

            SetValues? baseline;
            SetValues? actual;
            EffortMetrics? effort;

            if (target.load.value != null && target.load.value!.isNotEmpty) {
              final plannedLoad = target.load.value!.first ?? 0;
              final actualLoad = plannedLoad + loadVariance;
              final plannedReps = target.rep.value?.first?.toInt() ?? 5;

              baseline = SetValues(
                loadValue: [plannedLoad],
                loadUnit: 'kg',
                rep: [plannedReps.toDouble()],
              );
              actual = SetValues(
                loadValue: [actualLoad],
                loadUnit: 'kg',
                rep: [plannedReps.toDouble()],
              );
              if (target.rpe.value != null && target.rpe.value!.isNotEmpty) {
                final rpeVal = target.rpe.value!.first ?? 7.0;
                effort = EffortMetrics(rpe: [rpeVal + (w * 0.5)]);
              }
            } else if (target.duration.value != null &&
                target.duration.value!.isNotEmpty) {
              final dur = target.duration.value!.first ?? 60;
              baseline = SetValues(duration: [dur], durationUnit: 's');
              actual = SetValues(duration: [dur + 5], durationUnit: 's');
            } else if (target.rep.value != null &&
                target.rep.value!.isNotEmpty) {
              final reps = target.rep.value!.first ?? 8;
              baseline = SetValues(rep: [reps]);
              actual = SetValues(rep: [reps + 1]);
            }

            return TrainingSet(
              state: 'completed',
              sourceType: 'planned',
              baselinePlan: baseline,
              workingPlan: baseline,
              actual: actual,
              effortMetrics: effort,
              startedAt: startTime.toIso8601String(),
              finishedAt: startTime
                  .add(const Duration(minutes: 3))
                  .toIso8601String(),
            );
          }).toList();

          return ExerciseBlock(
            name: item.displayNameOverride ?? item.exerciseTypeKey,
            exerciseCategory: _categoryForKey(item.exerciseTypeKey),
            sourceType: 'planned',
            displayColumns: _columnsForProfile(item.recordProfileKey),
            sets: sets,
          );
        }).toList();

        records.add(TrainingRecord(
          date: fmt.format(recordDate),
          state: 'completed',
          endedReason: 'user_finished',
          dayLabel: day.dayTitle,
          weekIndex: w,
          daySlotType: 'planned_day',
          daySlotIndex: d,
          daySlotLabel: day.label,
          sourcePlanDayUid: day.uid,
          startedAt: startTime.toIso8601String(),
          finishedAt: endTime.toIso8601String(),
          exerciseBlocks: blocks,
        ));
      }
    }

    return records;
  }

  static String _categoryForKey(String key) {
    const mainLifts = {'squat', 'bench_press', 'deadlift'};
    const variants = {
      'pause_squat', 'close_grip_bench', 'sumo_deadlift', 'front_squat'
    };
    if (mainLifts.contains(key)) return '主项';
    if (variants.contains(key)) return '主项变式';
    return '辅助项';
  }

  static List<String> _columnsForProfile(String profile) {
    switch (profile) {
      case 'timed_hold_profile':
        return ['duration'];
      case 'bodyweight_reps_profile':
        return ['rep'];
      case 'distance_time_cardio_profile':
        return ['duration', 'distance'];
      default:
        return ['load', 'rep'];
    }
  }

  // ── Athlete Profiles ──

  static List<AthleteLiftProfile> generateDemoProfiles() {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    final today = fmt.format(now);
    final monthAgo = fmt.format(now.subtract(const Duration(days: 30)));
    final twoMonthsAgo = fmt.format(now.subtract(const Duration(days: 60)));

    return [
      AthleteLiftProfile(
        liftKey: 'squat',
        displayName: '深蹲',
        currentE1rm: 160,
        e1rmUnit: 'kg',
        e1rmUpdatedAt: now.toIso8601String(),
        prSnapshots: [
          PrSnapshot(value: 155, date: twoMonthsAgo, source: 'estimated'),
          PrSnapshot(value: 160, date: today, source: 'estimated'),
        ],
        history: [
          E1rmHistoryEntry(value: 145, date: twoMonthsAgo),
          E1rmHistoryEntry(value: 155, date: monthAgo),
          E1rmHistoryEntry(value: 160, date: today),
        ],
      ),
      AthleteLiftProfile(
        liftKey: 'bench_press',
        displayName: '卧推',
        currentE1rm: 115,
        e1rmUnit: 'kg',
        e1rmUpdatedAt: now.toIso8601String(),
        prSnapshots: [
          PrSnapshot(value: 110, date: twoMonthsAgo, source: 'estimated'),
          PrSnapshot(value: 115, date: today, source: 'estimated'),
        ],
        history: [
          E1rmHistoryEntry(value: 105, date: twoMonthsAgo),
          E1rmHistoryEntry(value: 110, date: monthAgo),
          E1rmHistoryEntry(value: 115, date: today),
        ],
      ),
      AthleteLiftProfile(
        liftKey: 'deadlift',
        displayName: '硬拉',
        currentE1rm: 200,
        e1rmUnit: 'kg',
        e1rmUpdatedAt: now.toIso8601String(),
        prSnapshots: [
          PrSnapshot(value: 190, date: twoMonthsAgo, source: 'estimated'),
          PrSnapshot(value: 200, date: today, source: 'estimated'),
        ],
        history: [
          E1rmHistoryEntry(value: 185, date: twoMonthsAgo),
          E1rmHistoryEntry(value: 195, date: monthAgo),
          E1rmHistoryEntry(value: 200, date: today),
        ],
      ),
    ];
  }

  // ── Notes ──

  static List<TrainingNote> generateDemoNotes() {
    final now = DateTime.now();
    return [
      TrainingNote(
        title: '深蹲技术调整',
        content: '今天尝试了更宽的站距，感觉臀部发力更好，'
            '但膝盖有轻微不适，需要继续观察。下次尝试调整脚尖外展角度。',
        createdAt: now.subtract(const Duration(days: 10)).toIso8601String(),
        updatedAt: now.subtract(const Duration(days: 10)).toIso8601String(),
      ),
      TrainingNote(
        title: '卧推握距实验',
        content: '窄握卧推时肩膀感觉更舒适，准备在下个周期将主项卧推'
            '握距收窄1-2厘米。注意保持肩胛骨收紧。',
        createdAt: now.subtract(const Duration(days: 7)).toIso8601String(),
        updatedAt: now.subtract(const Duration(days: 7)).toIso8601String(),
      ),
      TrainingNote(
        title: '恢复与睡眠',
        content: '最近睡眠质量下降，训练时感觉恢复不足，RPE普遍偏高。'
            '计划本周增加睡眠时间，减少咖啡因摄入。',
        createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
        updatedAt: now.subtract(const Duration(days: 3)).toIso8601String(),
      ),
      TrainingNote(
        title: '硬拉起始位置',
        content: '调整了硬拉起始位置，臀部稍微抬高约2厘米，'
            '感觉背部张力更好，离地更顺畅。保持这个调整继续练习。',
        createdAt: now.subtract(const Duration(days: 1)).toIso8601String(),
        updatedAt: now.subtract(const Duration(days: 1)).toIso8601String(),
      ),
    ];
  }

  // ── AI Topic ──

  static AiTopic generateDemoTopic() {
    final now = DateTime.now();
    return AiTopic(
      title: '训练进展讨论',
      category: 'recent',
      createdAt: now.subtract(const Duration(days: 5)).toIso8601String(),
      updatedAt: now.subtract(const Duration(days: 5)).toIso8601String(),
      lastActiveAt: now.subtract(const Duration(days: 5)).toIso8601String(),
      messages: [
        AiMessage(
          role: 'user',
          content: '我的深蹲最近一直卡在140kg做5组5次，RPE大概7.5-8，该怎么突破？',
          createdAt: now.subtract(const Duration(days: 5)).toIso8601String(),
        ),
        AiMessage(
          role: 'assistant',
          content: '从你的数据来看，140kg×5×5 RPE 7.5-8表明你有一定的余量空间。\n\n'
              '建议尝试以下方法突破：\n'
              '1. **渐进加载**：下周尝试142.5kg，保持组数和次数\n'
              '2. **变式训练**：增加暂停深蹲的训练量，提升底部力量\n'
              '3. **RPE管理**：如果RPE持续在8以上，可以先降组（减少1-2组）再加重量\n\n'
              '保持耐心，力量进步需要持续积累。',
          createdAt: now.subtract(const Duration(days: 5)).toIso8601String(),
        ),
      ],
      contextReferences: [
        const ContextReference(
          type: 'training_record',
          displayLabel: '近期深蹲训练',
          previewText: '140kg × 5 × 5, RPE 7.5-8',
        ),
      ],
    );
  }

  // ── Settings ──

  static UserSettings generateDemoSettings() {
    return const UserSettings(
      userName: '运动员',
      preferredWeeklyFrequency: 4,
      defaultWeightUnit: 'kg',
      language: 'zh-CN',
      tokenBalance: 100.0,
      tokenSpentRecent: 5.0,
      autoTriggerSettings: {
        'post_training_summary': true,
        'weekly_observation': true,
      },
    );
  }

  // ── Default memory files (uses built-in defaults) ──

  static List<AiMemoryFile> generateDemoMemoryFiles() {
    return AiMemoryFile.defaultFiles();
  }

  // ── Default exercise types ──

  static List<ExerciseType> generateDemoExerciseTypes() {
    return ExerciseType.defaultExerciseTypes();
  }
}
