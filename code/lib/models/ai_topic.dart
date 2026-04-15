import '../utils/uid_generator.dart';

// ---------------------------------------------------------------------------
// ToolCallTrace
// ---------------------------------------------------------------------------

class ToolCallTrace {
  final String toolName;
  final String source;
  final String? summary;
  final String? timestamp;

  const ToolCallTrace({
    required this.toolName,
    this.source = 'local',
    this.summary,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'toolName': toolName,
        'source': source,
        'summary': summary,
        'timestamp': timestamp,
      };

  factory ToolCallTrace.fromJson(Map<String, dynamic> json) => ToolCallTrace(
        toolName: json['toolName'] as String? ?? '',
        source: json['source'] as String? ?? 'local',
        summary: json['summary'] as String?,
        timestamp: json['timestamp'] as String?,
      );

  ToolCallTrace copyWith({
    String? toolName,
    String? source,
    String? summary,
    String? timestamp,
  }) =>
      ToolCallTrace(
        toolName: toolName ?? this.toolName,
        source: source ?? this.source,
        summary: summary ?? this.summary,
        timestamp: timestamp ?? this.timestamp,
      );
}

// ---------------------------------------------------------------------------
// ContextReference
// ---------------------------------------------------------------------------

class ContextReference {
  final String type;
  final String? targetUid;
  final String? displayLabel;
  final String? previewText;

  const ContextReference({
    required this.type,
    this.targetUid,
    this.displayLabel,
    this.previewText,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'targetUid': targetUid,
        'displayLabel': displayLabel,
        'previewText': previewText,
      };

  factory ContextReference.fromJson(Map<String, dynamic> json) =>
      ContextReference(
        type: json['type'] as String? ?? '',
        targetUid: json['targetUid'] as String?,
        displayLabel: json['displayLabel'] as String?,
        previewText: json['previewText'] as String?,
      );

  ContextReference copyWith({
    String? type,
    String? targetUid,
    String? displayLabel,
    String? previewText,
  }) =>
      ContextReference(
        type: type ?? this.type,
        targetUid: targetUid ?? this.targetUid,
        displayLabel: displayLabel ?? this.displayLabel,
        previewText: previewText ?? this.previewText,
      );
}

// ---------------------------------------------------------------------------
// AiMessage
// ---------------------------------------------------------------------------

class AiMessage {
  final String uid;
  final String role;
  final String content;
  final String createdAt;
  final List<ToolCallTrace> toolCalls;
  final List<String> attachments;

  AiMessage({
    String? uid,
    required this.role,
    this.content = '',
    String? createdAt,
    List<ToolCallTrace>? toolCalls,
    List<String>? attachments,
  })  : uid = uid ?? UidGenerator.generate(),
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        toolCalls = toolCalls ?? const [],
        attachments = attachments ?? const [];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'role': role,
        'content': content,
        'createdAt': createdAt,
        'toolCalls': toolCalls.map((t) => t.toJson()).toList(),
        'attachments': attachments,
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        role: json['role'] as String? ?? 'user',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
        toolCalls: (json['toolCalls'] as List<dynamic>?)
                ?.map((e) =>
                    ToolCallTrace.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        attachments: (json['attachments'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );

  AiMessage copyWith({
    String? uid,
    String? role,
    String? content,
    String? createdAt,
    List<ToolCallTrace>? toolCalls,
    List<String>? attachments,
  }) =>
      AiMessage(
        uid: uid ?? this.uid,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        toolCalls: toolCalls ?? this.toolCalls,
        attachments: attachments ?? this.attachments,
      );
}

// ---------------------------------------------------------------------------
// AiTopic
// ---------------------------------------------------------------------------

class AiTopic {
  final String uid;
  final String title;
  final String createdAt;
  final String updatedAt;
  final String lastActiveAt;
  final String category;
  final bool isAutoTriggered;
  final String? triggerSource;
  final List<AiMessage> messages;
  final List<ContextReference> contextReferences;

  AiTopic({
    String? uid,
    this.title = '',
    String? createdAt,
    String? updatedAt,
    String? lastActiveAt,
    this.category = 'recent',
    this.isAutoTriggered = false,
    this.triggerSource,
    List<AiMessage>? messages,
    List<ContextReference>? contextReferences,
  })  : uid = uid ?? UidGenerator.generate(),
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String(),
        lastActiveAt = lastActiveAt ?? DateTime.now().toIso8601String(),
        messages = messages ?? const [],
        contextReferences = contextReferences ?? const [];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'title': title,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'lastActiveAt': lastActiveAt,
        'category': category,
        'isAutoTriggered': isAutoTriggered,
        'triggerSource': triggerSource,
        'messages': messages.map((m) => m.toJson()).toList(),
        'contextReferences':
            contextReferences.map((c) => c.toJson()).toList(),
      };

  factory AiTopic.fromJson(Map<String, dynamic> json) => AiTopic(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        title: json['title'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        lastActiveAt: json['lastActiveAt'] as String?,
        category: json['category'] as String? ?? 'recent',
        isAutoTriggered: json['isAutoTriggered'] as bool? ?? false,
        triggerSource: json['triggerSource'] as String?,
        messages: (json['messages'] as List<dynamic>?)
                ?.map(
                    (e) => AiMessage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        contextReferences: (json['contextReferences'] as List<dynamic>?)
                ?.map((e) =>
                    ContextReference.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  AiTopic copyWith({
    String? uid,
    String? title,
    String? createdAt,
    String? updatedAt,
    String? lastActiveAt,
    String? category,
    bool? isAutoTriggered,
    String? triggerSource,
    List<AiMessage>? messages,
    List<ContextReference>? contextReferences,
  }) =>
      AiTopic(
        uid: uid ?? this.uid,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        category: category ?? this.category,
        isAutoTriggered: isAutoTriggered ?? this.isAutoTriggered,
        triggerSource: triggerSource ?? this.triggerSource,
        messages: messages ?? this.messages,
        contextReferences: contextReferences ?? this.contextReferences,
      );
}
