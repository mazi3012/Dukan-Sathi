import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/session.dart';
import 'presentation/main/pages/main_layout.dart';
import 'presentation/auth/pages/welcome_auth_flow.dart';
import 'presentation/auth/pages/shop_setup_page.dart';
import 'presentation/auth/pages/email_verification_page.dart';

import 'core/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase correctly for Flutter (handles session persistence and OAuth redirects)
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('WARNING: SUPABASE_URL or SUPABASE_ANON_KEY is missing! Use --dart-define=SUPABASE_URL=... during run.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  );

  // Initialize config (checks SharedPreferences + defaults based on build mode)
  await AppConfig.init();

  // Initialize session (checks SharedPreferences + validates with backend)
  await UserSession().init();
  runApp(
    const ProviderScope(
      child: DukanSathiApp(),
    ),
  );
}

class DukanSathiApp extends ConsumerWidget {
  const DukanSathiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Dukan Sathi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
      onGenerateRoute: _handleDeepLink,
    );
  }

  /// Handle deep links for email verification callback
  static Route<dynamic>? _handleDeepLink(RouteSettings settings) {
    // Example: dukansathi://auth/callback?type=signup&code=xxx
    if (settings.name?.contains('auth/callback') ?? false) {
      // Extract query parameters
      final uri = Uri.parse(settings.name ?? '');
      final type = uri.queryParameters['type'];
      final code = uri.queryParameters['code'];
      
      // Log for debugging
      debugPrint('[DeepLink] Auth callback detected: type=$type, code=$code');
      
      // For now, just log and proceed to AuthGate
      // In production, you would verify the code with Supabase
      // For now, assume email is verified after clicking link
      UserSession().markEmailVerified();
      
      // Return null to let MaterialApp handle routing to home
      return null;
    }
    return null;
  }
}

/// Routes based on user auth state:
/// 1. Not logged in → LoginPage
/// 2. Logged in but email not verified → EmailVerificationPage
/// 3. Logged in with email verified but no shop → ShopSetupPage
/// 4. Fully set up (logged in + has shop) → MainLayout
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserSession(),
      builder: (context, _) {
        final session = UserSession();
        
        // Not logged in
        if (!session.isLoggedIn) {
          return const WelcomeAuthFlow();
        }
        
        // Logged in but email not verified (optional verification)
        // For now we're allowing users to skip, so this is just a fallback
        if (!session.emailVerified) {
          return EmailVerificationPage(email: session.userName ?? 'your email');
        }
        
        // Logged in with email verified but no shop set up
        if (!session.hasShop) {
          return const ShopSetupPage();
        }
        
        // Fully authenticated and shop is set up
        return const MainLayout();
      },
    );
  }
}
