class AiMemoryFile {
  final String key;
  final String displayName;
  final String content;
  final String lastUpdatedAt;
  final bool isEditable;

  AiMemoryFile({
    required this.key,
    required this.displayName,
    this.content = '',
    String? lastUpdatedAt,
    this.isEditable = true,
  }) : lastUpdatedAt = lastUpdatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
        'key': key,
        'displayName': displayName,
        'content': content,
        'lastUpdatedAt': lastUpdatedAt,
        'isEditable': isEditable,
      };

  factory AiMemoryFile.fromJson(Map<String, dynamic> json) => AiMemoryFile(
        key: json['key'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        content: json['content'] as String? ?? '',
        lastUpdatedAt: json['lastUpdatedAt'] as String?,
        isEditable: json['isEditable'] as bool? ?? true,
      );

  AiMemoryFile copyWith({
    String? key,
    String? displayName,
    String? content,
    String? lastUpdatedAt,
    bool? isEditable,
  }) =>
      AiMemoryFile(
        key: key ?? this.key,
        displayName: displayName ?? this.displayName,
        content: content ?? this.content,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        isEditable: isEditable ?? this.isEditable,
      );

  /// Returns the 5 default AI memory files with initial content.
  /// The 'soul' file is read-only (isEditable: false) as it defines the
  /// core AI persona and should not be modified by the user.
  static List<AiMemoryFile> defaultFiles() {
    final now = DateTime.now().toIso8601String();
    return [
      AiMemoryFile(
        key: 'soul',
        displayName: '灵魂设定',
        content: '# 灵魂设定\n\n'
            '你是一位专业的力量举教练AI助手。\n'
            '你的目标是帮助运动员科学地提升深蹲、卧推和硬拉的成绩。\n'
            '你应该根据运动员的实际情况提供个性化的训练建议。',
        lastUpdatedAt: now,
        isEditable: false,
      ),
      AiMemoryFile(
        key: 'training_plan',
        displayName: '训练计划记忆',
        content: '# 训练计划记忆\n\n暂无训练计划记录。',
        lastUpdatedAt: now,
        isEditable: true,
      ),
      AiMemoryFile(
        key: 'user_traits',
        displayName: '用户特征',
        content: '# 用户特征\n\n暂无用户特征记录。',
        lastUpdatedAt: now,
        isEditable: true,
      ),
      AiMemoryFile(
        key: 'coach_observation',
        displayName: '教练观察',
        content: '# 教练观察\n\n暂无教练观察记录。',
        lastUpdatedAt: now,
        isEditable: true,
      ),
      AiMemoryFile(
        key: 'diary',
        displayName: '训练日记',
        content: '# 训练日记\n\n暂无训练日记。',
        lastUpdatedAt: now,
        isEditable: true,
      ),
    ];
  }
}
