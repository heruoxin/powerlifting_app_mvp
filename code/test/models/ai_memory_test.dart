import 'package:flutter_test/flutter_test.dart';
import 'package:powerlifting_app/models/ai_memory.dart';

void main() {
  group('AiMemoryFile', () {
    test('should create with required fields', () {
      final file = AiMemoryFile(
        key: 'diary',
        displayName: '训练日记',
        content: '# 训练日记\n\n今天完成了深蹲训练。',
      );

      expect(file.key, 'diary');
      expect(file.displayName, '训练日记');
      expect(file.content.contains('深蹲'), true);
      expect(file.isEditable, true);
    });

    test('should serialize and deserialize correctly', () {
      final file = AiMemoryFile(
        key: 'soul',
        displayName: '灵魂设定',
        content: 'You are a coach.',
        isEditable: false,
      );

      final json = file.toJson();
      final restored = AiMemoryFile.fromJson(json);

      expect(restored.key, 'soul');
      expect(restored.displayName, '灵魂设定');
      expect(restored.content, 'You are a coach.');
      expect(restored.isEditable, false);
    });

    test('copyWith should work correctly', () {
      final original = AiMemoryFile(
        key: 'diary',
        displayName: '训练日记',
        content: 'old content',
      );
      final modified = original.copyWith(content: 'new content');

      expect(original.content, 'old content');
      expect(modified.content, 'new content');
      expect(modified.key, 'diary'); // Preserved
    });

    test('defaultFiles should return 5 files', () {
      final files = AiMemoryFile.defaultFiles();

      expect(files.length, 5);
      expect(files.any((f) => f.key == 'soul'), true);
      expect(files.any((f) => f.key == 'diary'), true);
      expect(files.any((f) => f.key == 'coach_observation'), true);
      expect(files.any((f) => f.key == 'training_plan'), true);
      expect(files.any((f) => f.key == 'user_traits'), true);
    });

    test('soul file should be non-editable by default', () {
      final files = AiMemoryFile.defaultFiles();
      final soul = files.firstWhere((f) => f.key == 'soul');
      expect(soul.isEditable, false);
    });
  });
}
