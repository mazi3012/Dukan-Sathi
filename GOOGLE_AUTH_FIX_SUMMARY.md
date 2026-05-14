# Google Sign-In Fix Summary

## Issue
The app was throwing `TypeError: Cannot read properties of null (reading 'toString')` when clicking "Sign in with Google", followed by CORS errors and Google OAuth `origin_mismatch` errors.

## Root Causes Identified
1. **Null-Assert Operators**: Code used `!` null-asserts on `idToken`, `response.user` without defensive checks, causing crashes if values were null.
2. **Missing Web Configuration**: Google client ID not configured in `web/index.html` or Supabase.
3. **Google OAuth Origin Mismatch**: JavaScript origin and redirect URIs not registered in Google Cloud Console.
4. **No Debug Logging**: Difficult to diagnose where the null values originated.

## Fixes Applied

### 1. Code Defensiveness (lib/services/google_auth_service.dart, lib/core/session.dart)
- Replaced `!` null-asserts with local variables and defensive null checks.
- Added `debugPrint()` logging to capture `googleUser`, auth tokens, and Supabase `response.user`.
- Return clear error messages instead of crashing on null.

**Example:**
```dart
// Before: risk of crash
idToken: googleAuth.idToken!,

// After: safe
final idToken = googleAuth.idToken;
if (idToken == null || idToken.isEmpty) {
  return {'success': false, 'error': 'Failed to get tokens'};
}
```

### 2. UI Error Handling (lib/presentation/auth/pages/login_page.dart)
- Added try/catch around `loginWithGoogle()` call.
- Guard against null or non-map responses.
- Display user-friendly error messages.

### 3. Web Configuration (web/index.html)
- Added Google Identity Services (GSI) meta tag with client ID:
  ```html
  <meta name="google-signin-client_id" content="648987320349-asplif3bmr9ai0k3lkp9ulth5gne9eru.apps.googleusercontent.com">
  <script src="https://accounts.google.com/gsi/client" async defer></script>
  ```

### 4. Local Supabase Config (supabase/config.toml)
- Added Google OAuth provider config:
  ```toml
  [auth.external.google]
  enabled = true
  client_id = "648987320349-asplif3bmr9ai0k3lkp9ulth5gne9eru.apps.googleusercontent.com"
  skip_nonce_check = true
  ```

## Google Cloud Console Setup

### Authorised JavaScript Origins
- ✅ http://localhost:8080 (local testing)
- ⚠️ **TODO**: Add https://www.dukansathi.com (production)

### Authorised Redirect URIs
- ✅ https://owvtyqccmiurlwwpocoj.supabase.co/auth/v1/callback

**Note:** Google may take 5 minutes to several hours for settings to take effect.

## Supabase Configuration

### Google Provider
- **Status**: Requires manual setup in Supabase dashboard.
- **Location**: Project → Authentication → External OAuth Providers → Google
- **Required**: 
  - Client ID: 648987320349-asplif3bmr9ai0k3lkp9ulth5gne9eru.apps.googleusercontent.com
  - Client Secret: (create in Google Console → copy to Supabase)

## Testing Checklist

- [ ] Wait 5+ minutes for Google Console settings to propagate
- [ ] Clear browser cache and cookies
- [ ] Reload http://localhost:8080
- [ ] Click "Sign in with Google"
- [ ] Check browser DevTools Console for debug logs:
  - `[GoogleAuthService] googleUser: ...`
  - `[GoogleAuthService] googleAuth tokens: hasId=true hasAccess=true`
  - `[GoogleAuthService] supabase response.user: <user-id>`
- [ ] Verify successful login or capture any remaining errors
- [ ] Test on production (https://www.dukansathi.com) after adding to Google Console origins

## Deployment

### Local Build
```bash
export SUPABASE_URL="https://owvtyqccmiurlwwpocoj.supabase.co"
export SUPABASE_ANON_KEY="<your-anon-key>"
./vercel-build.sh
python3 -m http.server 8080 -d build/web
```

### Production Deployment
- Changes already pushed to `main` branch.
- Vercel auto-deploy (if linked) or manual deploy via dashboard.
- Ensure Google Console has https://www.dukansathi.com in Authorised JavaScript origins.

## Commits
1. `fix(auth): avoid null-asserts in Google sign-in, add defensive checks and logging`
2. `fix(ui): guard against null auth responses in LoginPage`
3. `chore(auth): add web GSI snippet and debug logging for Google auth flow`
4. `chore(auth): add Google client ID to web index and supabase local config`

## Next Steps
1. ✅ **Now**: Google Console settings are configured for localhost:8080.
2. **Wait**: 5+ minutes for propagation.
3. **Test**: Reload http://localhost:8080, try sign-in, capture logs.
4. **Add Production Domain**: Add https://www.dukansathi.com to Google Console origins.
5. **Configure Supabase**: Set up Google provider in Supabase dashboard with client secret.
6. **Deploy**: Push to production and test.

## Security Notes
- **DO NOT commit secrets** to the repository (client secrets, API keys).
- Use environment variables or Supabase secret manager for secrets.
- Rotate any keys that were accidentally exposed (Supabase anon keys, etc.).

## Debug Commands

If needed, you can inspect the browser DevTools Console output:
```javascript
// Manual test in browser console:
// (if using Dart's google_sign_in or if you implement web sign-in separately)
console.log('Google client ID loaded:', window.gapi?.auth2?.getAuthInstance?.());
```

## References
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Google Sign-In for Web](https://developers.google.com/identity/sign-in/web)
- [Supabase Google Auth](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Flutter google_sign_in package](https://pub.dev/packages/google_sign_in)
