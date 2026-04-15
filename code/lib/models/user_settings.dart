class UserSettings {
  final String? userName;
  final int preferredWeeklyFrequency;
  final String defaultWeightUnit;
  final String language;
  final double tokenBalance;
  final double tokenSpentRecent;
  final Map<String, bool> autoTriggerSettings;

  const UserSettings({
    this.userName,
    this.preferredWeeklyFrequency = 4,
    this.defaultWeightUnit = 'kg',
    this.language = 'zh-CN',
    this.tokenBalance = 0.0,
    this.tokenSpentRecent = 0.0,
    Map<String, bool>? autoTriggerSettings,
  }) : autoTriggerSettings = autoTriggerSettings ?? const {};

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'preferredWeeklyFrequency': preferredWeeklyFrequency,
        'defaultWeightUnit': defaultWeightUnit,
        'language': language,
        'tokenBalance': tokenBalance,
        'tokenSpentRecent': tokenSpentRecent,
        'autoTriggerSettings':
            Map<String, dynamic>.from(autoTriggerSettings),
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        userName: json['userName'] as String?,
        preferredWeeklyFrequency:
            json['preferredWeeklyFrequency'] as int? ?? 4,
        defaultWeightUnit:
            json['defaultWeightUnit'] as String? ?? 'kg',
        language: json['language'] as String? ?? 'zh-CN',
        tokenBalance:
            (json['tokenBalance'] as num?)?.toDouble() ?? 0.0,
        tokenSpentRecent:
            (json['tokenSpentRecent'] as num?)?.toDouble() ?? 0.0,
        autoTriggerSettings:
            (json['autoTriggerSettings'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, v as bool)) ??
                const {},
      );

  UserSettings copyWith({
    String? userName,
    int? preferredWeeklyFrequency,
    String? defaultWeightUnit,
    String? language,
    double? tokenBalance,
    double? tokenSpentRecent,
    Map<String, bool>? autoTriggerSettings,
  }) =>
      UserSettings(
        userName: userName ?? this.userName,
        preferredWeeklyFrequency:
            preferredWeeklyFrequency ?? this.preferredWeeklyFrequency,
        defaultWeightUnit: defaultWeightUnit ?? this.defaultWeightUnit,
        language: language ?? this.language,
        tokenBalance: tokenBalance ?? this.tokenBalance,
        tokenSpentRecent: tokenSpentRecent ?? this.tokenSpentRecent,
        autoTriggerSettings:
            autoTriggerSettings ?? this.autoTriggerSettings,
      );
}
