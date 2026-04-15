import 'package:flutter_test/flutter_test.dart';
import 'package:powerlifting_app/models/ai_topic.dart';

void main() {
  group('AiMessage', () {
    test('should create user message', () {
      final msg = AiMessage(role: 'user', content: '帮我分析训练');
      expect(msg.role, 'user');
      expect(msg.content, '帮我分析训练');
      expect(msg.uid.length, 12);
    });

    test('should create assistant message', () {
      final msg = AiMessage(role: 'assistant', content: '好的，我来分析一下...');
      expect(msg.role, 'assistant');
    });

    test('should serialize and deserialize', () {
      final msg = AiMessage(
        role: 'user',
        content: '这次训练怎么样？',
      );

      final json = msg.toJson();
      final restored = AiMessage.fromJson(json);

      expect(restored.role, 'user');
      expect(restored.content, '这次训练怎么样？');
    });
  });

  group('ContextReference', () {
    test('should serialize and deserialize', () {
      final ref = ContextReference(
        type: 'training_record',
        targetUid: 'record123',
        displayLabel: 'W3 D1 深蹲日',
        previewText: '深蹲 140kg x5',
      );

      final json = ref.toJson();
      final restored = ContextReference.fromJson(json);

      expect(restored.type, 'training_record');
      expect(restored.targetUid, 'record123');
      expect(restored.displayLabel, 'W3 D1 深蹲日');
      expect(restored.previewText, '深蹲 140kg x5');
    });
  });

  group('AiTopic', () {
    test('should create with defaults', () {
      final topic = AiTopic(title: '训练分析');
      expect(topic.title, '训练分析');
      expect(topic.messages, isEmpty);
      expect(topic.contextReferences, isEmpty);
      expect(topic.uid.length, 12);
    });

    test('should serialize and deserialize with messages', () {
      final topic = AiTopic(
        title: '深蹲技术讨论',
        messages: [
          AiMessage(role: 'user', content: '深蹲时膝盖内扣怎么办？'),
          AiMessage(role: 'assistant', content: '膝盖内扣通常是臀部力量不足导致...'),
        ],
        contextReferences: [
          ContextReference(
            type: 'training_record',
            targetUid: 'rec1',
            displayLabel: '上次深蹲训练',
          ),
        ],
      );

      final json = topic.toJson();
      final restored = AiTopic.fromJson(json);

      expect(restored.title, '深蹲技术讨论');
      expect(restored.messages.length, 2);
      expect(restored.messages[0].role, 'user');
      expect(restored.messages[1].role, 'assistant');
      expect(restored.contextReferences.length, 1);
    });

    test('copyWith should work correctly', () {
      final original = AiTopic(title: '原始标题');
      final modified = original.copyWith(
        title: '新标题',
        messages: [AiMessage(role: 'user', content: 'test')],
      );

      expect(original.title, '原始标题');
      expect(original.messages, isEmpty);
      expect(modified.title, '新标题');
      expect(modified.messages.length, 1);
      expect(modified.uid, original.uid); // UID preserved
    });
  });
}
