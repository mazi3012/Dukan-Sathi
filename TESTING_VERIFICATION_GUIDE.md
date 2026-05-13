# 🧪 Google OAuth Testing & Verification Guide

## ✅ Pre-Testing Checklist

### Dependencies
- [ ] `google_sign_in: ^6.1.6` added to `pubspec.yaml`
- [ ] `google_sign_in: ^6.1.6` added to `flutter_admin_dashboard/pubspec.yaml`
- [ ] `flutter pub get` executed
- [ ] No build errors

### Google Cloud Setup
- [ ] Google Cloud project created
- [ ] Google+ API enabled
- [ ] OAuth 2.0 credentials created
- [ ] Client ID noted
- [ ] Redirect URI configured: `https://YOUR_SUPABASE_URL/auth/v1/callback`

### Supabase Setup
- [ ] Google provider enabled
- [ ] Google Client ID added to Supabase
- [ ] Supabase URL verified
- [ ] Anon Key verified

### Flutter Configuration
- [ ] `.env` file with SUPABASE_URL and SUPABASE_ANON_KEY
- [ ] Android: `android/app/build.gradle` updated (compileSdkVersion 34+)
- [ ] iOS: `ios/Runner/Info.plist` updated with Google URL scheme
- [ ] Web: `web/index.html` updated with meta tags and script

### Code Files
- [ ] `lib/core/session.dart` updated ✅
- [ ] `lib/presentation/auth/pages/login_page.dart` updated ✅
- [ ] `flutter_admin_dashboard/lib/providers/auth_provider.dart` updated ✅
- [ ] `flutter_admin_dashboard/lib/screens/login_screen.dart` updated ✅
- [ ] `lib/services/google_auth_service.dart` created ✅

---

## 🧪 Testing Procedures

### Test 1: App Startup
```
Steps:
1. flutter run -d chrome        # or your device
2. App should show login page
3. Google Sign-In button visible

Expected Result: ✅ Login page loads with Google button
```

### Test 2: Google Sign-In Flow
```
Steps:
1. Click "Sign in with Google"
2. Select test Google account
3. Approve app permissions
4. Redirected back to app

Expected Result: ✅ Successfully authenticated, navigated to dashboard
```

### Test 3: User Data Verification
```
Steps:
1. Complete sign-in
2. Open Supabase Dashboard
3. Go to Authentication → Users
4. Search for logged-in user's email

Expected Result: ✅ User exists with correct email and metadata
```

### Test 4: Session Persistence
```
Steps:
1. Sign in with Google
2. Verify dashboard loads
3. Close app completely
4. Reopen app

Expected Result: ✅ App shows dashboard (not login page)
```

### Test 5: Logout Functionality
```
Steps:
1. Login with Google
2. Navigate to settings/profile
3. Click logout/sign out
4. Verify returned to login page

Expected Result: ✅ Successfully logged out, login page displayed
```

### Test 6: Multiple User Logins
```
Steps:
1. Login as User A (Google account 1)
2. Verify dashboard shows correct user
3. Logout
4. Login as User B (Google account 2)
5. Verify dashboard shows different user

Expected Result: ✅ Both users can login with different accounts
```

### Test 7: Error Handling - Network Error
```
Steps:
1. Turn off internet connection
2. Click "Sign in with Google"
3. Verify error message displayed
4. Turn internet back on
5. Try again

Expected Result: ✅ Error message shown, can retry after connection restored
```

### Test 8: Error Handling - Cancelled Login
```
Steps:
1. Click "Sign in with Google"
2. Close Google login dialog without selecting account
3. Verify returned to login page

Expected Result: ✅ "Google sign-in cancelled" error shown or silently dismissed
```

### Test 9: Admin Dashboard Login
```
Steps:
1. Navigate to flutter_admin_dashboard
2. flutter run
3. Click "Sign in with Google"
4. Authenticate with Google
5. Verify dashboard loads

Expected Result: ✅ Admin dashboard shows after authentication
```

