import 'package:flutter/foundation.dart';

import '../models/ai_memory.dart';
import '../models/ai_topic.dart';
import '../models/athlete_profile.dart';
import '../models/exercise_type.dart';
import '../models/plan_models.dart';
import '../models/training_note.dart';
import '../models/training_record.dart';
import '../models/user_settings.dart';
import '../services/ai_service.dart';
import '../services/demo_data_service.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AiService _aiService = AiService();

  // ── State ──
  UserSettings settings = const UserSettings();
  List<TrainingRecord> trainingRecords = [];
  List<PlanMesocycle> mesocycles = [];
  List<TrainingNote> notes = [];
  List<AiTopic> topics = [];
  List<AiMemoryFile> memoryFiles = [];
  List<AthleteLiftProfile> profiles = [];
  List<ExerciseType> exerciseTypes = [];

  TrainingRecord? activeTraining;
  int currentTabIndex = 0;
  bool isLoading = true;

  // ── Initialization ──

  Future<void> init() async {
    await StorageService.init();
    _aiService.init();
    await _storage.terminateStaleTrainingSessions();
    await _loadAllData();

    if (mesocycles.isEmpty) {
      await _seedDemoData();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAllData() async {
    final results = await Future.wait([
      _storage.getAllTrainingRecords(),
      _storage.getAllMesocycles(),
      _storage.getAllNotes(),
      _storage.getAllTopics(),
      _storage.getAllMemoryFiles(),
      _storage.getAllProfiles(),
      _storage.getSettings(),
      _storage.getExerciseTypes(),
    ]);

    trainingRecords = results[0] as List<TrainingRecord>;
    mesocycles = results[1] as List<PlanMesocycle>;
    notes = results[2] as List<TrainingNote>;
    topics = results[3] as List<AiTopic>;
    memoryFiles = results[4] as List<AiMemoryFile>;
    profiles = results[5] as List<AthleteLiftProfile>;
    settings = results[6] as UserSettings;
    exerciseTypes = results[7] as List<ExerciseType>;

    activeTraining = _storage.getActiveTraining();

    if (memoryFiles.isEmpty) {
      await _storage.initDefaultMemoryFiles();
      memoryFiles = await _storage.getAllMemoryFiles();
    }
  }

  Future<void> _seedDemoData() async {
    final meso = DemoDataService.generateDemoMesocycle();
    final records = DemoDataService.generateDemoRecords(meso);
    final demoProfiles = DemoDataService.generateDemoProfiles();
    final demoNotes = DemoDataService.generateDemoNotes();
    final demoTopic = DemoDataService.generateDemoTopic();
    final demoSettings = DemoDataService.generateDemoSettings();

    await _storage.saveMesocycle(meso);
    for (final r in records) {
      await _storage.saveTrainingRecord(r);
    }
    for (final p in demoProfiles) {
      await _storage.saveProfile(p);
    }
    for (final n in demoNotes) {
      await _storage.saveNote(n);
    }
    await _storage.saveTopic(demoTopic);
    await _storage.saveSettings(demoSettings);

    mesocycles = [meso];
    trainingRecords = records;
    profiles = demoProfiles;
    notes = demoNotes;
    topics = [demoTopic];
    settings = demoSettings;
  }

  // ── Training Lifecycle ──

  Future<void> startTraining({
    PlanDay? planDay,
    PlanMesocycle? mesocycle,
  }) async {
    // Don't allow starting a new training if one is active
    if (activeTraining != null) return;

    final blocks = <ExerciseBlock>[];

    if (planDay != null) {
      for (final item in planDay.exerciseItems) {
        // Find display name from exercise types catalog
        final exerciseType = exerciseTypes
            .where((et) => et.key == item.exerciseTypeKey)
            .firstOrNull;
        final displayName = item.displayNameOverride ??
            exerciseType?.displayName ??
            item.exerciseTypeKey;

        final sets = item.sets.map((ps) {
          SetValues? baseline;
          final t = ps.target;

          if (t.load.value != null || t.rep.value != null) {
            baseline = SetValues(
              loadValue: t.load.value,
              loadUnit: t.load.unit,
              rep: t.rep.value,
            );
          } else if (t.duration.value != null) {
            baseline = SetValues(
              duration: t.duration.value,
              durationUnit: t.duration.unit,
            );
          } else if (t.distance.value != null) {
            baseline = SetValues(
              distance: t.distance.value,
              distanceUnit: t.distance.unit,
              duration: t.duration.value,
              durationUnit: t.duration.unit,
            );
          }

          return TrainingSet(
            state: 'pending',
            sourceType: 'planned',
            baselinePlan: baseline,
            workingPlan: baseline,
          );
        }).toList();

        blocks.add(ExerciseBlock(
          name: displayName,
          exerciseCategory: _categoryLabel(item.exerciseTypeKey),
          sourceType: 'planned',
          displayColumns: _displayCols(item.recordProfileKey),
          sets: sets,
        ));
      }
    }

    // Determine slot label: for open sessions, generate OS1, OS2, etc.
    String slotLabel;
    if (planDay != null) {
      slotLabel = planDay.label;
    } else {
      final osCount = trainingRecords
              .where((r) => r.daySlotLabel.startsWith('OS'))
              .length +
          1;
      slotLabel = 'OS$osCount';
    }

    final record = TrainingRecord(
      state: 'in_progress',
      dayLabel: planDay?.dayTitle ?? (planDay == null ? '自由训练' : null),
      daySlotLabel: slotLabel,
      sourcePlanDayUid: planDay?.uid,
      startedAt: DateTime.now().toIso8601String(),
      exerciseBlocks: blocks,
    );

    await _storage.saveTrainingRecord(record);
    activeTraining = record;
    trainingRecords = await _storage.getAllTrainingRecords();
    notifyListeners();
  }

  Future<void> completeSet(
    String blockUid,
    String setUid,
    SetValues actual,
    EffortMetrics? effort,
  ) async {
    if (activeTraining == null) return;

    final updatedBlocks = activeTraining!.exerciseBlocks.map((block) {
      if (block.uid != blockUid) return block;
      final updatedSets = block.sets.map((s) {
        if (s.uid != setUid) return s;
        return s.copyWith(
          state: 'completed',
          actual: actual,
          effortMetrics: effort,
          finishedAt: DateTime.now().toIso8601String(),
        );
      }).toList();
      return block.copyWith(sets: updatedSets);
    }).toList();

    activeTraining = activeTraining!.copyWith(exerciseBlocks: updatedBlocks);
    await _storage.saveTrainingRecord(activeTraining!);
    notifyListeners();
  }

  Future<void> skipSet(String blockUid, String setUid) async {
    if (activeTraining == null) return;

    final updatedBlocks = activeTraining!.exerciseBlocks.map((block) {
      if (block.uid != blockUid) return block;
      final updatedSets = block.sets.map((s) {
        if (s.uid != setUid) return s;
        return s.copyWith(state: 'skipped');
      }).toList();
      return block.copyWith(sets: updatedSets);
    }).toList();

    activeTraining = activeTraining!.copyWith(exerciseBlocks: updatedBlocks);
    await _storage.saveTrainingRecord(activeTraining!);
    notifyListeners();
  }

  Future<void> finishTraining() async {
    if (activeTraining == null) return;

    activeTraining = activeTraining!.copyWith(
      state: 'completed',
      endedReason: 'user_finished',
      finishedAt: DateTime.now().toIso8601String(),
    );

    await _storage.saveTrainingRecord(activeTraining!);
    activeTraining = null;
    trainingRecords = await _storage.getAllTrainingRecords();
    notifyListeners();
  }

  Future<void> addExerciseToActiveTraining(ExerciseType type) async {
    if (activeTraining == null) return;

    final newSet = TrainingSet(state: 'pending', sourceType: 'free_form');

    final block = ExerciseBlock(
      name: type.displayName,
      exerciseCategory: type.category,
      sourceType: 'free_form',
      displayColumns: _displayCols(type.recordProfileKey),
      sets: [newSet],
    );

    final blocks = [...activeTraining!.exerciseBlocks, block];
    activeTraining = activeTraining!.copyWith(exerciseBlocks: blocks);
    await _storage.saveTrainingRecord(activeTraining!);
    notifyListeners();
  }

  Future<void> addSetToBlock(String blockUid) async {
    if (activeTraining == null) return;

    final updatedBlocks = activeTraining!.exerciseBlocks.map((block) {
      if (block.uid != blockUid) return block;
      final newSet = TrainingSet(state: 'pending', sourceType: block.sourceType);
      return block.copyWith(sets: [...block.sets, newSet]);
    }).toList();

    activeTraining = activeTraining!.copyWith(exerciseBlocks: updatedBlocks);
    await _storage.saveTrainingRecord(activeTraining!);
    notifyListeners();
  }

  // ── Plan Management ──

  Future<void> saveMesocycle(PlanMesocycle meso) async {
    final updated = meso.copyWith(updatedAt: DateTime.now().toIso8601String());
    await _storage.saveMesocycle(updated);
    mesocycles = await _storage.getAllMesocycles();
    notifyListeners();
  }

  Future<void> deleteMesocycle(String uid) async {
    await _storage.deleteMesocycle(uid);
    mesocycles = await _storage.getAllMesocycles();
    notifyListeners();
  }

  // ── Notes ──

  Future<void> addNote(TrainingNote note) async {
    await _storage.saveNote(note);
    notes = await _storage.getAllNotes();
    notifyListeners();
  }

  Future<void> updateNote(TrainingNote note) async {
    final updated = note.copyWith(updatedAt: DateTime.now().toIso8601String());
    await _storage.saveNote(updated);
    notes = await _storage.getAllNotes();
    notifyListeners();
  }

  Future<void> deleteNote(String uid) async {
    await _storage.deleteNote(uid);
    notes = await _storage.getAllNotes();
    notifyListeners();
  }

  // ── AI Chat ──

  Future<String> sendAiMessage(String topicUid, String message) async {
    final topicIndex = topics.indexWhere((t) => t.uid == topicUid);
    if (topicIndex == -1) return '话题未找到';

    var topic = topics[topicIndex];

    final userMsg = AiMessage(role: 'user', content: message);
    topic = topic.copyWith(
      messages: [...topic.messages, userMsg],
      updatedAt: DateTime.now().toIso8601String(),
      lastActiveAt: DateTime.now().toIso8601String(),
    );

    // Build memory-enriched system prompt
    final systemPrompt =
        _aiService.buildSystemPrompt(memoryFiles: memoryFiles);

    final response = await _aiService.sendMessage(
      message,
      history: topic.messages,
      systemPrompt: systemPrompt,
    );

    final assistantMsg = AiMessage(role: 'assistant', content: response);
    topic = topic.copyWith(
      messages: [...topic.messages, assistantMsg],
      updatedAt: DateTime.now().toIso8601String(),
      lastActiveAt: DateTime.now().toIso8601String(),
    );

    await _storage.saveTopic(topic);
    topics[topicIndex] = topic;
    notifyListeners();
    return response;
  }

  /// Generate an AI training summary and return it.
  Future<String> generateTrainingSummary(TrainingRecord record) async {
    return _aiService.generateTrainingSummary(record);
  }

  /// Get suggested questions for a new topic.
  List<String> getSuggestedQuestions() {
    return _aiService.generateSuggestedQuestions(
      currentPlanContext:
          mesocycles.isNotEmpty ? mesocycles.first.name : null,
      recentTrainingContext:
          trainingRecords.isNotEmpty ? 'has_records' : null,
    );
  }

  Future<AiTopic> createNewTopic({
    String? title,
    List<ContextReference>? refs,
  }) async {
    final topic = AiTopic(
      title: title ?? '新对话',
      contextReferences: refs ?? const [],
    );
    await _storage.saveTopic(topic);
    topics = await _storage.getAllTopics();
    notifyListeners();
    return topic;
  }

  Future<void> deleteTopic(String uid) async {
    await _storage.deleteTopic(uid);
    topics = await _storage.getAllTopics();
    notifyListeners();
  }

  // ── Memory ──

  Future<void> updateMemoryFile(AiMemoryFile file) async {
    final updated = file.copyWith(
      lastUpdatedAt: DateTime.now().toIso8601String(),
    );
    await _storage.saveMemoryFile(updated);
    memoryFiles = await _storage.getAllMemoryFiles();
    notifyListeners();
  }

  // ── Profiles ──

  Future<void> saveProfile(AthleteLiftProfile profile) async {
    await _storage.saveProfile(profile);
    profiles = await _storage.getAllProfiles();
    notifyListeners();
  }

  // ── Settings ──

  Future<void> updateSettings(UserSettings newSettings) async {
    settings = newSettings;
    await _storage.saveSettings(newSettings);
    notifyListeners();
  }

  // ── Helpers ──

  PlanDay? getNextPlanDay() {
    for (final meso in mesocycles) {
      if (meso.status != 'active') continue;
      for (final micro in meso.microcycles) {
        if (micro.status == 'completed') continue;
        for (final day in micro.days) {
          final hasRecord = trainingRecords.any(
            (r) => r.sourcePlanDayUid == day.uid && r.state == 'completed',
          );
          if (!hasRecord) return day;
        }
      }
    }
    return null;
  }

  PlanDay? getPlanDayByUid(String uid) {
    for (final meso in mesocycles) {
      for (final micro in meso.microcycles) {
        for (final day in micro.days) {
          if (day.uid == uid) return day;
        }
      }
    }
    return null;
  }

  List<TrainingRecord> getRecordsForWeek(int weekIndex) {
    return trainingRecords.where((r) => r.weekIndex == weekIndex).toList();
  }

  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  // ── Private helpers ──

  static String _categoryLabel(String exerciseTypeKey) {
    const mainLifts = {'squat', 'bench_press', 'deadlift'};
    const variants = {
      'pause_squat', 'close_grip_bench', 'sumo_deadlift', 'front_squat'
    };
    if (mainLifts.contains(exerciseTypeKey)) return '主项';
    if (variants.contains(exerciseTypeKey)) return '主项变式';
    return '辅助项';
  }

  static List<String> _displayCols(String profileKey) {
    switch (profileKey) {
      case 'timed_hold_profile':
        return ['duration'];
      case 'bodyweight_reps_profile':
        return ['rep'];
      case 'distance_time_cardio_profile':
        return ['duration', 'distance'];
      default:
        return ['load', 'rep'];
    }
  }
}
