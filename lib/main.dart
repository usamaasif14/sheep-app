// main.dart - App entry point
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/sheep_provider.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1B2A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize notifications (safe — errors don't crash the app)
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification init skipped: $e');
  }

  runApp(const SheepManagerApp());
}

class SheepManagerApp extends StatelessWidget {
  const SheepManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SheepProvider()..loadSheep()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()..loadRecords()),
      ],
      child: MaterialApp(
        title: 'Sheep Farm Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigation(),
      ),
    );
  }
}
