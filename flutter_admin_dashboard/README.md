# Flutter Admin Dashboard - Web Configuration

## Project Structure

```
flutter_admin_dashboard/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   ├── app_config.dart      # App configuration
│   │   ├── theme.dart           # Material theme
│   │   └── routes.dart          # Route definitions
│   ├── models/
│   │   ├── admin_user.dart
│   │   ├── admin_role.dart
│   │   └── admin_session.dart
│   ├── services/
│   │   ├── api_client.dart      # HTTP client
│   │   └── auth_service.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── users/
│   │   │   ├── users_list_screen.dart
│   │   │   ├── user_detail_screen.dart
│   │   │   └── create_user_screen.dart
│   │   ├── inventory/
│   │   │   ├── inventory_list_screen.dart
│   │   │   ├── inventory_detail_screen.dart
│   │   │   └── edit_item_screen.dart
│   │   ├── analytics/
│   │   │   └── analytics_screen.dart
│   │   ├── audit_log/
│   │   │   └── audit_log_screen.dart
│   │   └── settings/
│   │       ├── shop_settings_screen.dart
│   │       └── admin_settings_screen.dart
│   ├── widgets/
│   │   ├── layout/
│   │   │   ├── admin_layout.dart
│   │   │   ├── sidebar.dart
│   │   │   └── header.dart
│   │   ├── common/
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_dialog.dart
│   │   │   └── data_table.dart
│   │   └── forms/
│   │       ├── user_form.dart
│   │       ├── item_form.dart
│   │       └── form_field.dart
│   └── utils/
│       ├── constants.dart
│       ├── validators.dart
│       └── extensions.dart
├── web/
│   ├── index.html
│   ├── manifest.json
│   └── favicon.ico
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
└── test/
    └── widget_test.dart
```

## Environment Setup

### Development
```bash
cd flutter_admin_dashboard
flutter pub get
flutter run -d chrome
```

### Production Build
```bash
flutter build web --release
```

## Features Roadmap

### Phase 1 (Current)
- ✅ Project structure
- ✅ Configuration
- □ Login screen UI
- □ API client integration

### Phase 2
- □ Dashboard layout
- □ User management UI
- □ Inventory management UI
- □ Role/permission management

### Phase 3
- □ Analytics dashboard
- □ Audit log viewer
- □ Shop settings
- □ Report generation

### Phase 4
- □ Real-time updates with WebSocket
- □ Advanced filters and search
- □ Bulk operations
- □ Export functionality

## API Integration

The dashboard connects to:
- **Backend URL:** http://localhost:3100
- **API Base:** /api/admin/
- **Auth:** Token-based (session tokens)

## State Management

Using Provider for:
- Auth state (login, logout, permissions)
- User list state
- Inventory state
- Notification state

## Key Dependencies

- **go_router:** Client-side routing
- **provider:** State management
- **dio:** HTTP client with interceptors
- **freezed:** Code generation for models
- **shared_preferences:** Local storage for tokens

## Development Notes

1. **Authentication Flow:**
   - Login endpoint returns token
   - Token stored in SharedPreferences
   - Token added to all subsequent requests
   - Token refresh handled automatically

2. **Permission Checks:**
   - Fetch user permissions after login
   - Hide/disable UI based on permissions
   - Validate actions on backend

3. **Error Handling:**
   - Global error handling in API client
   -Show relevant error messages to user
   - Log errors for debugging

## Running the Dashboard

### Start Backend
```bash
cd /workspaces/dukansathi-new
dart run bin/genkit_server.dart  # Runs on port 3100
```

### Start Frontend
```bash
cd /workspaces/dukansathi-new/flutter_admin_dashboard
flutter run -d chrome
```

Admin dashboard will be available at: `http://localhost:5000`

## Testing

Run unit tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test/
```
