import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vstream/core/config/app_router.dart';
import 'package:vstream/core/config/env.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/shared/services/local_db_service.dart';
import 'package:vstream/shared/services/local_notification_service.dart';
import 'package:vstream/shared/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive + seed demo catalog
  await Hive.initFlutter();
  await LocalDbService.init();
  
  // Initialize Local Notifications
  await LocalNotificationService.initialize();

  // Initialize Supabase when credentials are provided
  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: VStreamApp()));
}

class VStreamApp extends ConsumerWidget {
  const VStreamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'VStream',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
