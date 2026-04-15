import 'package:flutter_test/flutter_test.dart';
import 'package:powerlifting_app/models/plan_models.dart';

void main() {
  group('PlanFieldValue', () {
    test('should serialize and deserialize correctly', () {
      final fv = PlanFieldValue(
        value: [100.0],
        unit: 'kg',
        origin: 'coach',
        percentRm: 75.0,
        referenceLiftKey: 'squat',
      );

      final json = fv.toJson();
      final restored = PlanFieldValue.fromJson(json);

      expect(restored.value, [100.0]);
      expect(restored.unit, 'kg');
      expect(restored.origin, 'coach');
      expect(restored.percentRm, 75.0);
      expect(restored.referenceLiftKey, 'squat');
    });

    test('empty field value should have correct defaults', () {
      const fv = PlanFieldValue.empty;
      expect(fv.value, isNull);
      expect(fv.unit, isNull);
      expect(fv.origin, 'empty');
    });

    test('copyWith should work correctly', () {
      const original = PlanFieldValue(value: [100.0], unit: 'kg');
      final modified = original.copyWith(value: [110.0]);

      expect(modified.value, [110.0]);
      expect(modified.unit, 'kg'); // Preserved
    });
  });

  group('PlanSetTarget', () {
    test('should serialize and deserialize correctly', () {
      final target = PlanSetTarget(
        load: const PlanFieldValue(value: [100.0], unit: 'kg', origin: 'coach'),
        rep: const PlanFieldValue(value: [5.0], origin: 'coach'),
        rpe: const PlanFieldValue(value: [8.0], origin: 'coach'),
      );

      final json = target.toJson();
      final restored = PlanSetTarget.fromJson(json);

      expect(restored.load.value, [100.0]);
      expect(restored.rep.value, [5.0]);
      expect(restored.rpe.value, [8.0]);
    });

    test('default target should have all empty fields', () {
      const target = PlanSetTarget();
      expect(target.load.origin, 'empty');
      expect(target.rep.origin, 'empty');
      expect(target.rpe.origin, 'empty');
    });
  });

  group('PlanSet', () {
    test('should generate UID on creation', () {
      final ps = PlanSet(exerciseItemUid: 'item1');
      expect(ps.uid.length, 12);
      expect(ps.exerciseItemUid, 'item1');
    });

    test('should serialize and deserialize', () {
      final ps = PlanSet(
        exerciseItemUid: 'item1',
        setOrderInItem: 2,
        tags: ['top_set', 'amrap'],
        isOptional: true,
        target: PlanSetTarget(
          load: const PlanFieldValue(value: [120.0], unit: 'kg'),
          rep: const PlanFieldValue(value: [3.0, 5.0]),
        ),
      );

      final json = ps.toJson();
      final restored = PlanSet.fromJson(json);

      expect(restored.exerciseItemUid, 'item1');
      expect(restored.setOrderInItem, 2);
      expect(restored.tags, ['top_set', 'amrap']);
      expect(restored.isOptional, true);
      expect(restored.target.load.value, [120.0]);
      expect(restored.target.rep.value, [3.0, 5.0]);
    });
  });

  group('PlanExerciseItem', () {
    test('should create with defaults', () {
      final item = PlanExerciseItem(
        planDayUid: 'day1',
        exerciseTypeKey: 'squat',
      );

      expect(item.uid.length, 12);
      expect(item.exerciseTypeKey, 'squat');
      expect(item.recordProfileKey, 'load_reps_profile');
      expect(item.fieldVisibility['load'], true);
      expect(item.fieldVisibility['rep'], true);
      expect(item.fieldVisibility['distance'], false);
    });

    test('should serialize with sets', () {
      final item = PlanExerciseItem(
        planDayUid: 'day1',
        exerciseTypeKey: 'bench_press',
        displayNameOverride: '卧推',
        sets: [
          PlanSet(exerciseItemUid: 'x'),
          PlanSet(exerciseItemUid: 'x'),
        ],
      );

      final json = item.toJson();
      final restored = PlanExerciseItem.fromJson(json);

      expect(restored.exerciseTypeKey, 'bench_press');
      expect(restored.displayNameOverride, '卧推');
      expect(restored.sets.length, 2);
    });
  });

  group('PlanDay', () {
    test('should create with defaults', () {
      final day = PlanDay(microcycleUid: 'w1', dayIndex: 0);
      expect(day.label, 'D1');
      expect(day.exerciseItems, isEmpty);
    });

    test('should serialize and deserialize', () {
      final day = PlanDay(
        microcycleUid: 'w1',
        dayIndex: 1,
        label: 'D2',
        dayTitle: '卧推日',
        exerciseItems: [
          PlanExerciseItem(
            planDayUid: 'day2',
            exerciseTypeKey: 'bench_press',
          ),
        ],
        notes: 'Focus on technique',
      );

      final json = day.toJson();
      final restored = PlanDay.fromJson(json);

      expect(restored.label, 'D2');
      expect(restored.dayTitle, '卧推日');
      expect(restored.exerciseItems.length, 1);
      expect(restored.notes, 'Focus on technique');
    });
  });

  group('PlanMicrocycle', () {
    test('should create with defaults', () {
      final week = PlanMicrocycle(mesocycleUid: 'meso1');
      expect(week.label, 'W1');
      expect(week.status, 'planned');
      expect(week.days, isEmpty);
    });

    test('should serialize and deserialize', () {
      final week = PlanMicrocycle(
        mesocycleUid: 'meso1',
        weekIndex: 2,
        label: 'W3',
        status: 'active',
        days: [
          PlanDay(microcycleUid: 'w3', dayIndex: 0),
          PlanDay(microcycleUid: 'w3', dayIndex: 1),
        ],
      );

      final json = week.toJson();
      final restored = PlanMicrocycle.fromJson(json);

      expect(restored.weekIndex, 2);
      expect(restored.label, 'W3');
      expect(restored.status, 'active');
      expect(restored.days.length, 2);
    });
  });

  group('PlanMesocycle', () {
    test('should create with defaults', () {
      final meso = PlanMesocycle(name: 'Hypertrophy Block');
      expect(meso.name, 'Hypertrophy Block');
      expect(meso.status, 'draft');
      expect(meso.microcycles, isEmpty);
    });

    test('should serialize full hierarchy', () {
      final meso = PlanMesocycle(
        name: 'Strength Block',
        status: 'active',
        goal: 'Build up to 180kg squat',
        startDate: '2024-03-01',
        microcycles: [
          PlanMicrocycle(
            mesocycleUid: 'test',
            weekIndex: 0,
            days: [
              PlanDay(
                microcycleUid: 'w1',
                exerciseItems: [
                  PlanExerciseItem(
                    planDayUid: 'd1',
                    exerciseTypeKey: 'squat',
                    sets: [
                      PlanSet(
                        exerciseItemUid: 'item1',
                        target: PlanSetTarget(
                          load: const PlanFieldValue(
                              value: [140.0], unit: 'kg', origin: 'coach'),
                          rep: const PlanFieldValue(
                              value: [5.0], origin: 'coach'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final json = meso.toJson();
      final restored = PlanMesocycle.fromJson(json);

      expect(restored.name, 'Strength Block');
      expect(restored.status, 'active');
      expect(restored.goal, 'Build up to 180kg squat');
      expect(restored.microcycles.length, 1);
      expect(restored.microcycles[0].days.length, 1);
      expect(restored.microcycles[0].days[0].exerciseItems.length, 1);
      expect(
        restored.microcycles[0].days[0].exerciseItems[0].sets[0].target.load
            .value,
        [140.0],
      );
    });
  });
}
