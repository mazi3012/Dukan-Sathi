import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Use conditional imports: supabase_flutter for mobile, supabase for web
import 'package:supabase_flutter/supabase_flutter.dart' if (dart.library.html) 'package:supabase/supabase.dart';

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
      debugPrint('[GoogleAuthService] googleUser: ${googleUser.email} id:${googleUser.id}');
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      debugPrint('[GoogleAuthService] googleAuth tokens: hasId=${idToken!=null} hasAccess=${accessToken!=null}');
      if (accessToken == null || idToken == null || idToken.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to get Google authentication tokens',
        };
      }

      // Sign in with Supabase using Google provider
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final respUser = response.user;
      debugPrint('[GoogleAuthService] supabase response.user: ${respUser?.id}');
      if (respUser == null) {
        debugPrint('[GoogleAuthService] Supabase response.user is null');
        return {
          'success': false,
          'error': 'Failed to authenticate with Supabase',
        };
      }

      final userId = respUser.id;
      final userEmail = respUser.email ?? googleUser.email;
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
