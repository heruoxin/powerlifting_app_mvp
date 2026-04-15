import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/exercise_type.dart';
import '../models/plan_models.dart';
import '../models/training_record.dart';
import '../models/training_note.dart';
import '../models/ai_memory.dart';
import '../models/ai_topic.dart';
import '../models/athlete_profile.dart';
import '../models/user_settings.dart';

class StorageService {
  static const String _recordsBox = 'training_records';
  static const String _mesocyclesBox = 'mesocycles';
  static const String _notesBox = 'training_notes';
  static const String _topicsBox = 'ai_topics';
  static const String _memoryBox = 'ai_memory';
  static const String _profilesBox = 'athlete_profiles';
  static const String _settingsBox = 'settings';
  static const String _exerciseTypesBox = 'exercise_types';

  static const String _settingsKey = 'user_settings';
  static const Duration _staleThreshold = Duration(hours: 8);

  // ── Initialization ──

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(_recordsBox),
      Hive.openBox<String>(_mesocyclesBox),
      Hive.openBox<String>(_notesBox),
      Hive.openBox<String>(_topicsBox),
      Hive.openBox<String>(_memoryBox),
      Hive.openBox<String>(_profilesBox),
      Hive.openBox<String>(_settingsBox),
      Hive.openBox<String>(_exerciseTypesBox),
    ]);
  }

  // ── Training Records ──

  Future<List<TrainingRecord>> getAllTrainingRecords() async {
    final box = Hive.box<String>(_recordsBox);
    return box.values.map((json) {
      return TrainingRecord.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<TrainingRecord?> getTrainingRecord(String uid) async {
    final box = Hive.box<String>(_recordsBox);
    final json = box.get(uid);
    if (json == null) return null;
    return TrainingRecord.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  Future<void> saveTrainingRecord(TrainingRecord record) async {
    final box = Hive.box<String>(_recordsBox);
    await box.put(record.uid, jsonEncode(record.toJson()));
  }

  Future<void> deleteTrainingRecord(String uid) async {
    final box = Hive.box<String>(_recordsBox);
    await box.delete(uid);
  }

  TrainingRecord? getActiveTraining() {
    final box = Hive.box<String>(_recordsBox);
    for (final json in box.values) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['state'] == 'in_progress') {
        return TrainingRecord.fromJson(map);
      }
    }
    return null;
  }

  // ── Mesocycles ──

  Future<List<PlanMesocycle>> getAllMesocycles() async {
    final box = Hive.box<String>(_mesocyclesBox);
    return box.values.map((json) {
      return PlanMesocycle.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> saveMesocycle(PlanMesocycle meso) async {
    final box = Hive.box<String>(_mesocyclesBox);
    await box.put(meso.uid, jsonEncode(meso.toJson()));
  }

  Future<void> deleteMesocycle(String uid) async {
    final box = Hive.box<String>(_mesocyclesBox);
    await box.delete(uid);
  }

  // ── Notes ──

  Future<List<TrainingNote>> getAllNotes() async {
    final box = Hive.box<String>(_notesBox);
    return box.values.map((json) {
      return TrainingNote.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> saveNote(TrainingNote note) async {
    final box = Hive.box<String>(_notesBox);
    await box.put(note.uid, jsonEncode(note.toJson()));
  }

  Future<void> deleteNote(String uid) async {
    final box = Hive.box<String>(_notesBox);
    await box.delete(uid);
  }

  // ── AI Topics ──

  Future<List<AiTopic>> getAllTopics() async {
    final box = Hive.box<String>(_topicsBox);
    return box.values.map((json) {
      return AiTopic.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> saveTopic(AiTopic topic) async {
    final box = Hive.box<String>(_topicsBox);
    await box.put(topic.uid, jsonEncode(topic.toJson()));
  }

  Future<void> deleteTopic(String uid) async {
    final box = Hive.box<String>(_topicsBox);
    await box.delete(uid);
  }

  // ── AI Memory ──

  Future<List<AiMemoryFile>> getAllMemoryFiles() async {
    final box = Hive.box<String>(_memoryBox);
    return box.values.map((json) {
      return AiMemoryFile.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> saveMemoryFile(AiMemoryFile file) async {
    final box = Hive.box<String>(_memoryBox);
    await box.put(file.key, jsonEncode(file.toJson()));
  }

  Future<void> initDefaultMemoryFiles() async {
    final box = Hive.box<String>(_memoryBox);
    if (box.isEmpty) {
      for (final file in AiMemoryFile.defaultFiles()) {
        await box.put(file.key, jsonEncode(file.toJson()));
      }
    }
  }

  // ── Athlete Profiles ──

  Future<List<AthleteLiftProfile>> getAllProfiles() async {
    final box = Hive.box<String>(_profilesBox);
    return box.values.map((json) {
      return AthleteLiftProfile.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> saveProfile(AthleteLiftProfile profile) async {
    final box = Hive.box<String>(_profilesBox);
    await box.put(profile.uid, jsonEncode(profile.toJson()));
  }

  // ── Settings ──

  Future<UserSettings> getSettings() async {
    final box = Hive.box<String>(_settingsBox);
    final json = box.get(_settingsKey);
    if (json == null) return const UserSettings();
    return UserSettings.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  Future<void> saveSettings(UserSettings settings) async {
    final box = Hive.box<String>(_settingsBox);
    await box.put(_settingsKey, jsonEncode(settings.toJson()));
  }

  // ── Exercise Types ──

  Future<List<ExerciseType>> getExerciseTypes() async {
    final box = Hive.box<String>(_exerciseTypesBox);
    if (box.isEmpty) {
      await initDefaultExerciseTypes();
    }
    return box.values.map((json) {
      return ExerciseType.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> initDefaultExerciseTypes() async {
    final box = Hive.box<String>(_exerciseTypesBox);
    if (box.isEmpty) {
      for (final type in ExerciseType.defaultExerciseTypes()) {
        await box.put(type.key, jsonEncode(type.toJson()));
      }
    }
  }

  // ── Stale session termination ──

  Future<void> terminateStaleTrainingSessions() async {
    final box = Hive.box<String>(_recordsBox);
    final now = DateTime.now();
    final keysToUpdate = <String>[];

    for (final key in box.keys) {
      final json = box.get(key as String);
      if (json == null) continue;
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['state'] != 'in_progress') continue;

      final startedAt = map['startedAt'] as String?;
      if (startedAt == null) {
        keysToUpdate.add(key);
        continue;
      }
      final started = DateTime.tryParse(startedAt);
      if (started == null || now.difference(started) > _staleThreshold) {
        keysToUpdate.add(key);
      }
    }

    for (final key in keysToUpdate) {
      final json = box.get(key);
      if (json == null) continue;
      final map = jsonDecode(json) as Map<String, dynamic>;
      map['state'] = 'completed';
      map['endedReason'] = 'auto_terminated';
      map['finishedAt'] = now.toIso8601String();
      await box.put(key, jsonEncode(map));
    }
  }
}