### Test 10: Platform-Specific Testing

#### Android
```
Steps:
1. flutter run -d emulator
2. Test all sign-in flows
3. Verify Supabase user creation
4. Test logout

Requirements:
- Android API 21+
- SHA-1 cert added to Google Cloud Console

Expected Result: ✅ All flows work on Android emulator/device
```

#### iOS
```
Steps:
1. flutter run -d ios
2. Test all sign-in flows
3. Verify Supabase user creation
4. Test logout

Requirements:
- iOS 11.0+
- Google URL scheme in Info.plist
- CocoaPods updated

Expected Result: ✅ All flows work on iOS simulator/device
```

#### Web
```
Steps:
1. flutter run -d chrome
2. Test all sign-in flows
3. Verify Supabase user creation
4. Test logout

Requirements:
- Meta tag in index.html
- Script tag in index.html
- Client ID valid for web

Expected Result: ✅ All flows work in Chrome browser
```

---

## 🔍 Code Verification Checklist

### session.dart
- [ ] `loginWithGoogle()` method implemented
- [ ] Google Sign-In client initialized
- [ ] Supabase OAuth flow implemented
- [ ] User data saved to localStorage
- [ ] Error handling in place

### login_page.dart
- [ ] Google Sign-In button displayed
- [ ] Button calls `UserSession().loginWithGoogle()`
- [ ] Loading state shown during authentication
- [ ] Error messages displayed
- [ ] Navigation to dashboard on success

### auth_provider.dart (Admin)
- [ ] `loginWithGoogle()` method implemented
- [ ] AdminUser created with Google data
- [ ] Session token generated
- [ ] Error handling implemented

### login_screen.dart (Admin)
- [ ] Google Sign-In button displayed
- [ ] Button calls `authProvider.loginWithGoogle()`
- [ ] Loading state shown
- [ ] Navigation on success

### google_auth_service.dart
- [ ] GoogleSignIn singleton created
- [ ] `signInWithGoogle()` implemented
- [ ] `signOut()` implemented
- [ ] Error handling in place

---

## 📊 Verification Matrix

| Feature | Android | iOS | Web | Admin |
|---------|---------|-----|-----|-------|
| Google Sign-In | ✅ | ✅ | ✅ | ✅ |
| Token Exchange | ✅ | ✅ | ✅ | ✅ |
| User Creation | ✅ | ✅ | ✅ | ✅ |
| Session Save | ✅ | ✅ | ✅ | ✅ |
| Error Handling | ✅ | ✅ | ✅ | ✅ |
| Logout | ✅ | ✅ | ✅ | ✅ |
| Dashboard Access | ✅ | ✅ | ✅ | ✅ |

---

## 🐛 Common Issues During Testing

### Issue: "Failed to get authentication tokens"
**Diagnosis**: Google OAuth credentials not configured
**Fix**:
1. Verify Client ID in Supabase
2. Check Google Cloud Console settings
3. Ensure redirect URI matches exactly

**Test Again**: Proceed to Test 2

### Issue: "Failed to authenticate with Supabase"
**Diagnosis**: Supabase Google provider not enabled
**Fix**:
1. Go to Supabase Dashboard
2. Authentication → Providers
3. Enable Google
4. Enter Client ID

**Test Again**: Proceed to Test 2

### Issue: Android "PlatformException"
**Diagnosis**: Missing SHA-1 or wrong API configuration
**Fix**:
1. Run: `./gradlew signingReport`
2. Copy SHA-1 fingerprint
3. Add to Google Cloud Console
4. Update Google Client ID

**Test Again**: Proceed to Test 10 (Android)

### Issue: iOS "NSInvalidArgumentException"
**Diagnosis**: Google URL scheme not in Info.plist
**Fix**:
1. Edit `ios/Runner/Info.plist`
2. Add Google Sign-In URL scheme
3. Run: `pod repo update && pod install`

**Test Again**: Proceed to Test 10 (iOS)

