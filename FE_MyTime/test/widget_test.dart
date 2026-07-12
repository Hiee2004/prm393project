import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/screens/focus_timer_screen.dart';
import 'package:project/screens/home_screen.dart';
import 'package:project/screens/statistics_screen.dart';
import 'package:project/screens/task_list_screen.dart';
import 'package:project/services/my_time_store.dart';

void main() {
  testWidgets('Home screen focuses on the MyTime workflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    );

    expect(find.text('MyTime'), findsOneWidget);
    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('Upcoming Tasks'), findsOneWidget);
  });

  testWidgets('Focus session sends completed output to results', (
    tester,
  ) async {
    final store = MyTimeStore.instance;
    final task = await store.addTask(
      title: 'Focus timer test task',
      description: 'Used by widget test',
      focusMinutes: 25,
      priority: TaskPriority.high,
      scheduledDate: DateTime.now(),
      outputs: const [
        'Complete the Focus Time screen',
        'Review notes',
        'Share recap',
      ],
    );
    store.selectTask(task);

    addTearDown(() async {
      await store.deleteTask(task);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const FocusTimerScreen(),
        routes: {
          AppRoutes.statistics: (_) => const StatisticsScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
        },
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Start'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Pause'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Complete the Focus Time screen'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(CheckboxListTile).first);

    await tester.scrollUntilVisible(
      find.text('Finish and view results'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Finish and view results'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Latest session'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Latest session'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Complete the Focus Time screen'), findsOneWidget);
  });

  test('Store supports create, update and delete task', () async {
    final store = MyTimeStore.instance;
    final plannedDate = DateTime(2026, 6, 20);

    final task = await store.addTask(
      title: 'CRUD task',
      description: 'Create task',
      focusMinutes: 25,
      priority: TaskPriority.low,
      scheduledDate: plannedDate,
      repeat: TaskRepeat.weekly,
      reminderEnabled: true,
      reminderTime: '08:30:00',
      outputs: ['Output A'],
    );

    expect(store.tasks.contains(task), isTrue);
    expect(task.occursOn(plannedDate.add(const Duration(days: 7))), isTrue);

    await store.updateTask(
      task: task,
      title: 'Updated CRUD task',
      description: 'Updated task',
      focusMinutes: 45,
      priority: TaskPriority.high,
      status: FocusTaskStatus.processing,
      scheduledDate: plannedDate,
      repeat: TaskRepeat.monthly,
      reminderEnabled: true,
      reminderTime: '10:00:00',
      outputs: ['Output A', 'Output B'],
    );

    expect(task.title, 'Updated CRUD task');
    expect(task.status, FocusTaskStatus.processing);
    expect(task.priority, TaskPriority.high);
    expect(task.outputs.length, 2);
    expect(task.repeat, TaskRepeat.monthly);
    expect(task.reminderTime, '10:00:00');

    await store.deleteTask(task);
    expect(store.tasks.contains(task), isFalse);
  });

  testWidgets('Task list filters by status and priority', (tester) async {
    final store = MyTimeStore.instance;

    final processingHigh = await store.addTask(
      title: 'Processing high task',
      description: 'Visible after both filters',
      focusMinutes: 25,
      priority: TaskPriority.high,
      outputs: ['Output'],
    );

    final todoHigh = await store.addTask(
      title: 'Todo high task',
      description: 'Hidden by status filter',
      focusMinutes: 25,
      priority: TaskPriority.high,
      outputs: ['Output'],
    );

    store.startTask(processingHigh);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const TaskListScreen(),
        routes: {
          AppRoutes.addTask: (_) => const SizedBox(),
          AppRoutes.taskDetail: (_) => const SizedBox(),
          AppRoutes.focus: (_) => const SizedBox(),
          AppRoutes.home: (_) => const SizedBox(),
          AppRoutes.statistics: (_) => const SizedBox(),
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('filter-In progress')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('filter-High priority')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Processing high task'), findsOneWidget);
    expect(find.text('Todo high task'), findsNothing);

    await store.deleteTask(processingHigh);
    await store.deleteTask(todoHigh);
  });
}
