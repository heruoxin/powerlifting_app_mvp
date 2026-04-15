import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_settings.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().settings;
    _nameController = TextEditingController(text: settings.userName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateSettings(UserSettings Function(UserSettings) updater) {
    final appState = context.read<AppState>();
    final updated = updater(appState.settings);
    appState.updateSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppState>().settings;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── User Name ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: '个人信息',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    hintText: '输入你的名字',
                  ),
                  onChanged: (value) {
                    _updateSettings((s) => s.copyWith(userName: value));
                  },
                ),
              ],
            ),
          ),

          // ── Weight Unit ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: '默认单位',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'kg', label: Text('公斤 (kg)')),
                    ButtonSegment(value: 'lb', label: Text('磅 (lb)')),
                  ],
                  selected: {settings.defaultWeightUnit},
                  onSelectionChanged: (value) {
                    _updateSettings(
                      (s) => s.copyWith(defaultWeightUnit: value.first),
                    );
                  },
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.textPrimary;
                      }
                      return AppTheme.textSecondary;
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ── Weekly Frequency ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: '每周训练频率',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final freq = i + 1;
                    final isSelected =
                        settings.preferredWeeklyFrequency == freq;
                    return ChoiceChip(
                      label: Text('$freq'),
                      selected: isSelected,
                      onSelected: (_) {
                        _updateSettings(
                          (s) =>
                              s.copyWith(preferredWeeklyFrequency: freq),
                        );
                      },
                      selectedColor:
                          AppTheme.primaryGold.withValues(alpha: 0.2),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── Language (placeholder) ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: '语言 / Language',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('简体中文'),
                  subtitle: const Text('更多语言即将支持'),
                  trailing: const Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryGreen,
                  ),
                ),
              ],
            ),
          ),

          // ── Data Export / Import ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: '数据管理',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showExportDialog(context),
                        icon: const Icon(Icons.upload_outlined),
                        label: const Text('导出数据'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('导入功能将在后续版本支持')),
                          );
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('导入数据'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showResetDialog(context),
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text('重置所有数据'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.dangerRed,
                    side: BorderSide(
                        color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),

          // ── About ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionHeader(
                  title: '关于',
                  padding: EdgeInsets.zero,
                ),
                SizedBox(height: 8),
                Text(
                  'Powerlifting App MVP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '版本 0.1.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '一款为力量举运动员打造的智能训练助手。',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final recordCount = appState.trainingRecords.length;
    final planCount = appState.mesocycles.length;
    final noteCount = appState.notes.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('数据导出'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前数据概览：'),
            const SizedBox(height: 8),
            Text('• 训练记录: $recordCount 条'),
            Text('• 训练计划: $planCount 个'),
            Text('• 训练笔记: $noteCount 条'),
            const SizedBox(height: 12),
            const Text(
              '完整导出功能将在后续版本中实现。数据将以JSON格式导出，支持备份和迁移。',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置所有数据'),
        content: const Text(
          '这将清除所有训练记录、计划、笔记和设置，并重新加载示例数据。\n\n此操作不可撤销！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final appState = context.read<AppState>();
              await appState.resetWithDemoData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据已重置')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}
