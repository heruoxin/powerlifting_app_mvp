import '../utils/uid_generator.dart';

// ---------------------------------------------------------------------------
// PrSnapshot
// ---------------------------------------------------------------------------

class PrSnapshot {
  final double value;
  final String unit;
  final String date;
  final String source;

  const PrSnapshot({
    required this.value,
    this.unit = 'kg',
    required this.date,
    this.source = 'actual',
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'unit': unit,
        'date': date,
        'source': source,
      };

  factory PrSnapshot.fromJson(Map<String, dynamic> json) => PrSnapshot(
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? 'kg',
        date: json['date'] as String? ?? '',
        source: json['source'] as String? ?? 'actual',
      );

  PrSnapshot copyWith({
    double? value,
    String? unit,
    String? date,
    String? source,
  }) =>
      PrSnapshot(
        value: value ?? this.value,
        unit: unit ?? this.unit,
        date: date ?? this.date,
        source: source ?? this.source,
      );
}

// ---------------------------------------------------------------------------
// E1rmHistoryEntry
// ---------------------------------------------------------------------------

class E1rmHistoryEntry {
  final double value;
  final String date;
  final String source;

  const E1rmHistoryEntry({
    required this.value,
    required this.date,
    this.source = 'actual',
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'date': date,
        'source': source,
      };

  factory E1rmHistoryEntry.fromJson(Map<String, dynamic> json) =>
      E1rmHistoryEntry(
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        date: json['date'] as String? ?? '',
        source: json['source'] as String? ?? 'actual',
      );

  E1rmHistoryEntry copyWith({
    double? value,
    String? date,
    String? source,
  }) =>
      E1rmHistoryEntry(
        value: value ?? this.value,
        date: date ?? this.date,
        source: source ?? this.source,
      );
}

// ---------------------------------------------------------------------------
// AthleteLiftProfile
// ---------------------------------------------------------------------------

class AthleteLiftProfile {
  final String uid;
  final String liftKey;
  final String displayName;
  final double? currentE1rm;
  final String e1rmUnit;
  final String? e1rmUpdatedAt;
  final List<PrSnapshot> prSnapshots;
  final List<E1rmHistoryEntry> history;

  AthleteLiftProfile({
    String? uid,
    required this.liftKey,
    required this.displayName,
    this.currentE1rm,
    this.e1rmUnit = 'kg',
    this.e1rmUpdatedAt,
    List<PrSnapshot>? prSnapshots,
    List<E1rmHistoryEntry>? history,
  })  : uid = uid ?? UidGenerator.generate(),
        prSnapshots = prSnapshots ?? const [],
        history = history ?? const [];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'liftKey': liftKey,
        'displayName': displayName,
        'currentE1rm': currentE1rm,
        'e1rmUnit': e1rmUnit,
        'e1rmUpdatedAt': e1rmUpdatedAt,
        'prSnapshots': prSnapshots.map((p) => p.toJson()).toList(),
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory AthleteLiftProfile.fromJson(Map<String, dynamic> json) =>
      AthleteLiftProfile(
        uid: json['uid'] as String? ?? UidGenerator.generate(),
        liftKey: json['liftKey'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        currentE1rm: (json['currentE1rm'] as num?)?.toDouble(),
        e1rmUnit: json['e1rmUnit'] as String? ?? 'kg',
        e1rmUpdatedAt: json['e1rmUpdatedAt'] as String?,
        prSnapshots: (json['prSnapshots'] as List<dynamic>?)
                ?.map(
                    (e) => PrSnapshot.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        history: (json['history'] as List<dynamic>?)
                ?.map((e) =>
                    E1rmHistoryEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  AthleteLiftProfile copyWith({
    String? uid,
    String? liftKey,
    String? displayName,
    double? currentE1rm,
    String? e1rmUnit,
    String? e1rmUpdatedAt,
    List<PrSnapshot>? prSnapshots,
    List<E1rmHistoryEntry>? history,
  }) =>
      AthleteLiftProfile(
        uid: uid ?? this.uid,
        liftKey: liftKey ?? this.liftKey,
        displayName: displayName ?? this.displayName,
        currentE1rm: currentE1rm ?? this.currentE1rm,
        e1rmUnit: e1rmUnit ?? this.e1rmUnit,
        e1rmUpdatedAt: e1rmUpdatedAt ?? this.e1rmUpdatedAt,
        prSnapshots: prSnapshots ?? this.prSnapshots,
        history: history ?? this.history,
      );
}
