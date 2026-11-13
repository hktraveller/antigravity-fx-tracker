import 'package:flutter/material.dart';
import 'models/currency.dart';
import 'screens/main_screen.dart';
import 'state/fx_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = FxController();
  await controller.initialize();
  runApp(GlobalFxTrackerApp(controller: controller));
}

class GlobalFxTrackerApp extends StatelessWidget {
  const GlobalFxTrackerApp({super.key, required this.controller});

  final FxController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ThemeMode resolvedThemeMode;
        switch (controller.themeMode) {
          case AppThemeMode.system:
            resolvedThemeMode = ThemeMode.system;
            break;
          case AppThemeMode.light:
            resolvedThemeMode = ThemeMode.light;
            break;
          case AppThemeMode.dark:
            resolvedThemeMode = ThemeMode.dark;
            break;
        }

        return MaterialApp(
          title: '全球匯率通 FX Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: resolvedThemeMode,
          home: MainScreen(controller: controller),
        );
      },
    );
  }
}
