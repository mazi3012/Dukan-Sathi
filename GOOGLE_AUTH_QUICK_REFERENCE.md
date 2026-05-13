# Google OAuth Implementation - Quick Reference

## 🎯 Quick Start

### For Users
```
1. Open App
2. Click "Sign in with Google"
3. Authenticate with Google
4. Done! You're logged in
```

### For Developers

#### 1. Setup Google OAuth
```bash
# Step 1: Create Google OAuth credentials at https://console.cloud.google.com
# Step 2: Add credentials to Supabase (Authentication → Providers → Google)
# Step 3: Configure your Flutter app (see GOOGLE_AUTH_SETUP.md for details)
# Step 4: Run the app
flutter run
```

#### 2. Test Google Login
```dart
// In any screen
final result = await UserSession().loginWithGoogle();

if (result['success'] == true) {
  print('User logged in: ${result['userId']}');
  // Navigate to main dashboard
} else {
  print('Error: ${result['error']}');
}
```

#### 3. Access User Data
```dart
final session = UserSession();

// Get current user ID
String? userId = session.userId;

// Get user name
String? userName = session.userName;

// Get shop info
String? shopId = session.shopId;
String? shopName = session.shopName;

// Check if logged in
bool isLoggedIn = session.isLoggedIn;
```

#### 4. Logout
```dart
await UserSession().logout();
// User is now signed out from both Google and Supabase
```

## 📁 Key Files

| File | Purpose |
|------|---------|
| `lib/core/session.dart` | Main session management with Google OAuth |
| `lib/services/google_auth_service.dart` | Google auth utility service |
| `lib/presentation/auth/pages/login_page.dart` | User login UI |
| `flutter_admin_dashboard/lib/providers/auth_provider.dart` | Admin auth state |
| `flutter_admin_dashboard/lib/screens/login_screen.dart` | Admin login UI |

## 🔧 Configuration Checklist

### Google Cloud Console
- [ ] Create OAuth 2.0 credentials
- [ ] Add redirect URIs: `https://YOUR_SUPABASE_URL/auth/v1/callback`
- [ ] Copy Client ID
- [ ] For mobile: Get SHA-1 certificate fingerprint
  ```bash
  ./gradlew signingReport  # Android
  ```

### Supabase Dashboard
- [ ] Enable Google provider
- [ ] Paste Google Client ID
- [ ] Verify callback URL

### Flutter App
- [ ] Add `google_sign_in: ^6.1.6` to pubspec.yaml
- [ ] Android: Update `android/app/build.gradle` (compileSdkVersion 34+)
- [ ] iOS: Add URL scheme to `ios/Runner/Info.plist`
- [ ] Web: Add meta tag to `web/index.html`
- [ ] Run `flutter pub get`

## 🐛 Common Issues & Fixes

### "Google sign-in cancelled"
✅ **This is normal** - User closed the login dialog

### "Failed to get authentication tokens"
- Check Google OAuth credentials are correct
- Verify Client ID in Supabase matches Google Cloud Console
- Ensure APIs are enabled in Google Cloud Console

### "Failed to authenticate with Supabase"
- Verify Google provider is enabled in Supabase
- Check Supabase URL and Anon Key in `.env`
- Ensure callback URL matches in both platforms

### Android: "PlatformException"
- Add app's SHA-1 fingerprint to Google Cloud Console
- Run: `./gradlew signingReport`
- Ensure minimum SDK is 21+

### iOS: "NSInvalidArgumentException"
- Add Google Sign-In URL scheme to `Info.plist`
- Update CocoaPods: `pod repo update && pod install`

## 📊 Architecture

```
┌─────────────────────────────────────┐
│   Flutter App (UI Layer)            │
│  - login_page.dart (User)           │
│  - login_screen.dart (Admin)        │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│   Application Layer                 │
│  - UserSession (Main app)           │
│  - AuthProvider (Admin)             │
│  - GoogleAuthService (Utility)      │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│   Google Sign-In Library            │
│  - google_sign_in ^6.1.6            │
└────────────────┬────────────────────┘
                 │
                 ▼
        ┌────────────────┐
        │  Google OAuth  │
        │   Servers      │
        └────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  Supabase                           │
│  - Authentication                   │
│  - User Management                  │
│  - Database (users, shops)          │
└─────────────────────────────────────┘
```

## 🔐 Security Notes

✅ **Passwords Never Stored Locally**
- Google handles all password security
- Your app only receives ID tokens

✅ **Token Management Automated**
- Supabase automatically manages access tokens
- Refresh tokens stored securely locally
- Tokens auto-expire based on configuration

✅ **2FA Available**
- Users can enable 2FA via their Google Account
- Works transparently with this app

✅ **Account Recovery**
- Users recover accounts via Google
- No email verification needed from app

## 📈 User Flow Diagram

```
App Start
    ↓
User Logged In? ← Check LocalStorage
    ├─ Yes → MainLayout (Dashboard)
    └─ No ↓
        LoginPage (Google Button)
            ↓
        User Taps "Sign in with Google"
            ↓
        Google Login Dialog
            ├─ User Cancels → Back to LoginPage
            └─ User Authenticates ↓
                Get ID Token from Google
                    ↓
                Send Token to Supabase
                    ↓
                Supabase Validates & Creates User
                    ↓
                Fetch User Data from Database
                    ↓
                Save to LocalStorage
                    ↓
                Navigate to MainLayout (Dashboard)
```

## 🧪 Testing Checklist

- [ ] App starts with login screen
- [ ] "Sign in with Google" button visible and clickable
- [ ] Google login dialog appears when tapped
- [ ] Can authenticate with test Google account
- [ ] User data appears in Supabase Console
- [ ] App navigates to main dashboard
- [ ] Session persists on app restart
- [ ] Logout clears session properly
- [ ] Multiple logins work correctly
- [ ] Error messages display appropriately
- [ ] Admin dashboard login also works
- [ ] Tested on Android, iOS, and Web

## 📚 Resources

- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Google Sign-In Package](https://pub.dev/packages/google_sign_in)
- [Google OAuth Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Flutter Security Best Practices](https://flutter.dev/docs/testing/best-practices)

## ✨ What's Next?

After successful Google OAuth implementation:

1. **Email Notifications**
   - Send welcome emails via Supabase
   - Setup email templates

2. **User Profiles**
   - Add profile picture from Google
   - Allow profile editing

3. **Analytics**
   - Track sign-up sources
   - Monitor authentication success rates

4. **Additional Auth Methods**
   - Apple Sign-In (iOS)
   - GitHub Sign-In (developers)
   - Phone Number Auth (optional)

5. **Advanced Features**
   - Social account linking
   - Biometric authentication
   - Risk-based authentication

---

**Last Updated**: May 13, 2026  
**Status**: Ready for Production ✅
