import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/screens/focus_timer_screen.dart';
import 'package:project/screens/home_screen.dart';

void main() {
  testWidgets('Home screen shows basic dashboard content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    );

    expect(find.text('Hello, Alex'), findsOneWidget);
    expect(find.text('Quick access'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Next task'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Next task'), findsOneWidget);
  });

  testWidgets('Focus timer starts and counts down', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const FocusTimerScreen()),
    );

    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('24:59'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
