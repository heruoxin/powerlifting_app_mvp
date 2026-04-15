import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/ai_topic.dart';
import '../models/training_record.dart';

class AiService {
  static const String _apiKey = 'AIzaSyAZWpsbwOfL4TB59KuRW7CAWXKObXycJ44';
  static const String _modelName = 'gemini-3.0-flash';

  late GenerativeModel _model;

  void init() {
    _model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(buildSystemPrompt()),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2048,
      ),
    );
  }

  /// Send a message with optional conversation history and system prompt.
  Future<String> sendMessage(
    String message, {
    List<AiMessage>? history,
    String? systemPrompt,
  }) async {
    try {
      final model = systemPrompt != null
          ? GenerativeModel(
              model: _modelName,
              apiKey: _apiKey,
              systemInstruction: Content.system(systemPrompt),
              generationConfig: GenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 2048,
              ),
            )
          : _model;

      final chatHistory = <Content>[];
      if (history != null) {
        for (final msg in history) {
          if (msg.role == 'user') {
            chatHistory.add(Content.text(msg.content));
          } else if (msg.role == 'assistant' || msg.role == 'model') {
            chatHistory.add(Content.model([TextPart(msg.content)]));
          }
        }
      }

      final chat = model.startChat(history: chatHistory);
      final response = await chat.sendMessage(Content.text(message));
      return response.text ?? '抱歉，我没有生成回复。';
    } catch (e) {
      return '发生错误: $e';
    }
  }

  /// Generate a training summary after workout completion.
  Future<String> generateTrainingSummary(TrainingRecord record) async {
    final buffer = StringBuffer()
      ..writeln('请为以下训练记录生成简短的总结和分析：')
      ..writeln('日期: ${record.date}')
      ..writeln('训练日: ${record.dayLabel ?? record.daySlotLabel}');

    for (final block in record.exerciseBlocks) {
      buffer.writeln('\n${block.name}:');
      for (var i = 0; i < block.sets.length; i++) {
        final set = block.sets[i];
        final actual = set.actual;
        if (actual == null) continue;
        final load = actual.loadValue?.firstOrNull ?? 0;
        final rep = actual.rep?.firstOrNull ?? 0;
        final rpe = set.effortMetrics?.rpe?.firstOrNull;
        buffer.write('  第${i + 1}组: ${load}kg × ${rep.toInt()}次');
        if (rpe != null) buffer.write(' RPE $rpe');
        buffer.writeln();
      }
    }

    buffer.writeln('\n请简要分析训练表现，包括强度控制和疲劳管理。不超过200字。');
    return sendMessage(buffer.toString());
  }

  /// Generate pre-training tips.
  Future<String> generatePreTrainingTips(
    String planDayInfo,
    String recentPerformance,
  ) async {
    final prompt = '''基于以下信息，给出简短的训练前提示：

今日计划:
$planDayInfo

近期表现:
$recentPerformance

请给出2-3条简短的训练前提示，注意重量选择和疲劳管理。不超过150字。''';
    return sendMessage(prompt);
  }

  /// Generate coach observation.
  Future<String> generateCoachObservation(String recentData) async {
    final prompt = '''作为教练，基于以下近期训练数据，给出一段简短的观察和建议：

$recentData

请从训练量、强度进展和恢复三个角度给出简短观察。不超过200字。''';
    return sendMessage(prompt);
  }

  String buildSystemPrompt() {
    return '你是一位专业的力量举教练AI助手，名为"电子教练"。\n'
        '你精通力量举三大项（深蹲、卧推、硬拉）的训练理论与实践。\n'
        '你理解RPE（自觉用力度）、周期化训练（periodization）、渐进超负荷等核心概念。\n'
        '你能够分析训练数据，提供个性化的训练建议和计划调整。\n'
        '你的沟通风格专业但亲和，注重以数据为依据的建议。\n'
        '请使用中文回复。';
  }
}
