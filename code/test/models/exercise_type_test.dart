import 'package:flutter_test/flutter_test.dart';
import 'package:powerlifting_app/models/exercise_type.dart';

void main() {
  group('ExerciseType', () {
    test('should create with required fields', () {
      final et = ExerciseType(
        key: 'squat',
        displayName: '深蹲',
        category: '主项',
        recordProfileKey: 'load_reps_profile',
      );

      expect(et.key, 'squat');
      expect(et.displayName, '深蹲');
      expect(et.category, '主项');
      expect(et.recordProfileKey, 'load_reps_profile');
    });

    test('should serialize and deserialize', () {
      final et = ExerciseType(
        key: 'bench_press',
        displayName: '卧推',
        category: '主项',
        recordProfileKey: 'load_reps_profile',
      );

      final json = et.toJson();
      final restored = ExerciseType.fromJson(json);

      expect(restored.key, 'bench_press');
      expect(restored.displayName, '卧推');
      expect(restored.category, '主项');
      expect(restored.recordProfileKey, 'load_reps_profile');
    });

    test('defaultExerciseTypes should return comprehensive list', () {
      final types = ExerciseType.defaultExerciseTypes();

      expect(types.isNotEmpty, true);

      // Should include the three main lifts
      expect(types.any((t) => t.key == 'squat'), true);
      expect(types.any((t) => t.key == 'bench_press'), true);
      expect(types.any((t) => t.key == 'deadlift'), true);

      // Should include different categories
      final categories = types.map((t) => t.category).toSet();
      expect(categories.length, greaterThan(1));
    });

    test('all exercise types should have non-empty key and displayName', () {
      final types = ExerciseType.defaultExerciseTypes();
      for (final t in types) {
        expect(t.key.isNotEmpty, true, reason: 'key should not be empty');
        expect(t.displayName.isNotEmpty, true,
            reason: 'displayName should not be empty for ${t.key}');
      }
    });
  });
}
