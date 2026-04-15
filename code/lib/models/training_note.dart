import '../utils/uid_generator.dart';

// ---------------------------------------------------------------------------
// NoteReference
// ---------------------------------------------------------------------------

class NoteReference {
  final String targetType;
  final String targetUid;

  const NoteReference({
    required this.targetType,
    required this.targetUid,
  });

  Map<String, dynamic> toJson() => {
        'targetType': targetType,
        'targetUid': targetUid,
      };

  factory NoteReference.fromJson(Map<String, dynamic> json) => NoteReference(
        targetType: json['targetType'] as String? ?? '',
        targetUid: json['targetUid'] as String? ?? '',
      );

  NoteReference copyWith({
    String? targetType,
    String? targetUid,
  }) =>
      NoteReference(
        targetType: targetType ?? this.targetType,
        targetUid: targetUid ?? this.targetUid,
      );
}

// ---------------------------------------------------------------------------
// TrainingNote
// ---------------------------------------------------------------------------

class TrainingNote {
  final String uid;
  final String title;
  final String content;
  final String createdAt;
  final String updatedAt;
  final List<NoteReference> references;
  final String? linkedTrainingRecordUid;

  TrainingNote({
    String? uid,
    this.title = '',
    this.content = '',
    String? createdAt,
    String? updatedAt,
    List<NoteReference>? references,
    this.linkedTrainingRecordUid,
  })  : uid = uid ?? UidGenerator.generate(),
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String(),
        references = references ?? const [];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'title': title,
        'content': content,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'references': references.map((r) => r.toJson()).toList(),
        'linkedTrainingRecordUid': linkedTrainingRecordUid,
      };

  factory TrainingNote.fromJson(Map<String, dynamic> json) => TrainingNote(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        references: (json['references'] as List<dynamic>?)
                ?.map((e) =>
                    NoteReference.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        linkedTrainingRecordUid:
            json['linkedTrainingRecordUid'] as String?,
      );

  TrainingNote copyWith({
    String? uid,
    String? title,
    String? content,
    String? createdAt,
    String? updatedAt,
    List<NoteReference>? references,
    String? linkedTrainingRecordUid,
  }) =>
      TrainingNote(
        uid: uid ?? this.uid,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        references: references ?? this.references,
        linkedTrainingRecordUid:
            linkedTrainingRecordUid ?? this.linkedTrainingRecordUid,
      );
}
