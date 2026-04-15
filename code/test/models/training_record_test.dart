import 'package:flutter_test/flutter_test.dart';
import 'package:powerlifting_app/models/training_record.dart';

void main() {
  group('SetValues', () {
    test('should serialize and deserialize correctly', () {
      final sv = SetValues(
        loadValue: [100.0],
        loadUnit: 'kg',
        rep: [5.0],
        note: 'test note',
      );

      final json = sv.toJson();
      final restored = SetValues.fromJson(json);

      expect(restored.loadValue, [100.0]);
      expect(restored.loadUnit, 'kg');
      expect(restored.rep, [5.0]);
      expect(restored.note, 'test note');
    });

    test('should handle null values gracefully', () {
      final sv = SetValues();
      final json = sv.toJson();
      final restored = SetValues.fromJson(json);

      expect(restored.loadValue, isNull);
      expect(restored.rep, isNull);
      expect(restored.duration, isNull);
    });

    test('should support range values', () {
      final sv = SetValues(
        loadValue: [80.0, 100.0],
        rep: [5.0, 8.0],
      );

      expect(sv.loadValue!.length, 2);
      expect(sv.loadValue!.first, 80.0);
      expect(sv.loadValue!.last, 100.0);
    });
  });

  group('EffortMetrics', () {
    test('should serialize and deserialize correctly', () {
      final em = EffortMetrics(rpe: [8.0]);
      final json = em.toJson();
      final restored = EffortMetrics.fromJson(json);

      expect(restored.rpe, [8.0]);
    });

    test('should handle empty metrics', () {
      final em = EffortMetrics();
      final json = em.toJson();
      final restored = EffortMetrics.fromJson(json);

      expect(restored.rpe, isNull);
    });
  });

  group('TrainingSet', () {
    test('should create with planning state by default', () {
      final ts = TrainingSet();
      expect(ts.state, 'planning');
      expect(ts.uid.length, 12);
    });

    test('should serialize and deserialize full set', () {
      final ts = TrainingSet(
        state: 'completed',
        sourceType: 'planned',
        baselinePlan: SetValues(loadValue: [100.0], rep: [5.0]),
        actual: SetValues(loadValue: [102.5], rep: [5.0]),
        effortMetrics: EffortMetrics(rpe: [8.5]),
        startedAt: '2024-03-15T10:00:00Z',
        finishedAt: '2024-03-15T10:01:30Z',
      );

      final json = ts.toJson();
      final restored = TrainingSet.fromJson(json);

      expect(restored.state, 'completed');
      expect(restored.sourceType, 'planned');
      expect(restored.baselinePlan?.loadValue, [100.0]);
      expect(restored.actual?.loadValue, [102.5]);
      expect(restored.effortMetrics?.rpe, [8.5]);
      expect(restored.startedAt, '2024-03-15T10:00:00Z');
      expect(restored.finishedAt, '2024-03-15T10:01:30Z');
    });

    test('copyWith should work correctly', () {
      final original = TrainingSet(state: 'pending');
      final modified = original.copyWith(
        state: 'completed',
        actual: SetValues(loadValue: [100.0]),
      );

      expect(original.state, 'pending');
      expect(modified.state, 'completed');
      expect(modified.actual?.loadValue, [100.0]);
      expect(modified.uid, original.uid); // UID preserved
    });
  });

  group('ExerciseBlock', () {
    test('should create with generated UID', () {
      final block = ExerciseBlock(
        name: 'Low Bar Squat',
        exerciseCategory: '主项',
        sets: [TrainingSet(), TrainingSet(), TrainingSet()],
      );

      expect(block.uid.length, 12);
      expect(block.name, 'Low Bar Squat');
      expect(block.sets.length, 3);
    });

    test('should serialize and deserialize correctly', () {
      final block = ExerciseBlock(
        name: 'Bench Press',
        exerciseCategory: '主项',
        sourceType: 'planned',
        displayColumns: ['load', 'rep'],
        note: 'Focus on arch',
        sets: [
          TrainingSet(
            state: 'completed',
            actual: SetValues(loadValue: [80.0], rep: [8.0]),
          ),
        ],
      );

      final json = block.toJson();
      final restored = ExerciseBlock.fromJson(json);

      expect(restored.name, 'Bench Press');
      expect(restored.exerciseCategory, '主项');
      expect(restored.sourceType, 'planned');
      expect(restored.displayColumns, ['load', 'rep']);
      expect(restored.note, 'Focus on arch');
      expect(restored.sets.length, 1);
      expect(restored.sets[0].state, 'completed');
    });
  });

  group('TrainingRecord', () {
    test('should create with default values', () {
      final record = TrainingRecord(
        state: 'in_progress',
        daySlotLabel: 'D1',
        startedAt: DateTime.now().toIso8601String(),
      );

      expect(record.uid.length, 12);
      expect(record.state, 'in_progress');
      expect(record.daySlotLabel, 'D1');
    });

    test('should serialize and deserialize complete record', () {
      final record = TrainingRecord(
        state: 'completed',
        dayLabel: '深蹲日',
        daySlotLabel: 'D1',
        sourcePlanDayUid: 'plan123',
        startedAt: '2024-03-15T09:00:00Z',
        finishedAt: '2024-03-15T10:30:00Z',
        exerciseBlocks: [
          ExerciseBlock(
            name: 'Squat',
            exerciseCategory: '主项',
            sets: [
              TrainingSet(
                state: 'completed',
                actual: SetValues(loadValue: [140.0], rep: [5.0]),
                effortMetrics: EffortMetrics(rpe: [7.0]),
              ),
            ],
          ),
        ],
      );

      final json = record.toJson();
      final restored = TrainingRecord.fromJson(json);

      expect(restored.state, 'completed');
      expect(restored.dayLabel, '深蹲日');
      expect(restored.exerciseBlocks.length, 1);
      expect(restored.exerciseBlocks[0].name, 'Squat');
      expect(
        restored.exerciseBlocks[0].sets[0].actual?.loadValue,
        [140.0],
      );
    });

    test('should handle empty exercise blocks', () {
      final record = TrainingRecord(
        state: 'in_progress',
        daySlotLabel: 'OS1',
        exerciseBlocks: [],
      );

      final json = record.toJson();
      final restored = TrainingRecord.fromJson(json);

      expect(restored.exerciseBlocks, isEmpty);
    });
  });
}
