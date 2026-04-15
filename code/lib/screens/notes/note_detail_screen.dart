import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  bool _hasChanges = false;

  bool get _isNew => widget.note == null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');

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

  Future<void> _save() async {
    final appState = context.read<AppState>();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    if (_isNew) {
      final note = TrainingNote(
        title: title,
        content: content,
      );
      await appState.addNote(note);
    } else {
      final updated = widget.note!.copyWith(
        title: title,
        content: content,
      );
      await appState.updateNote(updated);
    }

    if (mounted) Navigator.of(context).pop();
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
      await appState.deleteNote(widget.note!.uid);
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
        await _save();
        return false; // Already popped in _save
      }
      return result == 'discard';
    }
    return true;
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
