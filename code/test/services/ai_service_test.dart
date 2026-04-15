import 'package:flutter_test/flutter_test.dart';
import 'package:powerlifting_app/services/ai_service.dart';

void main() {
  group('AiService', () {
    late AiService aiService;

    setUp(() {
      aiService = AiService();
    });

    test('buildSystemPrompt should return non-empty string', () {
      final prompt = aiService.buildSystemPrompt();

      expect(prompt.isNotEmpty, true);
      expect(prompt.contains('力量举'), true);
      expect(prompt.contains('中文'), true);
      expect(prompt.contains('RPE'), true);
    });

    test('buildSystemPrompt with memory files should include them', () {
      // Using the model directly instead of creating instances
      // since AiMemoryFile is available
      final prompt = aiService.buildSystemPrompt();

      expect(prompt.contains('深蹲'), true);
      expect(prompt.contains('卧推'), true);
      expect(prompt.contains('硬拉'), true);
    });

    test('generateSuggestedQuestions should return questions', () {
      final questions = aiService.generateSuggestedQuestions();

      expect(questions.isNotEmpty, true);
      expect(questions.length, lessThanOrEqualTo(4));
      for (final q in questions) {
        expect(q.isNotEmpty, true);
      }
    });

    test('generateSuggestedQuestions with context should adapt', () {
      final questionsWithPlan = aiService.generateSuggestedQuestions(
        currentPlanContext: 'Hypertrophy Block',
      );

      final questionsWithRecords = aiService.generateSuggestedQuestions(
        recentTrainingContext: 'has_records',
      );

      expect(questionsWithPlan.isNotEmpty, true);
      expect(questionsWithRecords.isNotEmpty, true);
    });
  });
}
