# Phase 2: Admin Dashboard UI - Quick Start Guide

## 🚀 Get Started in 4 Steps

### Step 1: Install Dependencies
```bash
cd /workspaces/dukansathi-new/flutter_admin_dashboard
/opt/flutter/bin/flutter pub get
```

### Step 2: Ensure Backend is Running
```bash
# Backend API should be running on port 3100
cd /workspaces/dukansathi-new
/workspaces/dukansathi-new/.tooling/dart-sdk/bin/dart run bin/genkit_server.dart

# In another terminal verify:
curl -s http://localhost:3100/api/admin/roles | jq -r '.data | length'

# Expected response: 4
```

### Step 3: Build Flutter Web Dashboard
```bash
cd /workspaces/dukansathi-new/flutter_admin_dashboard
/opt/flutter/bin/flutter build web --web-renderer html --release
```

### Step 4: Serve Dashboard on Port 5000
```bash
cd /workspaces/dukansathi-new/flutter_admin_dashboard
python3 serve_with_cors.py
```

This serves the compiled `build/web` output with required CORS headers.

**Dashboard URL:** http://localhost:5000

---

## 🔐 Login Credentials

**Demo Account:**
- Email: `admin@dukansathi.com`
- Password: `demo123`

---

## 📱 What You'll See

### Login Screen
- Clean, professional login form
- Email/password validation
- Demo credentials hint
- Loading state during authentication

### Dashboard
- Welcome message
- 4 stats cards (Users, Roles, Permissions, Audit Logs)
- Quick access buttons
- Sidebar navigation (desktop) or drawer (mobile)

### Navigation Menu
- 📊 Dashboard (Home)
- 👥 Users (Management)
- 🔐 Roles & Permissions
- 📋 Audit Log
- ⚙️ Settings

---

## ✨ Features to Explore

### Users Management
- ✅ View all admin users from database
- ✅ Create new users with role selection
- ✅ Edit user details
- ✅ Deactivate users
- Real-time data from API

### Roles & Permissions
- ✅ View all 4 default roles
- ✅ See all 11 permissions grouped by resource
- ✅ View role descriptions
- Ready for editing/creation

### Audit Log
- ✅ Complete activity history
- ✅ Expandable entries with details
- ✅ Status indicators
- Real-time data from API

### Settings
- ✅ System information
- ✅ Security options
- ✅ User preferences
- ✅ Documentation links

---

## 🔄 Hot Reload

Make changes and see them instantly:
```bash
# While app is running in terminal, press 'r'
r  - Hot reload
R  - Hot restart
q  - Quit
```

---

## 🛠️ Debugging

### Check Network Requests
1. Open Chrome DevTools (F12)
2. Go to Network tab
3. Login and make actions
4. Watch API calls to backend admin endpoints (`/api/admin/*`)

### View Console Logs
1. Press `q` in terminal to pause
2. Check logs in Chrome DevTools Console

---

## 📍 API Endpoints Connected

The app is connected to these Phase 1 API endpoints:

| Feature | Endpoint | Status |
|---------|----------|--------|
| Roles | `GET /api/admin/roles` | ✅ Connected |
| Permissions | `GET /api/admin/permissions` | ✅ Connected |
| Users | `GET /api/admin/users` | ✅ Connected |
| Create User | `POST /api/admin/users` | ✅ Connected |
| Update User | `PUT /api/admin/users/{id}` | ✅ Connected |
| Deactivate User | `DELETE /api/admin/users/{id}` | ✅ Connected |
| Audit Log | `GET /api/admin/audit-log` | ✅ Connected |

---

## 🐛 Troubleshooting

### "Connection refused" Error
Make sure backend is running:
```bash
# Check if port 3100 is listening
curl http://localhost:3100/api/admin/roles
```

### Flutter Not Found
Make sure Flutter is in PATH:
```bash
/opt/flutter/bin/flutter --version
```

### Port 5000 Already in Use
Restart the frontend server:
```bash
pkill -f "serve_with_cors.py" || true
cd /workspaces/dukansathi-new/flutter_admin_dashboard
python3 serve_with_cors.py
```

### Codespaces CORS or Service Worker Errors
If you see `FetchEvent failed`, `manifest.json` CORS errors, or `Uncaught Error` from stale assets:
```bash
# Rebuild latest frontend bundle
cd /workspaces/dukansathi-new/flutter_admin_dashboard
/opt/flutter/bin/flutter build web --web-renderer html --release

# Restart frontend server
pkill -f "serve_with_cors.py" || true
python3 serve_with_cors.py
```

Then hard-refresh browser (`Ctrl+Shift+R` / `Cmd+Shift+R`).

### Dependencies Issues
Clear and reinstall:
```bash
flutter clean
flutter pub get
```

---

## 📸 What to Test

After login, try these:

1. **Dashboard Stats**
   - Should showing real numbers from database
   - Click stats cards (will navigate to screens)

2. **Create User**
   - Go to Users → Add User button
   - Fill in all fields
   - Select a role
   - Click Create
   - New user appears in table

3. **View Roles**
   - Go to Roles & Permissions → Roles tab
   - Should see 4 cards:
     - super_admin
     - shop_owner
     - inventory_manager
     - viewer

4. **View Permissions**
   - Go to Roles & Permissions → Permissions tab
   - Should see 11 permissions grouped by resource

5. **View Audit Log**
   - Go to Audit Log
   - See time-stamped entries
   - Click to expand details

---

## 🎯 Next Steps

### To Customize:
1. Edit theme colors in `lib/config/theme.dart`
2. Modify layouts in respective screen files
3. Change API base URL in `lib/services/api_service.dart`

### To Add Features:
1. Create new screen in `lib/screens/`
2. Add route in `lib/config/routes.dart`
3. Update `DataProvider` if needed
4. Add navigation item in `dashboard_screen.dart`

### To Connect Real Authentication:
1. Implement real login endpoint in `AuthProvider`
2. Hash passwords with bcrypt or argon2
3. Use JWT tokens instead of demo tokens
4. Add token refresh logic

---

## 📚 Reference

- **Flutter Docs:** https://flutter.dev/docs
- **Provider Docs:** https://pub.dev/packages/provider
- **GoRouter Docs:** https://pub.dev/packages/go_router
- **Material 3:** https://m3.material.io/

---

## ✅ Phase 2 Complete!

You now have a fully functional admin dashboard UI connected to your Phase 1 backend API!

🎉 Ready for user testing!
