import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/ai_memory.dart';
import '../models/ai_topic.dart';
import '../models/training_record.dart';

class AiService {
  static const String _apiKey = 'AIzaSyAZWpsbwOfL4TB59KuRW7CAWXKObXycJ44';
  static const String _modelName = 'gemini-2.0-flash';
  static const Duration _requestTimeout = Duration(seconds: 30);

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
      final response = await chat
          .sendMessage(Content.text(message))
          .timeout(_requestTimeout);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return '抱歉，AI 没有生成有效回复，请稍后重试。';
      }
      return text;
    } on TimeoutException {
      return '请求超时，AI 服务响应时间过长，请稍后重试。';
    } on GenerativeAIException catch (e) {
      return _handleGenerativeAIError(e);
    } catch (e) {
      return '与AI通信时出错，请稍后再试。(${e.runtimeType}: $e)';
    }
  }

  /// Map GenerativeAIException to user-friendly messages.
  String _handleGenerativeAIError(GenerativeAIException e) {
    final message = e.message;
    if (message.contains('API key')) {
      return 'AI 服务认证失败，请检查网络连接或联系支持。';
    }
    if (message.contains('quota') || message.contains('rate')) {
      return 'AI 服务调用次数已达上限，请稍后再试。';
    }
    if (message.contains('safety') || message.contains('block')) {
      return 'AI 回复因安全策略被拦截，请尝试换一种方式提问。';
    }
    return 'AI 服务异常：$message';
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

  /// Generate a detailed auto-summary after training completion.
  ///
  /// Unlike [generateTrainingSummary] which produces a brief overview, this
  /// method generates a richer narrative suitable for writing into the diary
  /// memory file (日记.md) and for the auto-triggered post-training topic.
  Future<String> generateAutoSummary(TrainingRecord record) async {
    final buffer = StringBuffer()
      ..writeln('你正在执行训练完成后的自动总结任务。')
      ..writeln('请基于以下训练记录，生成一份结构化的教练训练日记条目。')
      ..writeln()
      ..writeln('## 训练基本信息')
      ..writeln('- 日期: ${record.date}')
      ..writeln('- 训练日: ${record.dayLabel ?? record.daySlotLabel}');

    if (record.startedAt != null && record.finishedAt != null) {
      final start = DateTime.tryParse(record.startedAt!);
      final end = DateTime.tryParse(record.finishedAt!);
      if (start != null && end != null) {
        buffer.writeln('- 训练时长: ${end.difference(start).inMinutes}分钟');
      }
    }

    int totalSets = 0;
    int completedSets = 0;
    int skippedSets = 0;
    double totalVolume = 0;
    final rpeValues = <double>[];

    for (final block in record.exerciseBlocks) {
      buffer.writeln('\n### ${block.name} (${block.exerciseCategory})');
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
        buffer.write('- 第${i + 1}组: ${load}kg × ${rep.toInt()}次');
        if (rpe != null) {
          buffer.write(' RPE $rpe');
          rpeValues.add(rpe);
        }
        buffer.writeln(' [${set.state}]');
        totalVolume += load * rep;

        final plan = set.baselinePlan;
        if (plan != null) {
          final planLoad = plan.loadValue?.firstOrNull ?? 0;
          final planRep = plan.rep?.firstOrNull ?? 0;
          if (planLoad > 0 || planRep > 0) {
            buffer.writeln('  计划: ${planLoad}kg × ${planRep.toInt()}次');
          }
        }
      }
    }

    final avgRpe = rpeValues.isNotEmpty
        ? (rpeValues.reduce((a, b) => a + b) / rpeValues.length)
            .toStringAsFixed(1)
        : '无数据';

    buffer
      ..writeln()
      ..writeln('## 统计摘要')
      ..writeln('- 完成组数: $completedSets/$totalSets (跳过$skippedSets组)')
      ..writeln('- 估算总容量: ${totalVolume.toStringAsFixed(0)}kg')
      ..writeln('- 平均RPE: $avgRpe')
      ..writeln()
      ..writeln('## 输出要求')
      ..writeln('请按以下结构输出日记条目（300字以内）：')
      ..writeln('1. **事件摘要**：用2-3句话总结本次训练完成情况')
      ..writeln('2. **关键观察**：指出值得注意的表现亮点或问题')
      ..writeln('3. **计划执行**：对比计划与实际，指出偏差及可能原因')
      ..writeln('4. **RPE与疲劳**：分析强度控制和疲劳信号')
      ..writeln('5. **后续建议**：给出1-2条下次训练前的注意事项')
      ..writeln()
      ..writeln('语气要求：像一位熟悉运动员的教练写给自己的训练笔记，'
          '简洁专业，不说套话。');

    return sendMessage(buffer.toString());
  }

  /// Generate a plan day analysis for a specific training day.
  ///
  /// Explains the design intent and key focuses of a planned training day,
  /// used when the user taps "Ask AI" on the plan page.
  Future<String> generatePlanDayAnalysis(
    String planDayInfo, {
    String? weekContext,
    String? athleteContext,
  }) async {
    final buffer = StringBuffer()
      ..writeln('请基于以下训练日计划，给出教练级别的解读和执行建议。')
      ..writeln()
      ..writeln('## 训练日计划')
      ..writeln(planDayInfo);

    if (weekContext != null) {
      buffer
        ..writeln()
        ..writeln('## 本周上下文')
        ..writeln(weekContext);
    }
    if (athleteContext != null) {
      buffer
        ..writeln()
        ..writeln('## 运动员近况')
        ..writeln(athleteContext);
    }

    buffer
      ..writeln()
      ..writeln('请从以下角度给出分析（200字以内）：')
      ..writeln('1. **设计意图**：这个训练日在周期中的定位和目的')
      ..writeln('2. **重点动作**：哪些动作是今天的核心，需要重点对待')
      ..writeln('3. **强度建议**：重量选择和RPE目标的执行要点')
      ..writeln('4. **执行提示**：热身要点、组间休息、注意事项');

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

  /// Generate a structured coaching observation for the 教练观察.md memory file.
  ///
  /// Unlike [generateCoachObservation] which produces a brief summary for the
  /// user, this generates a structured observation matching the memory file
  /// template for long-term coaching insights.
  Future<String> generateCoachObservationForMemory(
    String recentData, {
    String? existingObservation,
  }) async {
    final buffer = StringBuffer()
      ..writeln('你正在执行教练观察更新任务。')
      ..writeln('请基于以下近期训练数据，生成或更新教练观察记录。')
      ..writeln()
      ..writeln('## 近期训练数据')
      ..writeln(recentData);

    if (existingObservation != null && existingObservation.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 已有教练观察')
        ..writeln(existingObservation);
    }

    buffer
      ..writeln()
      ..writeln('## 输出要求')
      ..writeln('请按以下结构输出（300字以内）：')
      ..writeln('1. **当前阶段判断**：运动员当前整体状态评估')
      ..writeln('2. **近期趋势**：主项表现、疲劳、执行质量的变化方向')
      ..writeln('3. **已确认观察**：有数据支撑的结论')
      ..writeln('4. **待验证假设**：需要更多训练数据验证的判断')
      ..writeln('5. **当前风险点**：近期需重点关注的问题')
      ..writeln('6. **接下来关注点**：下阶段观察重点')
      ..writeln()
      ..writeln('语气要求：像教练的内部工作笔记，简洁、有判断、有依据。');

    return sendMessage(buffer.toString());
  }

  /// Generate suggested questions for a new AI topic.
  List<String> generateSuggestedQuestions({
    String? currentPlanContext,
    String? recentTrainingContext,
  }) {
    final questions = <String>[];

    if (currentPlanContext != null && currentPlanContext.isNotEmpty) {
      questions.add('帮我解读一下「$currentPlanContext」的设计思路');
      questions.add('当前计划的强度安排合理吗？');
    }

    if (recentTrainingContext != null && recentTrainingContext.isNotEmpty) {
      questions.add('帮我分析一下上次训练的表现');
      questions.add('最近的RPE偏高，是不是该减载了？');
    }

    // Default questions when no context is available
    if (questions.isEmpty) {
      questions.addAll([
        '帮我分析一下最近的训练表现',
        '我的三大项强度进展怎么样？',
        '当前训练计划需要调整吗？',
      ]);
    }

    // Always include a general coaching question
    if (questions.length < 4) {
      questions.add('有什么恢复和疲劳管理的建议？');
    }

    return questions.take(4).toList();
  }

  /// Build the full system prompt with optional memory context.
  String buildSystemPrompt({List<AiMemoryFile>? memoryFiles}) {
    final buffer = StringBuffer()
      ..writeln('你是一位专业的力量举教练AI助手，名为"电子教练"。')
      ..writeln()
      ..writeln('## 你的核心定位')
      ..writeln('你是运动员的长期教练，不是一次性问答机器人。')
      ..writeln('你应基于持续积累的训练数据和记忆来理解运动员，'
          '给出的每一条建议都应建立在真实记录之上。')
      ..writeln()
      ..writeln('## 你的核心能力')
      ..writeln('- 精通力量举三大项（深蹲、卧推、硬拉）的训练理论与实践')
      ..writeln('- 理解RPE（自觉用力度）、周期化训练、渐进超负荷等核心概念')
      ..writeln('- 能够分析训练数据，提供个性化的训练建议和计划调整')
      ..writeln('- 了解常见伤病预防和恢复策略')
      ..writeln('- 能够拆解复杂问题，分步骤收集信息后再给出综合建议')
      ..writeln()
      ..writeln('## 你的工作原则')
      ..writeln('- 优先长期进步，不追求短期冲击')
      ..writeln('- 优先给出可执行的具体建议，而非泛泛而谈')
      ..writeln('- 始终基于运动员的真实训练记录做判断')
      ..writeln('- 不擅自修改已结束的训练记录')
      ..writeln('- 计划修改建议需用户确认后才生效')
      ..writeln('- 信息不足时主动提问，而非凭空推测')
      ..writeln()
      ..writeln('## 你的沟通风格')
      ..writeln('- 专业但亲和，像一位经验丰富的教练与运动员面对面交流')
      ..writeln('- 语言简洁有力，不说空话套话')
      ..writeln('- 对不熟悉的概念主动用通俗语言解释')
      ..writeln('- 善用数据对比（计划vs实际、本周vs上周）来说明问题')
      ..writeln('- 主动使用markdown格式使回复层次清晰')
      ..writeln()
      ..writeln('## 回复规范')
      ..writeln('- 请使用中文回复')
      ..writeln('- 涉及重量时默认使用kg，除非用户指定')
      ..writeln('- 涉及RPE时使用0-10分制')
      ..writeln('- 如果信息不足以给出建议，主动提问获取更多信息')
      ..writeln('- 避免超长回复，除非用户要求详细分析');

    if (memoryFiles != null && memoryFiles.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 你的教练记忆')
        ..writeln('以下是你对这位运动员的持续记忆，请结合这些信息回答问题：');
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
