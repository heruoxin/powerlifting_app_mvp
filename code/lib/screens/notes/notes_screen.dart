import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/training_note.dart';
import '../../models/ai_memory.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import 'note_detail_screen.dart';
import 'memory_file_detail_screen.dart';

/// Notes screen with dual tabs: User Notes + Coach Notes.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _UserNotesTab(),
                  _CoachNotesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '训练笔记',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(AppTheme.smallBorderRadius),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius:
                    BorderRadius.circular(AppTheme.smallBorderRadius),
                boxShadow: AppTheme.subtleShadow,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textTertiary,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w400),
              tabs: const [
                Tab(text: '我的笔记'),
                Tab(text: '教练笔记'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── User Notes Tab ──

class _UserNotesTab extends StatelessWidget {
  const _UserNotesTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final notes = List<TrainingNote>.from(appState.notes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (notes.isEmpty) {
      return _buildEmptyState(context);
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return _NoteCard(note: notes[index]);
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'add_note',
            onPressed: () => _createNewNote(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_alt_outlined,
              size: 48,
              color: AppTheme.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            '暂无训练笔记',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '记录你的训练心得和思考',
            style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _createNewNote(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('创建笔记'),
          ),
        ],
      ),
    );
  }

  void _createNewNote(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NoteDetailScreen()),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final TrainingNote note;

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(note.updatedAt);
    final preview = note.content.length > 100
        ? '${note.content.substring(0, 100)}...'
        : note.content;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NoteDetailScreen(note: note),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title.isNotEmpty ? note.title : '未命名笔记',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textTertiary)),
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              preview,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (note.references.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: note.references.map((ref) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ref.targetType} · ${ref.targetUid.length > 6 ? ref.targetUid.substring(0, 6) : ref.targetUid}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return DateFormat('MM/dd').format(dt);
    } catch (_) {
      return '';
    }
  }
}

// ── Coach Notes Tab ──

class _CoachNotesTab extends StatelessWidget {
  const _CoachNotesTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final memoryFiles = appState.memoryFiles;

    if (memoryFiles.isEmpty) {
      return const Center(
        child: Text('教练记忆文件尚未初始化',
            style: TextStyle(color: AppTheme.textTertiary)),
      );
    }

    final primaryKeys = ['diary', 'coach_observation'];
    final primary =
        memoryFiles.where((f) => primaryKeys.contains(f.key)).toList();
    final secondary =
        memoryFiles.where((f) => !primaryKeys.contains(f.key)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        GlassCard(
          color: AppTheme.accentBlue.withValues(alpha: 0.05),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18,
                  color: AppTheme.accentBlue.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI教练的记忆文件，记录了对你训练的观察和理解。这些文件由AI自动维护，你也可以手动编辑。',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: '默认展示'),
        const SizedBox(height: 6),
        ...primary.map((f) => _MemoryFileCard(file: f)),
        const SizedBox(height: 16),
        const SectionHeader(title: '更多记忆'),
        const SizedBox(height: 6),
        ...secondary.map((f) => _MemoryFileCard(file: f)),
      ],
    );
  }
}

class _MemoryFileCard extends StatelessWidget {
  const _MemoryFileCard({required this.file});
  final AiMemoryFile file;

  @override
  Widget build(BuildContext context) {
    final preview = file.content.length > 120
        ? '${file.content.substring(0, 120)}...'
        : file.content;
    final dateStr = _formatDate(file.lastUpdatedAt);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryFileDetailScreen(file: file),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_fileIcon(file.key), size: 18, color: _fileColor(file.key)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (!file.isEditable)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('只读',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textTertiary)),
                ),
              const SizedBox(width: 8),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String key) {
    switch (key) {
      case 'soul':
        return Icons.psychology;
      case 'training_plan':
        return Icons.calendar_month;
      case 'user_traits':
        return Icons.person_outline;
      case 'coach_observation':
        return Icons.visibility;
      case 'diary':
        return Icons.book;
      default:
        return Icons.description;
    }
  }

  Color _fileColor(String key) {
    switch (key) {
      case 'soul':
        return AppTheme.accentBlue;
      case 'training_plan':
        return AppTheme.primaryGold;
      case 'user_traits':
        return AppTheme.secondaryGreen;
      case 'coach_observation':
        return const Color(0xFFFF9800);
      case 'diary':
        return AppTheme.dangerRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('MM/dd HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }
}
