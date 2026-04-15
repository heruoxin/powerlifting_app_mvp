import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/training_status_bar.dart';
import 'coach/coach_screen.dart';
import 'info/info_screen.dart';
import 'notes/notes_screen.dart';
import 'plan/plan_screen.dart';
import 'training/training_workbench_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late PageController _pageController;

  static const _tabs = [
    _TabDef('信息', Icons.dashboard_outlined, Icons.dashboard),
    _TabDef('计划', Icons.calendar_month_outlined, Icons.calendar_month),
    _TabDef('笔记', Icons.note_alt_outlined, Icons.note_alt),
    _TabDef('教练', Icons.smart_toy_outlined, Icons.smart_toy),
  ];

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _pageController = PageController(initialPage: appState.currentTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    final appState = context.read<AppState>();
    appState.setTabIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    final appState = context.read<AppState>();
    appState.setTabIndex(index);
  }

  void _navigateToWorkbench(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TrainingWorkbenchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentIndex = appState.currentTabIndex;
    final pageView = PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: MediaQuery.of(context).size.width >= 1024
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      children: const [
        InfoScreen(),
        PlanScreen(),
        NotesScreen(),
        CoachScreen(),
      ],
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth >= 1024;
          return Column(
            children: [
              if (appState.activeTraining != null)
                TrainingStatusBar(onTap: () => _navigateToWorkbench(context)),
              Expanded(
                child: isLargeScreen
                    ? Row(
                        children: [
                          _GlassSideRail(
                            currentIndex: currentIndex,
                            onTap: _onTabTapped,
                            tabs: _tabs,
                          ),
                          Expanded(child: pageView),
                        ],
                      )
                    : pageView,
              ),
            ],
          );
        },
      ),
      extendBody: true,
      bottomNavigationBar: MediaQuery.of(context).size.width >= 1024
          ? null
          : _GlassBottomBar(
              currentIndex: currentIndex,
              onTap: _onTabTapped,
              tabs: _tabs,
            ),
    );
  }
}

// ── Tab definition ──

class _TabDef {
  const _TabDef(this.label, this.outlinedIcon, this.filledIcon);

  final String label;
  final IconData outlinedIcon;
  final IconData filledIcon;
}

// ── Glass-morphism bottom bar ──

class _GlassBottomBar extends StatelessWidget {
  const _GlassBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabDef> tabs;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? tab.filledIcon : tab.outlinedIcon,
                          size: 24,
                          color: selected
                              ? AppTheme.primaryGold
                              : AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppTheme.primaryGold
                                : AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _GlassSideRail extends StatelessWidget {
  const _GlassSideRail({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabDef> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: AppTheme.cardWhite.withValues(alpha: 0.9),
        border: Border(
          right: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          labelType: NavigationRailLabelType.all,
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primaryGold.withValues(alpha: 0.16),
          selectedIconTheme: const IconThemeData(
            color: AppTheme.primaryGold,
            size: 24,
          ),
          unselectedIconTheme: const IconThemeData(
            color: AppTheme.textTertiary,
            size: 22,
          ),
          selectedLabelTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          unselectedLabelTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textTertiary,
          ),
          leading: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.fitness_center_rounded,
                color: AppTheme.primaryGold,
                size: 24,
              ),
            ),
          ),
          destinations: [
            for (var i = 0; i < tabs.length; i++)
              NavigationRailDestination(
                icon: Icon(tabs[i].outlinedIcon),
                selectedIcon: Icon(tabs[i].filledIcon),
                label: Text(tabs[i].label),
              ),
          ],
        ),
      ),
    );
  }
}
