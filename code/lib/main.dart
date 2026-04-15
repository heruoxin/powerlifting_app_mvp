import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final appState = AppState();
  await appState.init();

  runApp(PowerliftingApp(appState: appState));
}

class PowerliftingApp extends StatelessWidget {
  const PowerliftingApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: '电子教练',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeShell(),
      ),
    );
  }
}
