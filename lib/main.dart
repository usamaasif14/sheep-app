// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/sheep_provider.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1B2A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Firebase init — safe, never crashes the app if not configured
  await FirebaseService.init();

  // Notifications — safe
  try {
    await NotificationService().initialize();
  } catch (_) {}

  runApp(const FarmManagerApp());
}

class FarmManagerApp extends StatelessWidget {
  const FarmManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SheepProvider()..loadSheep()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()..loadRecords()),
      ],
      child: MaterialApp(
        title: 'Farm Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigation(),
      ),
    );
  }
}
