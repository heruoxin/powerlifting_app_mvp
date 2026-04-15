import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/ai_memory.dart';
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
        maxOutputTokens: 4096,
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
                maxOutputTokens: 4096,
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
      return '与AI通信时出错，请稍后再试。($e)';
    }
  }

  /// Generate a training summary after workout completion.
  Future<String> generateTrainingSummary(TrainingRecord record) async {
    final buffer = StringBuffer()
      ..writeln('请为以下训练记录生成简短的训练总结和分析：')
      ..writeln('日期: ${record.date}')
      ..writeln('训练日: ${record.dayLabel ?? record.daySlotLabel}');

    if (record.startedAt != null && record.finishedAt != null) {
      final start = DateTime.tryParse(record.startedAt!);
      final end = DateTime.tryParse(record.finishedAt!);
      if (start != null && end != null) {
        final dur = end.difference(start);
        buffer.writeln('训练时长: ${dur.inMinutes}分钟');
      }
    }

    int totalSets = 0;
    int completedSets = 0;
    int skippedSets = 0;
    double totalVolume = 0;

    for (final block in record.exerciseBlocks) {
      buffer.writeln('\n${block.name} (${block.exerciseCategory}):');
      for (var i = 0; i < block.sets.length; i++) {
        final set = block.sets[i];
        totalSets++;
        if (set.state == 'completed') completedSets++;
        if (set.state == 'skipped') skippedSets++;

        final actual = set.actual;
        if (actual == null) continue;
        final load = actual.loadValue?.firstOrNull ?? 0;
        final rep = actual.rep?.firstOrNull ?? 0;
        final rpe = set.effortMetrics?.rpe?.firstOrNull;
        buffer.write('  第${i + 1}组: ${load}kg × ${rep.toInt()}次');
        if (rpe != null) buffer.write(' RPE $rpe');
        buffer.writeln();
        totalVolume += load * rep;

        // Show plan vs actual comparison
        final plan = set.baselinePlan;
        if (plan != null) {
          final planLoad = plan.loadValue?.firstOrNull ?? 0;
          final planRep = plan.rep?.firstOrNull ?? 0;
          if (planLoad > 0 || planRep > 0) {
            buffer.writeln('    (计划: ${planLoad}kg × ${planRep.toInt()}次)');
          }
        }
      }
    }

    buffer
      ..writeln()
      ..writeln('完成率: $completedSets/$totalSets 组 '
          '(跳过$skippedSets组)')
      ..writeln('估算总容量: ${totalVolume.toStringAsFixed(0)}kg')
      ..writeln()
      ..writeln('请从以下角度简要分析（200字以内）：')
      ..writeln('1. 训练完成度与计划符合程度')
      ..writeln('2. 强度控制（RPE分布是否合理）')
      ..writeln('3. 疲劳管理建议')
      ..writeln('4. 一句话总结');

    return sendMessage(buffer.toString());
  }

  /// Generate pre-training tips based on plan and recent performance.
  Future<String> generatePreTrainingTips(
    String planDayInfo,
    String recentPerformance,
  ) async {
    final prompt = '''作为力量举教练，基于以下信息给出训练前提示：

今日计划:
$planDayInfo

近期表现:
$recentPerformance

请给出2-3条简短、实用的训练前提示，包括：
- 热身重点和注意事项
- 重量选择建议
- 疲劳管理提醒
控制在150字以内。''';
    return sendMessage(prompt);
  }

  /// Generate coach observation based on recent training data.
  Future<String> generateCoachObservation(String recentData) async {
    final prompt = '''作为力量举教练，基于以下近期训练数据，给出教练观察：

$recentData

请从以下角度给出简短观察和建议（200字以内）：
1. 训练量趋势（是否在合理范围）
2. 强度进展（三大项表现变化）
3. 恢复状况（RPE趋势、完成率）
4. 下阶段调整建议''';
    return sendMessage(prompt);
  }

  /// Generate suggested questions for a new AI topic.
  List<String> generateSuggestedQuestions({
    String? currentPlanContext,
    String? recentTrainingContext,
  }) {
    final questions = <String>[
      '帮我分析一下最近的训练表现',
      '我的三大项强度进展怎么样？',
      '当前训练计划需要调整吗？',
    ];

    if (currentPlanContext != null) {
      questions.insert(0, '帮我解读一下当前训练计划的设计思路');
    }
    if (recentTrainingContext != null) {
      questions.insert(1, '上次训练中有什么值得注意的地方？');
    }

    return questions.take(4).toList();
  }

  /// Build the full system prompt with optional memory context.
  String buildSystemPrompt({List<AiMemoryFile>? memoryFiles}) {
    final buffer = StringBuffer()
      ..writeln('你是一位专业的力量举教练AI助手，名为"电子教练"。')
      ..writeln()
      ..writeln('## 你的核心能力')
      ..writeln('- 精通力量举三大项（深蹲、卧推、硬拉）的训练理论与实践')
      ..writeln('- 理解RPE（自觉用力度）、周期化训练、渐进超负荷等核心概念')
      ..writeln('- 能够分析训练数据，提供个性化的训练建议和计划调整')
      ..writeln('- 了解常见伤病预防和恢复策略')
      ..writeln()
      ..writeln('## 你的沟通风格')
      ..writeln('- 专业但亲和，像一位经验丰富的教练与运动员对话')
      ..writeln('- 注重以数据为依据的建议，不做空泛推测')
      ..writeln('- 回复简洁实用，避免冗长废话')
      ..writeln('- 主动使用markdown格式使回复更清晰')
      ..writeln()
      ..writeln('## 回复规范')
      ..writeln('- 请使用中文回复')
      ..writeln('- 涉及重量时默认使用kg，除非用户指定')
      ..writeln('- 涉及RPE时使用0-10分制')
      ..writeln('- 如果信息不足以给出建议，主动提问获取更多信息');

    if (memoryFiles != null && memoryFiles.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 你的教练记忆');
      for (final file in memoryFiles) {
        if (file.content.trim().isNotEmpty) {
          buffer
            ..writeln()
            ..writeln('### ${file.displayName}')
            ..writeln(file.content);
        }
      }
    }

    return buffer.toString();
  }
}
