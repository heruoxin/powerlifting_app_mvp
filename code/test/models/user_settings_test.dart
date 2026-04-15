import 'package:flutter_test/flutter_test.dart';
import 'package:powerlifting_app/models/user_settings.dart';

void main() {
  group('UserSettings', () {
    test('should create with defaults', () {
      const settings = UserSettings();
      expect(settings.userName, isNull);
      expect(settings.defaultWeightUnit, 'kg');
      expect(settings.preferredWeeklyFrequency, 4);
      expect(settings.tokenBalance, 0.0);
    });

    test('should serialize and deserialize', () {
      const settings = UserSettings(
        userName: '训练者',
        defaultWeightUnit: 'lb',
        preferredWeeklyFrequency: 3,
        tokenBalance: 50.0,
      );

      final json = settings.toJson();
      final restored = UserSettings.fromJson(json);

      expect(restored.userName, '训练者');
      expect(restored.defaultWeightUnit, 'lb');
      expect(restored.preferredWeeklyFrequency, 3);
      expect(restored.tokenBalance, 50.0);
    });

    test('copyWith should work correctly', () {
      const original = UserSettings(userName: 'Alice');
      final modified = original.copyWith(userName: 'Bob');

      expect(original.userName, 'Alice');
      expect(modified.userName, 'Bob');
      expect(modified.defaultWeightUnit, 'kg'); // Preserved
    });
  });
}
