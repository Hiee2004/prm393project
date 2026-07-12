import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/screens/register_screen.dart';
import 'package:project/services/session_store.dart';
import 'package:project/services/user_api_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('register reaches backend and returns an authenticated user', (
    tester,
  ) async {
    const testEmail = 'codex.e2e@mytime.invalid';

    await tester.pumpWidget(
      MaterialApp(home: const RegisterScreen(), routes: AppRoutes.routes),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(0), 'Codex E2E');
    await tester.enterText(fields.at(1), testEmail);
    await tester.enterText(fields.at(2), 'Test123!');
    await tester.enterText(fields.at(3), 'Test123!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));

    for (var attempt = 0; attempt < 80; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('MyTime').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('MyTime'), findsOneWidget);

    final token = SessionStore.instance.token;
    expect(token, isNotNull);
    expect(token, isNotEmpty);

    final user = await UserApiService().getMe(token!);
    expect(user['email'], testEmail);
  });
}
