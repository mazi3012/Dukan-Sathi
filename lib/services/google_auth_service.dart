import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Google Authentication Service
/// Handles all Google Sign-In operations and Supabase integration
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  late SupabaseClient _supabase;

  /// Initialize the Supabase client
  void initialize(SupabaseClient supabase) {
    _supabase = supabase;
  }

  /// Sign in with Google and authenticate with Supabase
  /// Returns a map with success status and user data
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Sign out first to ensure fresh login
      await _googleSignIn.signOut();

      // Start Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
          'error': 'Google sign-in cancelled',
        };
      }

      // Get Google authentication tokens
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return {
          'success': false,
          'error': 'Failed to get Google authentication tokens',
        };
      }

      // Sign in with Supabase using Google provider
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );

      if (response.user == null) {
        return {
          'success': false,
          'error': 'Failed to authenticate with Supabase',
        };
      }

      final userId = response.user!.id;
      final userEmail = response.user!.email ?? googleUser.email;
      final userName = googleUser.displayName ?? googleUser.email;

      return {
        'success': true,
        'userId': userId,
        'email': userEmail,
        'name': userName,
        'photoUrl': googleUser.photoUrl,
      };
    } catch (e, stack) {
      debugPrint('[GoogleAuthService] Sign in error: $e\n$stack');
      String msg = e.toString();
      if (msg.contains('PlatformException')) {
        msg = 'Failed to sign in with Google. Please try again.';
      } else {
        msg = msg.replaceAll('Exception: ', '');
      }
      return {
        'success': false,
        'error': msg,
      };
    }
  }

  /// Sign out from Google and Supabase
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] Sign out error: $e');
    }
  }

  /// Get current signed-in user (if any)
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Disconnect the app from the user's Google account
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] Disconnect error: $e');
    }
  }
}
