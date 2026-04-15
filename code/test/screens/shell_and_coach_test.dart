import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:powerlifting_app/models/ai_topic.dart';
import 'package:powerlifting_app/providers/app_state.dart';
import 'package:powerlifting_app/screens/coach/coach_screen.dart';
import 'package:powerlifting_app/screens/home_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeShell responsive layout', () {
    testWidgets('shows navigation rail on large screens', (tester) async {
      final appState = AppState();
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(home: HomeShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('信息'), findsWidgets);
      expect(find.text('计划'), findsWidgets);
    });

    testWidgets('keeps bottom navigation on small screens', (tester) async {
      final appState = AppState();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(home: HomeShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('教练'), findsOneWidget);
      expect(find.text('笔记'), findsOneWidget);
    });
  });

  testWidgets('CoachScreen renders context references for active topic', (
    tester,
  ) async {
    final appState = AppState();
    final topic = AiTopic(
      title: '上下文测试',
      contextReferences: const [
        ContextReference(
          type: 'note',
          targetUid: 'note-1',
          displayLabel: '深蹲训练后记录',
          previewText: '右肩略紧，末组速度下降。',
        ),
      ],
    );
    appState.topics = [topic];
    appState.currentCoachTopicUid = topic.uid;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: CoachScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('已带入上下文'), findsOneWidget);
    expect(find.text('深蹲训练后记录'), findsWidgets);
    expect(find.text('右肩略紧，末组速度下降。'), findsWidgets);
  });
}
