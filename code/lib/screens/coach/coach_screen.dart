import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import '../../models/ai_topic.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
/// AI Coach chat screen with topic drawer and message display.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  String? _activeTopicUid;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _showTopicDrawer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.topics.isNotEmpty) {
        setState(() => _activeTopicUid = appState.topics.first.uid);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  AiTopic? get _activeTopic {
    if (_activeTopicUid == null) return null;
    final appState = context.read<AppState>();
    try {
      return appState.topics.firstWhere((t) => t.uid == _activeTopicUid);
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    final appState = context.read<AppState>();

    // Create topic if none selected
    if (_activeTopicUid == null) {
      final topic = await appState.createNewTopic(
        title: message.length > 20 ? '${message.substring(0, 20)}...' : message,
      );
      setState(() => _activeTopicUid = topic.uid);
    }

    _messageController.clear();
    setState(() => _isSending = true);

    _scrollToBottom();

    await appState.sendAiMessage(_activeTopicUid!, message);

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _createNewTopic() async {
    final appState = context.read<AppState>();
    final topic = await appState.createNewTopic(title: '新对话');
    setState(() {
      _activeTopicUid = topic.uid;
      _showTopicDrawer = false;
    });
  }

  Future<void> _deleteTopic(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除对话'),
        content: const Text('确定要删除这个对话吗？'),
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
      await appState.deleteTopic(uid);
      if (_activeTopicUid == uid) {
        setState(() {
          _activeTopicUid =
              appState.topics.isNotEmpty ? appState.topics.first.uid : null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final topic = _activeTopic;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(appState, topic),
            Expanded(
              child: Stack(
                children: [
                  // Messages area
                  topic != null && topic.messages.isNotEmpty
                      ? _buildMessageList(topic)
                      : _buildWelcome(),
                  // Topic drawer overlay
                  if (_showTopicDrawer)
                    _buildTopicDrawer(appState),
                ],
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppState appState, AiTopic? topic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          GestureDetector(
            onTap: () => setState(() => _showTopicDrawer = !_showTopicDrawer),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showTopicDrawer
                    ? AppTheme.primaryGold.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _showTopicDrawer ? Icons.close : Icons.menu,
                size: 22,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '电子教练',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (topic != null)
                  Text(
                    topic.title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // New conversation button
          GestureDetector(
            onTap: _createNewTopic,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_comment_outlined,
                size: 20,
                color: AppTheme.primaryGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicDrawer(AppState appState) {
    final topics = List<AiTopic>.from(appState.topics)
      ..sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showTopicDrawer = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {}, // Absorb taps on drawer
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
                          const Text(
                            '对话列表',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _createNewTopic,
                            child: const Icon(Icons.add,
                                size: 22, color: AppTheme.primaryGold),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Topic list
                    Expanded(
                      child: topics.isEmpty
                          ? const Center(
                              child: Text('暂无对话',
                                  style: TextStyle(
                                      color: AppTheme.textTertiary)),
                            )
                          : ListView.builder(
                              itemCount: topics.length,
                              itemBuilder: (context, index) {
                                final t = topics[index];
                                final isActive =
                                    t.uid == _activeTopicUid;
                                return _buildTopicTile(t, isActive);
                              },
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

  Widget _buildTopicTile(AiTopic topic, bool isActive) {
    final dateStr = _formatRelativeDate(topic.lastActiveAt);
    final messageCount = topic.messages.length;

    return Container(
      color: isActive
          ? AppTheme.primaryGold.withValues(alpha: 0.08)
          : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
        subtitle: Text(
          '$messageCount 条消息 · $dateStr',
          style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
        ),
        trailing: GestureDetector(
          onTap: () => _deleteTopic(topic.uid),
          child: Icon(Icons.delete_outline,
              size: 18,
              color: AppTheme.textTertiary.withValues(alpha: 0.5)),
        ),
        onTap: () {
          setState(() {
            _activeTopicUid = topic.uid;
            _showTopicDrawer = false;
          });
        },
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy,
                  size: 32, color: AppTheme.primaryGold),
            ),
            const SizedBox(height: 16),
            const Text(
              '电子教练',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '我是你的力量举教练AI，可以帮你分析训练数据、\n调整计划、解答训练问题。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Quick actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _quickAction('分析近期训练', Icons.analytics_outlined),
                _quickAction('调整下周计划', Icons.calendar_month),
                _quickAction('恢复建议', Icons.healing),
                _quickAction('技术要点', Icons.school),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        _messageController.text = label;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryGold),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(AiTopic topic) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: topic.messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == topic.messages.length && _isSending) {
          return _buildTypingIndicator();
        }
        final msg = topic.messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(AiMessage msg) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy,
                  size: 18, color: AppTheme.primaryGold),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: isUser
                  ? Text(
                      msg.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: msg.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                        strong: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        listBullet: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        code: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy,
                size: 18, color: AppTheme.primaryGold),
          ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryGold.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '思考中...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
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
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSending
                    ? AppTheme.textTertiary
                    : AppTheme.primaryGold,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 20,
                color: _isSending ? Colors.white60 : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(String iso) {
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