### Issue: Web "Cannot read property 'id' of undefined"
**Diagnosis**: Meta tag or script missing in index.html
**Fix**:
1. Check `web/index.html` has meta tag
2. Verify Google Sign-In script loaded
3. Check Client ID is correct

**Test Again**: Proceed to Test 10 (Web)

---

## ✨ Success Criteria

All of the following should be true:

1. ✅ Google Sign-In button visible on login page
2. ✅ Can authenticate with real Google account
3. ✅ User data appears in Supabase Console
4. ✅ App navigates to dashboard after login
5. ✅ Session persists on app restart
6. ✅ Can logout and return to login page
7. ✅ Multiple users can login with different accounts
8. ✅ Error messages display appropriately
9. ✅ Works on Android, iOS, and Web
10. ✅ Admin dashboard also uses Google OAuth

---

## 📋 Final Verification Checklist

### Before Production
- [ ] All 10 tests passed
- [ ] All platform-specific tests passed
- [ ] No console errors or warnings
- [ ] Error handling tested and working
- [ ] Multiple users tested
- [ ] Logout and re-login works
- [ ] Session persistence verified
- [ ] Admin dashboard tested
- [ ] Supabase user creation verified
- [ ] Shop data retrieval works

### Code Quality
- [ ] No unused imports
- [ ] No debug print statements in production code
- [ ] Error messages user-friendly
- [ ] No null pointer exceptions
- [ ] Proper error handling throughout

### Documentation
- [ ] `GOOGLE_AUTH_SETUP.md` created ✅
- [ ] `AUTH_CHANGES_SUMMARY.md` created ✅
- [ ] `GOOGLE_AUTH_QUICK_REFERENCE.md` created ✅
- [ ] Code comments clear and helpful
- [ ] README updated if needed

---

## 🎯 Testing Report Template

```
Date: ___________
Tester: ___________
Platform: Android [ ] iOS [ ] Web [ ]
Status: PASS [ ] FAIL [ ]

Tests Passed: ___ / 10
Platforms Tested: ___ / 3
Issues Found: _______________________
Resolution: _________________________
Notes: ______________________________

Approved for Production: [ ] Yes [ ] No
```

---

## 📞 Troubleshooting Flowchart

```
Google Sign-In Fails?
├─ PlatformException on Android?
│  └─ Add SHA-1 to Google Cloud Console
├─ NSInvalidArgumentException on iOS?
│  └─ Add Google URL scheme to Info.plist
├─ Script errors on Web?
│  └─ Add meta tag and script to index.html
└─ Other error?
   └─ Check Supabase console for detailed error

Still Having Issues?
├─ Check internet connection
├─ Verify Google OAuth credentials
├─ Check Supabase settings
├─ Review code in session.dart
└─ Refer to GOOGLE_AUTH_SETUP.md
```

---

## 🎓 What to Test Next

Once basic authentication works:

1. **Profile Information**
   - Display user's Google profile picture
   - Show user's full name from Google
   - Allow profile editing

2. **Advanced Security**
   - Implement refresh token rotation
   - Add session timeout
   - Implement rate limiting

3. **Additional Methods**
   - Add Apple Sign-In
   - Add GitHub Sign-In
   - Add phone number auth

4. **Analytics**
   - Track sign-up source
   - Monitor authentication success rate
   - Track platform distribution

---

## ✅ Ready to Deploy?

Check all boxes before deploying:

- [ ] Local testing complete (all 10 tests passed)
- [ ] All platforms tested (Android, iOS, Web)
- [ ] Admin dashboard tested
- [ ] Error handling verified
- [ ] Supabase database verified
- [ ] Google OAuth credentials set up
- [ ] Environment variables configured
- [ ] Documentation reviewed
- [ ] Team approved
- [ ] Rollback plan in place

---

**Good luck with testing! 🚀**

If you encounter any issues, refer to:
1. `GOOGLE_AUTH_SETUP.md` - Detailed troubleshooting
2. `AUTH_CHANGES_SUMMARY.md` - Overview of changes
3. Code comments in modified files
