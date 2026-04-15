import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/ai_topic.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

/// AI Coach chat screen with topic navigation drawer and message display.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen>
    with SingleTickerProviderStateMixin {
  String? _activeTopicUid;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  bool _drawerOpen = false;
  String? _errorMsg;
  late final AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      if (s.topics.isNotEmpty) {
        final sorted = _sortedTopics(s.topics);
        setState(() => _activeTopicUid = sorted.first.uid);
      }
    });
    _msgCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──

  List<AiTopic> _sortedTopics(List<AiTopic> src) {
    final list = List<AiTopic>.from(src);
    list.sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
    return list;
  }

  AiTopic? get _activeTopic {
    if (_activeTopicUid == null) return null;
    final topics = context.read<AppState>().topics;
    for (final t in topics) {
      if (t.uid == _activeTopicUid) return t;
    }
    return null;
  }

  bool get _canSend => _msgCtrl.text.trim().isNotEmpty && !_isSending;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Actions ──

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    final appState = context.read<AppState>();
    if (_activeTopicUid == null) {
      final title =
          text.length > 20 ? '${text.substring(0, 20)}...' : text;
      final topic = await appState.createNewTopic(title: title);
      setState(() => _activeTopicUid = topic.uid);
    }

    _msgCtrl.clear();
    setState(() {
      _isSending = true;
      _errorMsg = null;
    });
    _scrollToBottom();

    try {
      await appState.sendAiMessage(_activeTopicUid!, text);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = '发送失败：$e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
    _scrollToBottom();
  }

  Future<void> _createNewTopic() async {
    final topic =
        await context.read<AppState>().createNewTopic(title: '新对话');
    setState(() {
      _activeTopicUid = topic.uid;
      _drawerOpen = false;
    });
  }

  Future<void> _deleteTopic(String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除对话'),
        content: const Text('确定要删除这个对话吗？此操作不可撤销。'),
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
    if (ok != true || !mounted) return;
    final appState = context.read<AppState>();
    await appState.deleteTopic(uid);
    if (_activeTopicUid == uid) {
      setState(() {
        _activeTopicUid =
            appState.topics.isNotEmpty ? appState.topics.first.uid : null;
      });
    } else {
      setState(() {});
    }
  }

  String _relativeDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return DateFormat('MM/dd').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _messageTime(String iso) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  bool _isRecent(String iso) {
    try {
      return DateTime.now().difference(DateTime.parse(iso)).inHours < 24;
    } catch (_) {
      return false;
    }
  }

  IconData _iconFor(String q) {
    if (q.contains('分析') || q.contains('表现')) return Icons.analytics_outlined;
    if (q.contains('计划') || q.contains('调整')) return Icons.calendar_month;
    if (q.contains('强度') || q.contains('进展')) return Icons.trending_up;
    if (q.contains('训练')) return Icons.fitness_center;
    return Icons.chat_bubble_outline;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final topic = _activeTopic;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(topic),
            Expanded(
              child: Stack(
                children: [
                  _buildBody(appState, topic),
                  if (_drawerOpen) _buildDrawerOverlay(appState),
                ],
              ),
            ),
            if (_errorMsg != null) _buildErrorBar(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(AiTopic? topic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _headerIcon(
            icon: _drawerOpen ? Icons.close : Icons.menu,
            highlight: _drawerOpen,
            onTap: () => setState(() => _drawerOpen = !_drawerOpen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('电子教练',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                if (topic != null)
                  Text(topic.title,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          _headerIcon(
            icon: Icons.add_comment_outlined,
            highlight: false,
            onTap: _createNewTopic,
            color: AppTheme.primaryGold,
          ),
        ],
      ),
    );
  }

  Widget _headerIcon({
    required IconData icon,
    required bool highlight,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: highlight
              ? AppTheme.primaryGold.withValues(alpha: 0.15)
              : (color != null
                  ? color.withValues(alpha: 0.10)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 22, color: color ?? AppTheme.textPrimary),
      ),
    );
  }

  // ── Body ──

  Widget _buildBody(AppState appState, AiTopic? topic) {
    if (appState.topics.isEmpty) return _buildWelcomeScreen(appState);
    if (topic == null) return _buildWelcomeScreen(appState);
    if (topic.messages.isEmpty) return _buildEmptyTopic(appState);
    return _buildMessageList(topic);
  }

  // ── Welcome (no topics) ──

  Widget _buildWelcomeScreen(AppState appState) {
    final suggestions = appState.getSuggestedQuestions();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy,
                  size: 36, color: AppTheme.primaryGold),
            ),
            const SizedBox(height: 20),
            const Text('电子教练',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              '我是你的力量举教练AI，可以帮你分析训练数据、\n调整计划、解答训练问题。',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 28),
            if (suggestions.isNotEmpty) ...[
              const Text('试试这些问题：',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: suggestions
                    .map((q) => _suggestedChip(q, _iconFor(q)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Empty topic (has topic but no messages) ──

  Widget _buildEmptyTopic(AppState appState) {
    final suggestions = appState.getSuggestedQuestions();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_outlined,
                size: 48,
                color: AppTheme.primaryGold.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('开始新的对话',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('向教练提问，或选择以下建议：',
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            if (suggestions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: suggestions
                    .map((q) => _suggestedChip(q, _iconFor(q)))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _suggestedChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        _msgCtrl.text = label;
        _sendMessage();
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        borderRadius: AppTheme.chipBorderRadius,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryGold),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message list ──

  Widget _buildMessageList(AiTopic topic) {
    final count = topic.messages.length + (_isSending ? 1 : 0);
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: count,
      itemBuilder: (_, i) {
        if (i == topic.messages.length && _isSending) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(topic.messages[i]);
      },
    );
  }

  Widget _buildMessageBubble(AiMessage msg) {
    final isUser = msg.role == 'user';
    final time = _messageTime(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _aiAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryGold.withValues(alpha: 0.15)
                        : AppTheme.cardWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? Border.all(
                            color:
                                AppTheme.primaryGold.withValues(alpha: 0.25),
                            width: 0.5)
                        : null,
                    boxShadow: isUser ? null : AppTheme.subtleShadow,
                  ),
                  child: isUser
                      ? Text(msg.content,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              height: 1.5))
                      : MarkdownBody(
                          data: msg.content,
                          selectable: true,
                          styleSheet: _mdStyle(),
                        ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          if (time.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isUser ? 0 : 40,
                right: isUser ? 8 : 0,
              ),
              child: Text(time,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textTertiary)),
            ),
        ],
      ),
    );
  }

  Widget _aiAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child:
          const Icon(Icons.smart_toy, size: 18, color: AppTheme.primaryGold),
    );
  }

  MarkdownStyleSheet _mdStyle() {
    return MarkdownStyleSheet(
      p: const TextStyle(
          fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
      strong: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary),
      listBullet:
          const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      code: TextStyle(
        fontSize: 13,
        color: AppTheme.textPrimary,
        backgroundColor: Colors.grey.withValues(alpha: 0.1),
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
              color: AppTheme.primaryGold.withValues(alpha: 0.4), width: 3),
        ),
      ),
    );
  }

  // ── Typing indicator (animated dots) ──

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aiAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: AppTheme.subtleShadow,
            ),
            child: AnimatedBuilder(
              animation: _dotCtrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.25;
                    final t = (_dotCtrl.value + delay) % 1.0;
                    final scale = 0.5 + 0.5 * sin(t * pi);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold
                                .withValues(alpha: 0.3 + 0.5 * scale),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Error bar ──

  Widget _buildErrorBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.dangerRed.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppTheme.dangerRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMsg ?? '',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.dangerRed)),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMsg = null),
            child: const Icon(Icons.close, size: 16, color: AppTheme.dangerRed),
          ),
        ],
      ),
    );
  }

  // ── Input area ──

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, max(MediaQuery.of(context).padding.bottom, 8.0)),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          top: BorderSide(
              color: Colors.black.withValues(alpha: 0.05), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _msgCtrl,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                style: const TextStyle(fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _canSend ? _sendMessage : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _canSend ? AppTheme.primaryGold : const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded,
                  size: 20,
                  color: _canSend
                      ? AppTheme.textPrimary
                      : AppTheme.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drawer overlay ──

  Widget _buildDrawerOverlay(AppState appState) {
    final sorted = _sortedTopics(appState.topics);
    final recent = sorted.where((t) => _isRecent(t.lastActiveAt)).toList();
    final earlier = sorted.where((t) => !_isRecent(t.lastActiveAt)).toList();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _drawerOpen = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(4, 0),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drawer header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          const Text('对话列表',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _createNewTopic,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGold
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add,
                                  size: 20, color: AppTheme.primaryGold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Topic sections
                    Expanded(
                      child: sorted.isEmpty
                          ? const Center(
                              child: Text('暂无对话',
                                  style: TextStyle(
                                      color: AppTheme.textTertiary)))
                          : ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                if (recent.isNotEmpty) ...[
                                  _sectionHeader('最近'),
                                  ...recent.map(
                                      (t) => _topicTile(t, t.uid == _activeTopicUid)),
                                ],
                                if (earlier.isNotEmpty) ...[
                                  _sectionHeader('更早'),
                                  ...earlier.map(
                                      (t) => _topicTile(t, t.uid == _activeTopicUid)),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(title,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textTertiary,
              letterSpacing: 0.5)),
    );
  }

  Widget _topicTile(AiTopic topic, bool isActive) {
    final date = _relativeDate(topic.lastActiveAt);
    final count = topic.messages.length;

    return Container(
      color: isActive
          ? AppTheme.primaryGold.withValues(alpha: 0.08)
          : Colors.transparent,
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        title: Text(
          topic.title.isNotEmpty ? topic.title : '未命名对话',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('$count 条消息 · $date',
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textTertiary)),
        trailing: GestureDetector(
          onTap: () => _deleteTopic(topic.uid),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.delete_outline,
                size: 18, color: AppTheme.textTertiary),
          ),
        ),
        onTap: () {
          setState(() {
            _activeTopicUid = topic.uid;
            _drawerOpen = false;
          });
        },
      ),
    );
  }
}
