# Supabase Google Login Implementation Guide

## Overview
This document provides step-by-step instructions for setting up and using Supabase Google Login authentication in the Dukan Sathi application.

## What Was Changed

### 1. **Removed Authentication Methods**
- ❌ Email/Password registration (`UserSession.register()`)
- ❌ Email/Password login (`UserSession.loginWithEmail()`)
- ❌ Demo credentials authentication

### 2. **New Authentication Method**
- ✅ Google OAuth login (`UserSession.loginWithGoogle()`)
- ✅ Automatic user creation in Supabase
- ✅ Shop information retrieval after authentication

## Installation & Setup

### Step 1: Install Dependencies
The required dependencies have been added to both `pubspec.yaml` files:

```yaml
dependencies:
  google_sign_in: ^6.1.6
  supabase_flutter: ^2.10.6
```

Run the following command to install dependencies:
```bash
flutter pub get
```

### Step 2: Configure Google OAuth in Supabase

#### A. Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API:
   - Go to APIs & Services → Library
   - Search for "Google+ API"
   - Click on it and press "Enable"

4. Create OAuth 2.0 credentials:
   - Go to APIs & Services → Credentials
   - Click "Create Credentials" → "OAuth client ID"
   - Choose "Web application"
   - Add authorized redirect URIs:
     - `https://YOUR_SUPABASE_URL/auth/v1/callback`
     - For local development: `http://localhost:5173/auth/v1/callback` (for web)
   - Click Create and note your **Client ID**

#### B. Configure Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Authentication → Providers**
4. Find and enable **Google**
5. Paste your Google OAuth **Client ID** from Step A
6. Save the configuration

### Step 3: Configure Flutter App

#### For Android:
Add to `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34  // Use API 34+
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

#### For iOS:
1. Go to `ios/Runner/Info.plist`
2. Add Google Sign-In URL scheme:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

#### For Web:
Add to `web/index.html` in the `<head>` section:
```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
<script src="https://accounts.google.com/gsi/client" async defer></script>
```

## Usage

### Main App (User Login)

**File:** `lib/presentation/auth/pages/login_page.dart`

The login page now shows a Google Sign-In button. When users click it:

```dart
Future<void> _handleGoogleLogin() async {
  final result = await UserSession().loginWithGoogle();
  
  if (result['success'] == true) {
    _navigateToDashboard();
  } else {
    setState(() => _error = result['error']);
  }
}
```

### Admin Dashboard

**File:** `flutter_admin_dashboard/lib/screens/login_screen.dart`

The admin login screen also uses Google Sign-In:

```dart
Future<void> _handleGoogleLogin(BuildContext context) async {
  final authProvider = context.read<AuthProvider>();
  final success = await authProvider.loginWithGoogle();
  
  if (success && mounted) {
    context.go('/dashboard');
  }
}
```

### Session Management

**File:** `lib/core/session.dart`

The `UserSession` class handles user authentication state:

```dart
// Authenticate with Google
final result = await UserSession().loginWithGoogle();

// Logout
await UserSession().logout();

// Check if logged in
bool isLoggedIn = UserSession().isLoggedIn;
```

### Google Auth Service (Utility)

**File:** `lib/services/google_auth_service.dart`

For more granular control, use the `GoogleAuthService`:

```dart
final googleAuth = GoogleAuthService();

// Sign in
final result = await googleAuth.signInWithGoogle();

// Sign out
await googleAuth.signOut();

// Check current user
if (googleAuth.isSignedIn) {
  final user = googleAuth.currentUser;
}
```

## User Flow

1. **User opens app** → Sees Google Sign-In button
2. **User clicks "Sign in with Google"** → Redirected to Google login
3. **User authenticates with Google** → Returned to app
4. **App exchanges token with Supabase** → User authenticated
5. **User data created/updated in Supabase** → Session established
6. **User navigated to main dashboard** → Full access granted

## Database Schema

When a user authenticates, the following data is created/updated:

### `auth.users` (Supabase Built-in)
- `id`: User ID (auto-generated)
- `email`: User's Google email
- `email_confirmed_at`: Set automatically by Google

### `public.users` (Custom Table)
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### `public.shops` (Existing)
```sql
CREATE TABLE shops (
  id UUID PRIMARY KEY,
  owner_id UUID NOT NULL REFERENCES auth.users(id),
  name TEXT,
  state TEXT,
  business_type TEXT,
  gst_registration_number TEXT,
  gst_mode TEXT,
  upi_id TEXT,
  onboarding_completed BOOLEAN,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Security Considerations

1. **No Password Storage** ✅
   - All passwords are managed by Google
   - Your app never handles passwords
   - Reduced PCI compliance burden

2. **Token Management** ✅
   - Access tokens are automatically managed by Supabase
   - Refresh tokens stored securely locally
   - Tokens expire after set time

3. **HTTPS Only** ✅
   - OAuth callbacks must use HTTPS in production
   - Local development uses HTTP

4. **Google Account Security** ✅
   - Users can manage Google account recovery
   - Two-factor authentication supported via Google
   - Users can revoke app permissions anytime

## Troubleshooting

### Issue: "Google sign-in cancelled"
**Solution:** User closed the Google login dialog. This is normal behavior.

### Issue: "Failed to get Google authentication tokens"
**Solution:** 
- Check that Google OAuth credentials are properly configured
- Verify that Client ID is correct in Supabase settings

### Issue: "Failed to authenticate with Supabase"
**Solution:**
- Check that Google provider is enabled in Supabase
- Verify Supabase project URL and anon key in `.env`

### Issue: "PlatformException" on Android
**Solution:**
- Ensure minimum SDK is 21+
- Check SHA-1 certificate fingerprint is added to Google Cloud Console
- Run `./gradlew signingReport` to get your app's SHA-1

### Issue: "NSInvalidArgumentException" on iOS
**Solution:**
- Add Google Sign-In URL scheme to `Info.plist`
- Check CocoaPods dependencies: `pod repo update && pod install`

## Testing

### Manual Testing Steps

1. **Start the app:**
   ```bash
   flutter run
   ```

2. **Click "Sign in with Google"**

3. **Authenticate with a test Google account**

4. **Verify:**
   - User data appears in Supabase Console
   - App navigates to dashboard
   - Session is maintained on app restart

### Automated Testing

```dart
// Unit test example
test('Google login returns user data', () async {
  final result = await UserSession().loginWithGoogle();
  
  expect(result['success'], true);
  expect(result['userId'], isNotEmpty);
  expect(result['email'], contains('@'));
});
```

## Environment Variables

Ensure `.env` file contains:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## Next Steps

1. ✅ Test Google login with a real Google account
2. ✅ Verify user data is created in Supabase
3. ✅ Test on Android, iOS, and Web platforms
4. ✅ Set up email reminders/notifications
5. ✅ Implement custom onboarding after first login

## Support Resources

- [Supabase Google OAuth Docs](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Supabase Flutter Docs](https://supabase.com/docs/reference/flutter/introduction)
- [Google Cloud Console](https://console.cloud.google.com/)

## Migration from Email/Password Auth

If migrating existing users:

```dart
// Old users with email/password need to use "Forgot Password" or re-register with Google
// New signups use only Google OAuth
// Consider adding a message: "Sign in with your Google account. If you have an old account, please use password reset."
```

---

**Last Updated:** May 2024
**Status:** Production Ready ✅
