import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ai_topic.dart';
import '../../models/training_note.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

/// Full-screen note editor for creating and editing user training notes.
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, this.note});

  final TrainingNote? note;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  TrainingNote? _currentNote;
  bool _hasChanges = false;

  bool get _isNew => _currentNote == null;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<TrainingNote?> _persist({bool popAfterSave = false}) async {
    final appState = context.read<AppState>();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      if (popAfterSave && mounted) {
        Navigator.of(context).pop();
      }
      return null;
    }

    late TrainingNote note;
    if (_isNew) {
      note = TrainingNote(title: title, content: content);
      await appState.addNote(note);
    } else {
      note = _currentNote!.copyWith(title: title, content: content);
      await appState.updateNote(note);
    }

    if (mounted) {
      setState(() {
        _currentNote = note;
        _hasChanges = false;
      });
      if (popAfterSave) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已保存笔记')));
      }
    }
    return note;
  }

  Future<void> _save() async {
    await _persist(popAfterSave: true);
  }

  Future<void> _delete() async {
    if (_isNew) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除笔记'),
        content: const Text('确定要删除这条笔记吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final appState = context.read<AppState>();
      await appState.deleteNote(_currentNote!.uid);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('未保存的更改'),
          content: const Text('你有未保存的更改，是否保存？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: const Text('放弃'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('保存'),
            ),
          ],
        ),
      );

      if (result == 'save') {
        await _persist(popAfterSave: true);
        return false; // Already popped in _save
      }
      return result == 'discard';
    }
    return true;
  }

  Future<void> _askAi() async {
    final appState = context.read<AppState>();
    final savedNote = await _persist();
    if (savedNote == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请先输入一些笔记内容')));
      }
      return;
    }

    final refs = [
      ContextReference(
        type: 'note',
        targetUid: savedNote.uid,
        displayLabel: savedNote.title.isNotEmpty ? savedNote.title : '训练笔记',
        previewText: _preview(savedNote.content),
      ),
      if (savedNote.linkedTrainingRecordUid != null &&
          appState.getTrainingRecordByUid(savedNote.linkedTrainingRecordUid!) !=
              null)
        ContextReference(
          type: 'training_record',
          targetUid: savedNote.linkedTrainingRecordUid,
          displayLabel: appState.trainingRecordLabel(
            appState.getTrainingRecordByUid(
              savedNote.linkedTrainingRecordUid!,
            )!,
          ),
        ),
    ];

    final topic = await appState.createNewTopic(title: '笔记追问', refs: refs);
    appState.setCurrentCoachTopic(topic.uid);
    appState.setTabIndex(3);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _preview(String text) {
    final sanitized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (sanitized.length <= 100) return sanitized;
    return '${sanitized.substring(0, 100)}...';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? '新建笔记' : '编辑笔记'),
          actions: [
            IconButton(
              icon: const Icon(Icons.smart_toy_outlined, size: 22),
              tooltip: '问 AI',
              onPressed: _askAi,
            ),
            if (!_isNew)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22),
                color: AppTheme.dangerRed,
                onPressed: _delete,
              ),
            TextButton(
              onPressed: _save,
              child: Text(
                '保存',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _hasChanges
                      ? AppTheme.primaryGold
                      : AppTheme.textTertiary,
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (context.watch<AppState>().activeTraining != null ||
                  (_currentNote?.references.isNotEmpty ?? false)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (context.watch<AppState>().activeTraining != null)
                        _ReferenceChip(
                          label:
                              '当前训练 · ${context.read<AppState>().trainingRecordLabel(context.read<AppState>().activeTraining!)}',
                        ),
                      for (final ref in _currentNote?.references ?? const [])
                        _ReferenceChip(
                          label: context.read<AppState>().describeNoteReference(
                            ref,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Title field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '标题（可选）',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const Divider(),
              // Content field
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: '写下你的训练笔记...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    height: 1.6,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.accentBlue,
        ),
      ),
    );
  }
}
