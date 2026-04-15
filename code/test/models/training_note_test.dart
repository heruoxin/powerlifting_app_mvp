import 'package:flutter_test/flutter_test.dart';
import 'package:powerlifting_app/models/training_note.dart';

void main() {
  group('TrainingNote', () {
    test('should create with defaults', () {
      final note = TrainingNote(
        title: '训练笔记',
        content: '今天训练状态很好。',
      );

      expect(note.uid.length, 12);
      expect(note.title, '训练笔记');
      expect(note.content, '今天训练状态很好。');
      expect(note.references, isEmpty);
    });

    test('should serialize and deserialize', () {
      final note = TrainingNote(
        title: '深蹲技术笔记',
        content: '膝盖追踪需要注意',
        references: [
          NoteReference(targetType: 'training_record', targetUid: 'rec1'),
        ],
      );

      final json = note.toJson();
      final restored = TrainingNote.fromJson(json);

      expect(restored.title, '深蹲技术笔记');
      expect(restored.content, '膝盖追踪需要注意');
      expect(restored.references.length, 1);
      expect(restored.references[0].targetType, 'training_record');
    });
  });

  group('NoteReference', () {
    test('should serialize and deserialize', () {
      final ref = NoteReference(
        targetType: 'plan_day',
        targetUid: 'day123',
      );

      final json = ref.toJson();
      final restored = NoteReference.fromJson(json);

      expect(restored.targetType, 'plan_day');
      expect(restored.targetUid, 'day123');
    });
  });
}
