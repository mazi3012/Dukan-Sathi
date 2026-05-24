import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database.dart'; // Import supabase client

class AuthService {
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? '648987320349-asplif3bmr9ai0k3lkp9ulth5gne9eru.apps.googleusercontent.com' : null,
      serverClientId: '648987320349-asplif3bmr9ai0k3lkp9ulth5gne9eru.apps.googleusercontent.com',
      scopes: [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
    );
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      debugPrint('[AuthService] Starting Google Sign-In flow (isWeb: $kIsWeb)');
      
      if (kIsWeb) {
        debugPrint('[AuthService] Web platform detected - using signInWithOAuth redirect');
        final String redirectTo = Uri.base.origin;
        debugPrint('[AuthService] Web redirect URL: $redirectTo');

        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectTo,
        );
        return {'success': true, 'note': 'Redirecting to Google...'};
      }

      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AuthService] Google sign-in cancelled by user');
        return {'success': false, 'error': 'Google sign-in cancelled'};
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null || idToken.isEmpty) {
        return {'success': false, 'error': 'Failed to get Google authentication tokens'};
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final respUser = response.user;
      debugPrint('[AuthService] supabase response.user: ${respUser?.id}');
      if (respUser == null) {
        debugPrint('[AuthService] Supabase response.user is null');
        return {'success': false, 'error': 'Failed to authenticate with Supabase'};
      }

      final userId = respUser.id;
      final userEmail = respUser.email ?? googleUser.email;
      final userName = googleUser.displayName ?? googleUser.email;

      await supabase.from('users').upsert({
        'id': userId,
        'email': userEmail,
        'full_name': userName,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'userId': userId,
        'userName': userName,
        'emailConfirmed': respUser.emailConfirmedAt != null || true,
      };
    } catch (e, stack) {
      debugPrint('[AuthService] Google login error: $e\n$stack');
      String msg = e.toString();
      if (msg.contains('PlatformException')) {
        msg = 'Failed to sign in with Google. Please try again.';
      } else {
        msg = msg.replaceAll('Exception: ', '');
      }
      return {'success': false, 'error': msg};
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}
