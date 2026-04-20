import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dukansathi_admin_dashboard/main.dart';
import 'package:dukansathi_admin_dashboard/providers/auth_provider.dart';
import 'package:dukansathi_admin_dashboard/providers/data_provider.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DataProvider()),
        ],
        child: const AdminDashboardApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dukan Sathi Admin'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
