import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/session.dart';
import 'presentation/main/pages/main_layout.dart';
import 'presentation/auth/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize session (checks SharedPreferences + validates with backend)
  await UserSession().init();
  runApp(
    const ProviderScope(
      child: DukanSathiApp(),
    ),
  );
}

class DukanSathiApp extends StatelessWidget {
  const DukanSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dukan Sathi Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}

/// Routes to Dashboard if logged in, otherwise to Login page.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = UserSession();
    if (session.isLoggedIn) {
      return const MainLayout();
    }
    return const LoginPage();
  }
}
