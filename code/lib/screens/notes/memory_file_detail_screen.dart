import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../models/ai_memory.dart';
import '../../models/ai_topic.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

/// Detail screen for viewing/editing a single AI memory file.
class MemoryFileDetailScreen extends StatefulWidget {
  const MemoryFileDetailScreen({super.key, required this.file});

  final AiMemoryFile file;

  @override
  State<MemoryFileDetailScreen> createState() => _MemoryFileDetailScreenState();
}

class _MemoryFileDetailScreenState extends State<MemoryFileDetailScreen> {
  late TextEditingController _contentController;
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.file.content);
    _contentController.addListener(() {
      if (!_hasChanges && _contentController.text != widget.file.content) {
        setState(() => _hasChanges = true);
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final appState = context.read<AppState>();
    final updated = widget.file.copyWith(content: _contentController.text);
    await appState.updateMemoryFile(updated);
    if (mounted) {
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已保存')));
    }
  }

  Future<void> _askAi() async {
    final appState = context.read<AppState>();
    final content = _isEditing ? _contentController.text : widget.file.content;
    final topic = await appState.createNewTopic(
      title: '教练笔记追问',
      refs: [
        ContextReference(
          type: 'memory_file',
          targetUid: widget.file.key,
          displayLabel: widget.file.displayName,
          previewText: _preview(content),
        ),
      ],
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, size: 22),
            tooltip: '问 AI',
            onPressed: _askAi,
          ),
          if (widget.file.isEditable && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 22),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
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
      body: _isEditing ? _buildEditor() : _buildViewer(),
    );
  }

  Widget _buildViewer() {
    return Markdown(
      data: widget.file.content,
      padding: const EdgeInsets.all(16),
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
        h2: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        h3: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        p: const TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
          height: 1.6,
        ),
        listBullet: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        decoration: const InputDecoration(
          hintText: '编辑记忆文件内容...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
          height: 1.6,
          fontFamily: 'monospace',
        ),
        maxLines: null,
        keyboardType: TextInputType.multiline,
      ),
    );
  }
}
