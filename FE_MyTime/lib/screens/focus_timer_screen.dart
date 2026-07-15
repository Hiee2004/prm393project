import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/custom_focus_audio.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/focus_notification_service.dart';
import 'package:project/services/focus_audio_service.dart';
import 'package:project/services/applied_smart_plan_store.dart';
import 'package:project/services/focus_audio_library_store.dart';
import 'package:project/services/focus_timer_draft_store.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';
import 'package:project/services/focus_session_api_service.dart';
import 'package:project/services/session_store.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _focusTemplates = [
    _FocusTemplate(
      id: 'pomodoro',
      label: 'Pomodoro',
      focusMinutes: 25,
      breakMinutes: 5,
      icon: Icons.timelapse_rounded,
      description: 'Classic short focus burst.',
    ),
    _FocusTemplate(
      id: 'study',
      label: 'Study',
      focusMinutes: 50,
      breakMinutes: 10,
      icon: Icons.menu_book_rounded,
      description: 'Balanced study sprint.',
    ),
    _FocusTemplate(
      id: 'deep_work',
      label: 'Deep Work',
      focusMinutes: 90,
      breakMinutes: 15,
      icon: Icons.psychology_alt_rounded,
      description: 'Long, high-concentration block.',
    ),
    _FocusTemplate(
      id: 'ultra_focus',
      label: 'Ultra Focus',
      focusMinutes: 120,
      breakMinutes: 20,
      icon: Icons.bolt_rounded,
      description: 'Extended intense session.',
    ),
  ];

  static const _builtInSoundProfiles = [
    _FocusSoundProfile(
      id: 'off',
      label: 'Silent',
      icon: Icons.volume_off_rounded,
      description: 'No ambient layer.',
      accent: AppColors.textMuted,
    ),
    _FocusSoundProfile(
      id: 'rain',
      label: 'Rain',
      icon: Icons.water_drop_rounded,
      description: 'Soft rain for calm focus.',
      accent: Color(0xFF4F8DFF),
      assetPath: 'audio/rain_loop.wav',
    ),
    _FocusSoundProfile(
      id: 'cafe',
      label: 'Cafe',
      icon: Icons.local_cafe_rounded,
      description: 'Warm public-space energy.',
      accent: Color(0xFFC17A2D),
      assetPath: 'audio/cafe_loop.wav',
    ),
    _FocusSoundProfile(
      id: 'white_noise',
      label: 'White Noise',
      icon: Icons.graphic_eq_rounded,
      description: 'Neutral mask for distractions.',
      accent: Color(0xFF7C6BFF),
      assetPath: 'audio/white_noise_loop.wav',
    ),
    _FocusSoundProfile(
      id: 'ocean',
      label: 'Ocean',
      icon: Icons.waves_rounded,
      description: 'Steady wave rhythm.',
      accent: Color(0xFF0EA5A4),
      assetPath: 'audio/ocean_loop.wav',
    ),
  ];

  Timer? _timer;
  StreamSubscription<FocusNotificationAction>? _notificationActionSubscription;
  FocusTask? _task;
  late final AnimationController _hourglassController;
  late int _totalSeconds;
  late int _remainingSeconds;
  List<_FocusSegment> _segments = const [];
  List<int> _segmentRemainingSeconds = const [];
  int _currentSegmentIndex = 0;
  int _completedFocusSeconds = 0;
  final Set<int> _completedIndexes = {};
  int _distractions = 0;
  bool _isRunning = false;
  bool _focusLockEnabled = false;
  DateTime? _startedAt;
  _FocusTemplate? _selectedTemplate;
  List<_FocusSoundProfile> _availableSoundProfiles = List<_FocusSoundProfile>.from(
    _builtInSoundProfiles,
  );
  _FocusSoundProfile _selectedSound = _builtInSoundProfiles[1];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hourglassController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _notificationActionSubscription = FocusNotificationService.instance.actions
        .listen(_handleNotificationAction);
    _task = MyTimeStore.instance.selectedTask;
    _configureDefaultPlan(_task);
    _selectedTemplate = _templateForMinutes(_task?.focusMinutes ?? 25);
    unawaited(_initializeFocusTimer());

    final outputs = _task?.outputs ?? [];
    for (var index = 0; index < outputs.length; index++) {
      if (outputs[index].isCompleted) {
        _completedIndexes.add(index);
      }
    }
  }

  Future<void> _initializeFocusTimer() async {
    await _loadSoundProfiles();
    await _restoreTimerDraftOrLoadPlan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_persistTimerDraft());
    _timer?.cancel();
    _notificationActionSubscription?.cancel();
    _hourglassController.dispose();
    unawaited(FocusNotificationService.instance.cancel());
    unawaited(FocusAudioService.instance.stopAmbient());
    unawaited(_applyFocusMode(lockActive: false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseAndPersistForExit();
    }
  }

  void _selectTask(FocusTask? task) {
    if (task == null || identical(task, _task)) return;

    _pauseAndPersistForExit();
    MyTimeStore.instance.selectTask(task);
    setState(() {
      _startedAt = null;
      _task = task;
      _configureDefaultPlan(task);
      _selectedTemplate = _templateForMinutes(task.focusMinutes);
      _completedIndexes
        ..clear()
        ..addAll([
          for (var index = 0; index < task.outputs.length; index++)
            if (task.outputs[index].isCompleted) index,
        ]);
      _distractions = 0;
      _isRunning = false;
    });
    unawaited(_loadAppliedPlanForTask(task));
  }

  void _configureDefaultPlan(FocusTask? task) {
    final focusMinutes = task?.focusMinutes ?? 25;
    _segments = [
      _FocusSegment(
        label: 'Focus session',
        minutes: focusMinutes,
        isBreak: false,
      ),
    ];
    _segmentRemainingSeconds = [focusMinutes * 60];
    _currentSegmentIndex = 0;
    _completedFocusSeconds = 0;
    _totalSeconds = focusMinutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  Future<void> _loadAppliedPlanForTask(FocusTask? task) async {
    if (task == null) return;

    final plan = await AppliedSmartPlanStore.instance.getPlan(task.id);
    if (!mounted || _task?.id != task.id || plan == null || plan.pomodoroPlan.isEmpty) {
      return;
    }

    final segments = plan.pomodoroPlan
        .where((item) => item.minutes > 0)
        .map(
          (item) => _FocusSegment(
            label: item.label,
            minutes: item.minutes,
            isBreak: item.isBreak,
          ),
        )
        .toList();
    if (segments.isEmpty) return;

    final firstSegmentSeconds = segments.first.minutes * 60;
    final totalFocusSeconds = segments
        .where((segment) => !segment.isBreak)
        .fold<int>(0, (total, segment) => total + segment.minutes * 60);

    setState(() {
      _segments = segments;
      _segmentRemainingSeconds = [
        for (final segment in segments) segment.minutes * 60,
      ];
      _currentSegmentIndex = 0;
      _completedFocusSeconds = 0;
      _totalSeconds = totalFocusSeconds;
      _remainingSeconds = firstSegmentSeconds;
      _selectedTemplate = null;
    });
    unawaited(_persistTimerDraft());
  }

  _FocusSegment get _currentSegment => _segments[_currentSegmentIndex];

  Future<void> _loadSoundProfiles() async {
    final customAudios = await FocusAudioLibraryStore.instance.getAudios();
    if (!mounted) return;

    final profiles = _builtInSoundProfiles.map((profile) {
      CustomFocusAudio? customAudio;
      for (final item in customAudios) {
        if (item.id == profile.id) {
          customAudio = item;
          break;
        }
      }
      return _profileWithCustomOverride(profile, customAudio);
    }).toList();
    final selectedMatch = profiles.where((profile) => profile.id == _selectedSound.id);

    setState(() {
      _availableSoundProfiles = profiles;
      if (selectedMatch.isNotEmpty) {
        _selectedSound = selectedMatch.first;
      } else {
        _selectedSound = _builtInSoundProfiles[1];
      }
    });
  }

  _FocusSoundProfile _profileWithCustomOverride(
    _FocusSoundProfile profile,
    CustomFocusAudio? audio,
  ) {
    if (audio == null || audio.filePath.trim().isEmpty) {
      return profile;
    }

    return _FocusSoundProfile(
      id: profile.id,
      label: profile.label,
      icon: profile.icon,
      description: 'Custom audio: ${audio.label}',
      accent: profile.accent,
      filePath: audio.filePath,
    );
  }

  Future<void> _restoreTimerDraftOrLoadPlan() async {
    final restored = await _restoreTimerDraft();
    if (!restored) {
      await _loadAppliedPlanForTask(_task);
    }
  }

  Future<bool> _restoreTimerDraft() async {
    final draft = await FocusTimerDraftStore.instance.getDraft();
    if (draft == null) return false;

    final taskId = draft['taskId']?.toString();
    if (taskId == null || taskId.isEmpty) {
      await FocusTimerDraftStore.instance.clear();
      return false;
    }

    final resolvedTask = _resolveTaskById(taskId);
    if (resolvedTask == null) {
      await FocusTimerDraftStore.instance.clear();
      return false;
    }

    final segments = ((draft['segments'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (segment) => _FocusSegment(
            label: segment['label']?.toString() ?? 'Focus session',
            minutes: (segment['minutes'] as num?)?.toInt() ?? 1,
            isBreak: segment['isBreak'] == true,
          ),
        )
        .where((segment) => segment.minutes > 0)
        .toList();
    if (segments.isEmpty) {
      await FocusTimerDraftStore.instance.clear();
      return false;
    }

    final restoredSegmentIndex = (((draft['currentSegmentIndex'] as num?)
                    ?.toInt() ??
                0)
            .clamp(0, segments.length - 1))
        .toInt();
    final restoredCurrentSegment = segments[restoredSegmentIndex];
    final totalFocusSeconds = segments
        .where((segment) => !segment.isBreak)
        .fold<int>(0, (total, segment) => total + segment.minutes * 60);
    final remainingSeconds = ((draft['remainingSeconds'] as num?)?.toInt() ??
            restoredCurrentSegment.minutes * 60)
        .clamp(0, math.max(restoredCurrentSegment.minutes * 60, 0))
        .toInt();
    final storedTotalSeconds =
        ((draft['totalSeconds'] as num?)?.toInt() ?? totalFocusSeconds)
            .clamp(0, totalFocusSeconds)
            .toInt();
    final completedFocusSeconds =
        ((draft['completedFocusSeconds'] as num?)?.toInt() ?? 0)
            .clamp(0, storedTotalSeconds)
            .toInt();
    final restoredRemainingBySegment =
        ((draft['segmentRemainingSeconds'] as List?) ?? const [])
            .map((value) => (value as num?)?.toInt())
            .whereType<int>()
            .toList();
    final normalizedRemainingBySegment = List<int>.generate(segments.length, (
      index,
    ) {
      final maxSeconds = math.max(segments[index].minutes * 60, 0);
      final restoredValue = index < restoredRemainingBySegment.length
          ? restoredRemainingBySegment[index]
          : null;
      if (restoredValue == null) {
        if (index == restoredSegmentIndex) {
          return remainingSeconds.clamp(0, maxSeconds).toInt();
        }
        return maxSeconds;
      }
      return restoredValue.clamp(0, maxSeconds).toInt();
    });
    final selectedTemplateId = draft['selectedTemplateId']?.toString();
    final selectedSoundId = draft['selectedSoundId']?.toString();
    final startedAtText = draft['startedAt']?.toString();
    final restoredStartedAt = startedAtText == null || startedAtText.isEmpty
        ? null
        : DateTime.tryParse(startedAtText);

    final completedIndexes = ((draft['completedIndexes'] as List?) ?? const [])
        .map((index) => (index as num?)?.toInt())
        .whereType<int>()
        .toSet();

    final restoredTemplate = _focusTemplates.cast<_FocusTemplate?>().firstWhere(
          (template) => template?.id == selectedTemplateId,
          orElse: () => null,
        );
    _FocusSoundProfile? restoredSound;
    for (final profile in _availableSoundProfiles) {
      if (profile.id == selectedSoundId) {
        restoredSound = profile;
        break;
      }
    }

    if (!mounted) return true;

    setState(() {
      _task = resolvedTask;
      _segments = segments;
      _segmentRemainingSeconds = normalizedRemainingBySegment;
      _currentSegmentIndex = restoredSegmentIndex;
      _completedFocusSeconds = completedFocusSeconds;
      _totalSeconds = storedTotalSeconds;
      _remainingSeconds = normalizedRemainingBySegment[restoredSegmentIndex];
      _selectedTemplate = restoredTemplate;
      _selectedSound = restoredSound ?? _selectedSound;
      _startedAt = restoredStartedAt;
      _distractions = (draft['distractions'] as num?)?.toInt() ?? 0;
      _focusLockEnabled = draft['focusLockEnabled'] == true;
      _isRunning = false;
      _completedIndexes
        ..clear()
        ..addAll(completedIndexes);
    });

    MyTimeStore.instance.selectTask(resolvedTask);
    return true;
  }

  FocusTask? _resolveTaskById(String taskId) {
    for (final task in MyTimeStore.instance.tasks) {
      if (task.id == taskId) return task;
    }

    final selectedTask = MyTimeStore.instance.selectedTask;
    if (selectedTask?.id == taskId) return selectedTask;
    return null;
  }

  bool get _hasRestorableProgress {
    final initialRemainingSeconds = _segments.isEmpty ? 0 : _segments.first.minutes * 60;
    final hasSegmentProgress = _segments.isNotEmpty &&
        _segmentRemainingSeconds.length == _segments.length &&
        _segmentRemainingSeconds.asMap().entries.any(
          (entry) => entry.value != _segments[entry.key].minutes * 60,
        );
    return _startedAt != null ||
        _currentSegmentIndex > 0 ||
        hasSegmentProgress ||
        _completedFocusSeconds > 0 ||
        _remainingSeconds != initialRemainingSeconds ||
        _selectedTemplate != null ||
        _segments.length > 1 ||
        _completedIndexes.isNotEmpty ||
        _distractions > 0;
  }

  Future<void> _persistTimerDraft() async {
    final task = _task;
    if (task == null || _segments.isEmpty || !_hasRestorableProgress) {
      await FocusTimerDraftStore.instance.clear();
      return;
    }

    await FocusTimerDraftStore.instance.saveDraft({
      'taskId': task.id,
      'segments': [
        for (final segment in _segments)
          {
            'label': segment.label,
            'minutes': segment.minutes,
            'isBreak': segment.isBreak,
          },
      ],
      'currentSegmentIndex': _currentSegmentIndex,
      'remainingSeconds': _remainingSeconds,
      'segmentRemainingSeconds': _segmentRemainingSeconds,
      'totalSeconds': _totalSeconds,
      'completedFocusSeconds': _completedFocusSeconds,
      'completedIndexes': _completedIndexes.toList()..sort(),
      'distractions': _distractions,
      'focusLockEnabled': _focusLockEnabled,
      'selectedTemplateId': _selectedTemplate?.id,
      'selectedSoundId': _selectedSound.id,
      'startedAt': _startedAt?.toIso8601String(),
    });
  }

  void _pauseAndPersistForExit() {
    if (_isRunning) {
      _timer?.cancel();
      _hourglassController.stop();
      setState(() => _isRunning = false);
      unawaited(FocusAudioService.instance.stopAmbient());
      unawaited(_applyFocusMode(lockActive: false));
      unawaited(_showPausedNotification());
    }

    unawaited(_persistTimerDraft());
  }

  List<_FocusSegment> _buildTemplateSegments(_FocusTemplate template) {
    final segments = <_FocusSegment>[
      _FocusSegment(
        label: template.label,
        minutes: math.max(template.focusMinutes, 1),
        isBreak: false,
      ),
    ];

    if (template.breakMinutes > 0) {
      segments.add(
        _FocusSegment(
          label: 'Break',
          minutes: template.breakMinutes,
          isBreak: true,
        ),
      );
    }

    return segments;
  }

  void _selectTemplate(_FocusTemplate template) {
    if (_isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pause the timer before changing focus template.'),
        ),
      );
      return;
    }

    _timer?.cancel();
    _hourglassController.stop();
    _hourglassController.value = 0;
    unawaited(FocusNotificationService.instance.cancel());

    final segments = _buildTemplateSegments(template);
    final totalFocusSeconds = segments
        .where((segment) => !segment.isBreak)
        .fold<int>(0, (total, segment) => total + segment.minutes * 60);

    setState(() {
      _segments = segments;
      _segmentRemainingSeconds = [
        for (final segment in segments) segment.minutes * 60,
      ];
      _currentSegmentIndex = 0;
      _completedFocusSeconds = 0;
      _selectedTemplate = template;
      _startedAt = null;
      _totalSeconds = totalFocusSeconds;
      _remainingSeconds = _currentSegment.minutes * 60;
      _isRunning = false;
    });
    unawaited(_persistTimerDraft());
  }

  void _toggleFocusLock(bool value) {
    setState(() => _focusLockEnabled = value);
    unawaited(_applyFocusMode(lockActive: value && _isRunning));
    unawaited(_persistTimerDraft());
  }

  void _selectSound(_FocusSoundProfile profile) {
    setState(() => _selectedSound = profile);
    SystemSound.play(SystemSoundType.click);
    unawaited(_syncAmbientAudio());
    unawaited(_persistTimerDraft());
  }

  void _toggleTimer() {
    final task = _task;
    if (task != null && !task.canStartToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This task can start on ${_formatDate(task.scheduledDate)}.',
          ),
        ),
      );
      return;
    }

    if (_isRunning) {
      _pauseTimer();
      return;
    }

    _resumeTimer();
  }

  void _handleNotificationAction(FocusNotificationAction action) {
    if (!mounted) return;
    switch (action) {
      case FocusNotificationAction.pause:
        if (_isRunning) _pauseTimer();
      case FocusNotificationAction.resume:
        if (!_isRunning && _remainingSeconds > 0) _resumeTimer();
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    _hourglassController.stop();
    setState(() => _isRunning = false);
    unawaited(FocusAudioService.instance.stopAmbient());
    unawaited(_applyFocusMode(lockActive: false));
    unawaited(_showPausedNotification());
    unawaited(_persistTimerDraft());
  }

  void _resumeTimer() {
    _startedAt ??= DateTime.now();
    if (_task != null) {
      MyTimeStore.instance.startTask(_task!);
    }
    setState(() => _isRunning = true);
    unawaited(_applyFocusMode(lockActive: _focusLockEnabled));
    _hourglassController.repeat();
    unawaited(_syncAmbientAudio());
    unawaited(_showRunningNotification());
    _startTicker();
    unawaited(_persistTimerDraft());
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _hourglassController.stop();
        _segmentRemainingSeconds[_currentSegmentIndex] = 0;

        if (_currentSegmentIndex < _segments.length - 1) {
          final nextIndex = _currentSegmentIndex + 1;
          final nextSegment = _segments[nextIndex];
          setState(() {
            _currentSegmentIndex = nextIndex;
            _remainingSeconds = _segmentRemainingSeconds[nextIndex]
                .clamp(0, nextSegment.minutes * 60)
                .toInt();
            _isRunning = true;
          });
          _hourglassController.repeat();
          unawaited(_showRunningNotification());
          unawaited(_persistTimerDraft());
          return;
        }

        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        unawaited(FocusAudioService.instance.stopAmbient());
        unawaited(FocusAudioService.instance.playCompletionCue());
        unawaited(_applyFocusMode(lockActive: false));
        unawaited(
          FocusNotificationService.instance.showCompleted(
            taskTitle: _task?.title ?? 'Focus Time',
          ),
        );
        unawaited(FocusTimerDraftStore.instance.clear());
        return;
      }

      setState(() {
        _remainingSeconds--;
        _segmentRemainingSeconds[_currentSegmentIndex] = _remainingSeconds;
      });
      if (_remainingSeconds % 60 == 0) {
        unawaited(_showRunningNotification());
        unawaited(_persistTimerDraft());
      }
    });
  }

  void _resetTimer() {
    _startedAt = null;
    _timer?.cancel();
    _hourglassController.stop();
    _hourglassController.value = 0;
    unawaited(FocusNotificationService.instance.cancel());
    unawaited(FocusAudioService.instance.stopAmbient());
    unawaited(_applyFocusMode(lockActive: false));
    setState(() {
      _segmentRemainingSeconds = [
        for (final segment in _segments) segment.minutes * 60,
      ];
      _currentSegmentIndex = 0;
      _completedFocusSeconds = 0;
      _remainingSeconds = _currentSegment.minutes * 60;
      _isRunning = false;
    });
    unawaited(_persistTimerDraft());
  }

  void _jumpToSegment(int offset) {
    if (_segments.length <= 1) return;

    final targetIndex = _currentSegmentIndex + offset;
    if (targetIndex < 0 || targetIndex >= _segments.length) return;

    final targetSegment = _segments[targetIndex];
    setState(() {
      _segmentRemainingSeconds[_currentSegmentIndex] = _remainingSeconds;
      _currentSegmentIndex = targetIndex;
      _remainingSeconds = _segmentRemainingSeconds[targetIndex]
          .clamp(0, targetSegment.minutes * 60)
          .toInt();
    });

    if (_isRunning) {
      _hourglassController.repeat();
      unawaited(_showRunningNotification());
    } else {
      unawaited(_showPausedNotification());
    }

    unawaited(_persistTimerDraft());
  }

  Future<void> _finishSession() async {
    final task = _task;
    if (task == null) return;

    _timer?.cancel();
    _hourglassController.stop();
    unawaited(FocusNotificationService.instance.cancel());
    unawaited(FocusAudioService.instance.stopAmbient());
    unawaited(_applyFocusMode(lockActive: false));

    final elapsedSeconds = _elapsedFocusSeconds;
    final token = SessionStore.instance.token;

    if (token != null && token.isNotEmpty) {
      try {
        await FocusSessionApiService.instance.createSession(
          token: token,
          focusTaskId: task.id,
          plannedSeconds: _totalSeconds,
          actualFocusSeconds: elapsedSeconds,
          completedOutputs: _completedIndexes.length,
          totalOutputs: task.outputs.length,
          distractionCount: _distractions,
          totalDistractionSeconds: 0,
          startedAt: _startedAt ?? DateTime.now(),
          completedAt: DateTime.now(),
        );
      } catch (e) {
        debugPrint('Failed to sync focus session: $e');
      }
    }

    await MyTimeStore.instance.completeSession(
      task: task,
      elapsedSeconds: elapsedSeconds,
      plannedMinutes: _focusMinutes,
      completedIndexes: _completedIndexes,
      distractions: _distractions,
      occurrenceDate: DateTime.now(),
    );
    await FocusTimerDraftStore.instance.clear();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, AppRoutes.statistics);
  }

  Future<void> _applyFocusMode({required bool lockActive}) async {
    if (lockActive) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      return;
    }

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Future<void> _showRunningNotification() {
    if (_currentSegment.isBreak) {
      return FocusNotificationService.instance.showSegmentStarted(
        taskTitle: _task?.title ?? 'Focus Time',
        segmentLabel: _currentSegment.label,
        remainingTime: _timeText,
        isBreak: true,
      );
    }

    return FocusNotificationService.instance.showSegmentStarted(
      taskTitle: _task?.title ?? 'Focus Time',
      segmentLabel: _currentSegment.label,
      remainingTime: _timeText,
      isBreak: false,
    );
  }

  Future<void> _showPausedNotification() {
    return FocusNotificationService.instance.showPaused(
      taskTitle: _task?.title ?? 'Focus Time',
      remainingTime: _timeText,
    );
  }

  Future<void> _syncAmbientAudio() async {
    if (!_isRunning || _selectedSound.assetPath == null) {
      if (_selectedSound.filePath == null) {
        await FocusAudioService.instance.stopAmbient();
        return;
      }
    }
    if (_selectedSound.assetPath != null) {
      await FocusAudioService.instance.playAmbientAsset(_selectedSound.assetPath!);
      return;
    }

    if (_selectedSound.filePath != null) {
      await FocusAudioService.instance.playAmbientFile(_selectedSound.filePath!);
      return;
    }

    await FocusAudioService.instance.stopAmbient();
  }

  String get _timeText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _clockStatus {
    if (_isRunning) {
      return _currentSegment.isBreak ? 'BREAK' : 'FOCUSING';
    }
    if (_currentSegmentIndex == 0 &&
        _remainingSeconds == _currentSegment.minutes * 60) {
      return 'READY';
    }
    return 'PAUSED';
  }

  int get _focusMinutes => (_totalSeconds / 60).round();

  String get _breakHint {
    if (_currentSegment.isBreak) {
      return 'Break time: ${_currentSegment.minutes} min';
    }

    final nextBreakIndex = _segments.indexWhere(
      (segment) => segment.isBreak && _segments.indexOf(segment) > _currentSegmentIndex,
    );
    if (nextBreakIndex != -1) {
      return 'Next break: ${_segments[nextBreakIndex].minutes} min';
    }

    return _segments.length > 1 ? 'Final focus block' : 'Single focus session';
  }

  int get _elapsedFocusSeconds {
    if (_segments.isEmpty || _segmentRemainingSeconds.length != _segments.length) {
      return 0;
    }

    var total = 0;
    for (var index = 0; index < _segments.length; index++) {
      final segment = _segments[index];
      if (segment.isBreak) continue;
      final plannedSeconds = segment.minutes * 60;
      final remainingSeconds = _segmentRemainingSeconds[index].clamp(
        0,
        plannedSeconds,
      );
      total += plannedSeconds - remainingSeconds;
    }
    return total.clamp(0, 86400);
  }

  bool get _lockEditing => _focusLockEnabled && _isRunning;

  double get _progress {
    if (_totalSeconds <= 0) return 0;
    return (_elapsedFocusSeconds / _totalSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final canStart = task?.canStartToday ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final soundAccent = _selectedSound.accent;

    return PopScope(
      canPop: !_lockEditing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _lockEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Focus lock is on. Pause the timer or turn off focus lock to leave.',
              ),
            ),
          );
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Focus Time'),
            actions: [
              IconButton(
                tooltip: _focusLockEnabled
                    ? 'Unlock focus mode'
                    : 'Lock focus mode',
                onPressed: () => _toggleFocusLock(!_focusLockEnabled),
                icon: Icon(
                  _focusLockEnabled
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              if (_selectedSound.id != 'off')
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            soundAccent.withValues(alpha: 0.08),
                            Colors.transparent,
                            soundAccent.withValues(alpha: 0.04),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              task == null
                  ? _NoTaskView(
                      onSelectTask: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.tasks,
                        );
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _FocusModeDeck(
                          focusMinutes: _focusMinutes,
                          selectedTemplate: _selectedTemplate,
                          selectedSound: _selectedSound,
                          soundProfiles: _availableSoundProfiles,
                          focusLockEnabled: _focusLockEnabled,
                          isRunning: _isRunning,
                          breakHint: _breakHint,
                          onTemplateSelected: _selectTemplate,
                          onSoundSelected: _selectSound,
                          onFocusLockChanged: _toggleFocusLock,
                        ),
                        const SizedBox(height: 14),
                        _FocusTaskPicker(
                          selectedTask: task,
                          onChanged: _lockEditing ? null : _selectTask,
                        ),
                        const SizedBox(height: 14),
                        _FocusDurationPicker(
                          minutes: _focusMinutes,
                          enabled: !_isRunning && !_lockEditing,
                          selectedTemplate: _selectedTemplate,
                        ),
                        const SizedBox(height: 14),
                        if (!canStart)
                          AppCard(
                            color: AppColors.surfaceSoft,
                            child: Text(
                              'This is a future plan. You can review it now, but Focus Time is available on ${_formatDate(task.scheduledDate)}.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                        if (!canStart) const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _hourglassController,
                          builder: (context, child) {
                            return _FocusSessionCard(
                              title: task.title,
                              status: _clockStatus,
                              segmentLabel: _currentSegment.label,
                              outputText:
                                  '${_completedIndexes.length}/${task.outputs.length} output',
                              time: _timeText,
                              progress: _progress,
                              focusMinutes: _focusMinutes,
                              hourglassValue: _progress,
                              breakHint: _breakHint,
                              segmentSummary:
                                  '${_currentSegmentIndex + 1}/${_segments.length} segments',
                              soundProfile: _selectedSound,
                              canGoPrevious: _currentSegmentIndex > 0,
                              canGoNext:
                                  _currentSegmentIndex < _segments.length - 1,
                              onPreviousStep: () => _jumpToSegment(-1),
                              onNextStep: () => _jumpToSegment(1),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _FocusControls(
                          isRunning: _isRunning,
                          canStart: canStart,
                          unavailableText:
                              'Available on ${_formatDate(task.scheduledDate)}',
                          focusLockEnabled: _focusLockEnabled,
                          onToggle: _toggleTimer,
                          onReset: _lockEditing ? null : _resetTimer,
                        ),
                        const SizedBox(height: 24),
                        const SectionHeader(
                          title: 'Session outputs',
                          subtitle: 'Check an output when you complete it.',
                        ),
                        const SizedBox(height: 8),
                        _OutputChecklist(
                          task: task,
                          completedIndexes: _completedIndexes,
                          enabled: !_lockEditing,
                          onChanged: (index, value) {
                            setState(() {
                              if (value) {
                                _completedIndexes.add(index);
                              } else {
                                _completedIndexes.remove(index);
                              }
                            });
                            unawaited(_persistTimerDraft());
                          },
                        ),
                        const SizedBox(height: 8),
                        _SessionActions(
                          distractions: _distractions,
                          focusLocked: _lockEditing,
                          onRecordDistraction: () {
                            setState(() => _distractions++);
                            unawaited(_persistTimerDraft());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Distraction recorded.'),
                              ),
                            );
                          },
                          onFinish: _finishSession,
                        ),
                      ],
                    ),
            ],
          ),
          bottomNavigationBar: _lockEditing
              ? null
              : const AppBottomNavigation(selectedIndex: 2),
        ),
      ),
    );
  }
}

class _FocusTaskPicker extends StatelessWidget {
  const _FocusTaskPicker({required this.selectedTask, required this.onChanged});

  final FocusTask selectedTask;
  final ValueChanged<FocusTask?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tasks = MyTimeStore.instance.tasks
        .where((task) => !task.isCompleted)
        .toList();
    final hasSelected = tasks.any((task) => identical(task, selectedTask));
    final value = hasSelected ? selectedTask : null;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FocusTask>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          hint: const Text('Choose a focus task'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: tasks.map((task) {
            return DropdownMenuItem(
              value: task,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.hourglass_bottom_rounded,
                      color: AppColors.primaryDark,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${task.focusMinutes} min • ${_formatDate(task.scheduledDate)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FocusModeDeck extends StatelessWidget {
  const _FocusModeDeck({
    required this.focusMinutes,
    required this.selectedTemplate,
    required this.selectedSound,
    required this.soundProfiles,
    required this.focusLockEnabled,
    required this.isRunning,
    required this.breakHint,
    required this.onTemplateSelected,
    required this.onSoundSelected,
    required this.onFocusLockChanged,
  });

  final int focusMinutes;
  final _FocusTemplate? selectedTemplate;
  final _FocusSoundProfile selectedSound;
  final List<_FocusSoundProfile> soundProfiles;
  final bool focusLockEnabled;
  final bool isRunning;
  final String breakHint;
  final ValueChanged<_FocusTemplate> onTemplateSelected;
  final ValueChanged<_FocusSoundProfile> onSoundSelected;
  final ValueChanged<bool> onFocusLockChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Advanced focus mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a timer template, choose an ambient scene, and lock the session when you want zero-friction focus.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (selectedTemplate == null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primaryDark,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current session: Custom $focusMinutes min',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _FocusTimerScreenState._focusTemplates.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final template = _FocusTimerScreenState._focusTemplates[index];
                final selected = selectedTemplate?.id == template.id;
                return _TemplateCard(
                  template: template,
                  selected: selected,
                  onTap: () => onTemplateSelected(template),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selectedSound.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selectedSound.accent.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                _AmbientBars(
                  color: selectedSound.accent,
                  active: isRunning && selectedSound.id != 'off',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambient scene: ${selectedSound.label}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedSound.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        breakHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: soundProfiles.map((profile) {
              return ChoiceChip(
                selected: profile.id == selectedSound.id,
                label: Text(profile.label),
                avatar: Icon(profile.icon, size: 16),
                onSelected: (_) => onSoundSelected(profile),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: focusLockEnabled,
            onChanged: onFocusLockChanged,
            secondary: Icon(
              focusLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: AppColors.primary,
            ),
            title: const Text('Lock screen focus mode'),
            subtitle: Text(
              focusLockEnabled
                  ? 'Hide extra chrome and block leaving while the timer is running.'
                  : 'Keep navigation available until you decide to lock in.',
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final _FocusTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 156,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? AppColors.primary : Colors.black).withValues(
                alpha: selected ? 0.18 : 0.04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              template.icon,
              color: selected ? Colors.white : AppColors.primaryDark,
              size: 18,
            ),
            const SizedBox(height: 8),
            Text(
              template.label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${template.focusMinutes}/${template.breakMinutes}',
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: 0.92)
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusDurationPicker extends StatelessWidget {
  const _FocusDurationPicker({
    required this.minutes,
    required this.enabled,
    required this.selectedTemplate,
  });

  final int minutes;
  final bool enabled;
  final _FocusTemplate? selectedTemplate;

  @override
  Widget build(BuildContext context) {
    final isCustom = selectedTemplate == null;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Focus duration: $minutes min',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (selectedTemplate != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    '${selectedTemplate!.label} ${selectedTemplate!.focusMinutes}/${selectedTemplate!.breakMinutes}',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (selectedTemplate == null && isCustom)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    'Custom',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (!enabled)
                const Text(
                  'Pause to edit',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

_FocusTemplate? _templateForMinutes(int minutes) {
  for (final template in _FocusTimerScreenState._focusTemplates) {
    if (template.focusMinutes == minutes) return template;
  }
  return null;
}

class _FocusTemplate {
  const _FocusTemplate({
    required this.id,
    required this.label,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.icon,
    required this.description,
  });

  final String id;
  final String label;
  final int focusMinutes;
  final int breakMinutes;
  final IconData icon;
  final String description;
}

class _FocusSoundProfile {
  const _FocusSoundProfile({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    required this.accent,
    this.assetPath,
    this.filePath,
  });

  final String id;
  final String label;
  final IconData icon;
  final String description;
  final Color accent;
  final String? assetPath;
  final String? filePath;
}

class _FocusSegment {
  const _FocusSegment({
    required this.label,
    required this.minutes,
    required this.isBreak,
  });

  final String label;
  final int minutes;
  final bool isBreak;
}

class _FocusSessionCard extends StatelessWidget {
  const _FocusSessionCard({
    required this.title,
    required this.status,
    required this.segmentLabel,
    required this.outputText,
    required this.time,
    required this.progress,
    required this.focusMinutes,
    required this.hourglassValue,
    required this.breakHint,
    required this.segmentSummary,
    required this.soundProfile,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPreviousStep,
    required this.onNextStep,
  });

  final String title;
  final String status;
  final String segmentLabel;
  final String outputText;
  final String time;
  final double progress;
  final int focusMinutes;
  final double hourglassValue;
  final String breakHint;
  final String segmentSummary;
  final _FocusSoundProfile soundProfile;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPreviousStep;
  final VoidCallback onNextStep;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF3CF), Color(0xFFFFFFFF)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.timer_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$focusMinutes min focus plan',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$segmentLabel • $segmentSummary',
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _StepNavButton(
                                tooltip: 'Previous step',
                                icon: Icons.chevron_left_rounded,
                                enabled: canGoPrevious,
                                onTap: onPreviousStep,
                              ),
                              const SizedBox(width: 6),
                              _StepNavButton(
                                tooltip: 'Next step',
                                icon: Icons.chevron_right_rounded,
                                enabled: canGoNext,
                                onTap: onNextStep,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HeaderPill(
                                icon: Icons.coffee_rounded,
                                label: breakHint,
                              ),
                              _HeaderPill(
                                icon: soundProfile.icon,
                                label: soundProfile.label,
                                color: soundProfile.accent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _FocusClock(
                  time: time,
                  progress: progress,
                  hourglassValue: hourglassValue,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                _StatusChip(status: status),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.task_alt_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          outputText,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isRunning = status == 'FOCUSING';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isRunning ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isRunning ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _StepNavButton extends StatelessWidget {
  const _StepNavButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _FocusControls extends StatelessWidget {
  const _FocusControls({
    required this.isRunning,
    required this.canStart,
    required this.unavailableText,
    required this.focusLockEnabled,
    required this.onToggle,
    required this.onReset,
  });

  final bool isRunning;
  final bool canStart;
  final String unavailableText;
  final bool focusLockEnabled;
  final VoidCallback onToggle;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canStart ? onToggle : null,
            icon: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(
              canStart
                  ? (isRunning
                        ? 'Pause'
                        : focusLockEnabled
                        ? 'Start locked session'
                        : 'Start')
                  : unavailableText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Reset timer',
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _OutputChecklist extends StatelessWidget {
  const _OutputChecklist({
    required this.task,
    required this.completedIndexes,
    required this.enabled,
    required this.onChanged,
  });

  final FocusTask task;
  final Set<int> completedIndexes;
  final bool enabled;
  final void Function(int index, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(task.outputs.length, (index) {
        final output = task.outputs[index];
        final checked = completedIndexes.contains(index);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: checked ? const Color(0xFFECFDF3) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: checked
                  ? AppColors.success.withValues(alpha: 0.22)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: AppColors.primary,
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            value: checked,
            title: Text(
              output.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: checked
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: output.isCompleted
                ? const Text('Completed in a previous session')
                : null,
            onChanged: !enabled || output.isCompleted
                ? null
                : (value) => onChanged(index, value ?? false),
          ),
        );
      }),
    );
  }
}

class _SessionActions extends StatelessWidget {
  const _SessionActions({
    required this.distractions,
    required this.focusLocked,
    required this.onRecordDistraction,
    required this.onFinish,
  });

  final int distractions;
  final bool focusLocked;
  final VoidCallback onRecordDistraction;
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.surfaceSoft,
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: onRecordDistraction,
            icon: const Icon(Icons.warning_amber_rounded),
            label: Text('Record distraction ($distractions)'),
          ),
          if (focusLocked) ...[
            const SizedBox(height: 8),
            const Text(
              'Focus lock is active. Pause the timer to edit the session.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await onFinish();
              },
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Finish and view results'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    this.color = AppColors.primaryDark,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBars extends StatelessWidget {
  const _AmbientBars({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bars = active
        ? const [20.0, 28.0, 16.0, 24.0]
        : const [8.0, 12.0, 8.0, 10.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final height in bars)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              width: 6,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _FocusClock extends StatelessWidget {
  const _FocusClock({
    required this.time,
    required this.progress,
    required this.hourglassValue,
  });

  final String time;
  final double progress;
  final double hourglassValue;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final safeHourglassValue = hourglassValue.clamp(0.0, 1.0);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF0), Color(0xFFFFE7AB)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 350,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedHourglass(
                    value: safeHourglassValue,
                    size: 318,
                    color: const Color(0xFFB87922),
                  ),
                  Positioned(
                    bottom: 86,
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.96,
                                  end: 1,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            time,
                            key: ValueKey(time),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Focus Time',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: safeProgress,
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: Colors.white.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedHourglass extends StatelessWidget {
  const AnimatedHourglass({
    super.key,
    required this.value,
    required this.size,
    required this.color,
  });

  final double value;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HourglassPainter(value: value, color: color),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  const _HourglassPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final v = value.clamp(0.0, 1.0);
    final w = size.width;
    final h = size.height;
    final midX = w / 2;

    final topY = h * 0.12;
    final neckY = h * 0.50;
    final bottomY = h * 0.88;

    final glassTopLeft = w * 0.25;
    final glassTopRight = w * 0.75;
    final glassBottomLeft = w * 0.25;
    final glassBottomRight = w * 0.75;

    final woodDark = Color.lerp(color, const Color(0xFF7A4A15), 0.20)!;
    final woodLight = Color.lerp(color, const Color(0xFFFFD06A), 0.45)!;
    final sandColor = AppColors.primary;
    final sandLight = const Color(0xFFFFE08A);

    final glowPaint = Paint()
      ..color = sandColor.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(midX, h * 0.52),
        width: w * 0.62,
        height: h * 0.70,
      ),
      glowPaint,
    );

    final topCapRect = Rect.fromCenter(
      center: Offset(midX, h * 0.065),
      width: w * 0.70,
      height: h * 0.105,
    );
    final bottomCapRect = Rect.fromCenter(
      center: Offset(midX, h * 0.935),
      width: w * 0.70,
      height: h * 0.105,
    );

    void drawWoodCap(Rect rect) {
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(rect.height / 2),
      );
      canvas.drawShadow(Path()..addRRect(rrect), Colors.black26, 7, true);
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [woodLight, color, woodDark],
          ).createShader(rect),
      );
      canvas.drawOval(
        Rect.fromLTWH(
          rect.left + rect.width * 0.08,
          rect.top + rect.height * 0.06,
          rect.width * 0.84,
          rect.height * 0.38,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.16),
      );
    }

    drawWoodCap(topCapRect);
    drawWoodCap(bottomCapRect);

    final postPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [woodDark, woodLight, woodDark],
      ).createShader(Rect.fromLTWH(0, topY, w, bottomY - topY));

    final leftPost = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.185, h * 0.095, w * 0.035, h * 0.81),
      const Radius.circular(999),
    );
    final rightPost = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.78, h * 0.095, w * 0.035, h * 0.81),
      const Radius.circular(999),
    );
    canvas.drawRRect(leftPost, postPaint);
    canvas.drawRRect(rightPost, postPaint);

    final glassPath = Path()
      ..moveTo(glassTopLeft, topY)
      ..cubicTo(w * 0.28, h * 0.25, w * 0.38, h * 0.40, midX, neckY)
      ..cubicTo(
        w * 0.62,
        h * 0.60,
        w * 0.72,
        h * 0.75,
        glassBottomRight,
        bottomY,
      )
      ..lineTo(glassBottomLeft, bottomY)
      ..cubicTo(w * 0.28, h * 0.75, w * 0.38, h * 0.60, midX, neckY)
      ..cubicTo(w * 0.62, h * 0.40, w * 0.72, h * 0.25, glassTopRight, topY)
      ..close();

    canvas.drawShadow(glassPath, Colors.black26, 8, true);

    final glassRect = Rect.fromLTWH(
      glassTopLeft,
      topY,
      glassTopRight - glassTopLeft,
      bottomY - topY,
    );

    canvas.save();
    canvas.clipPath(glassPath);

    canvas.drawPath(
      glassPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.74),
            Colors.white.withValues(alpha: 0.22),
            sandLight.withValues(alpha: 0.16),
          ],
        ).createShader(glassRect),
    );

    final upperSandBase = neckY - 6;
    final upperSandTop = topY + 25 + (h * 0.14 * v);
    final topSandLeft = glassTopLeft + 18 + (w * 0.10 * v);
    final topSandRight = glassTopRight - 18 - (w * 0.10 * v);

    if (v < 0.98) {
      final topSand = Path()
        ..moveTo(topSandLeft, upperSandTop)
        ..quadraticBezierTo(
          midX,
          upperSandTop + 10 + math.sin(v * math.pi * 2) * 2,
          topSandRight,
          upperSandTop,
        )
        ..cubicTo(w * 0.67, h * 0.31, w * 0.58, h * 0.42, midX, upperSandBase)
        ..cubicTo(
          w * 0.42,
          h * 0.42,
          w * 0.33,
          h * 0.31,
          topSandLeft,
          upperSandTop,
        )
        ..close();

      canvas.drawPath(
        topSand,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [sandLight, sandColor],
          ).createShader(Rect.fromLTWH(0, upperSandTop, w, upperSandBase)),
      );
    }

    if (v > 0.02) {
      final lowerHeight = h * (0.06 + 0.21 * v);
      final bottomSandTop = bottomY - 25 - lowerHeight;
      final bottomSand = Path()
        ..moveTo(glassBottomLeft + 17, bottomY - 24)
        ..quadraticBezierTo(
          midX,
          bottomSandTop - math.sin(v * math.pi * 2) * 3,
          glassBottomRight - 17,
          bottomY - 24,
        )
        ..lineTo(glassBottomRight - 9, bottomY - 10)
        ..lineTo(glassBottomLeft + 9, bottomY - 10)
        ..close();

      canvas.drawPath(
        bottomSand,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [sandLight, sandColor],
          ).createShader(Rect.fromLTWH(0, bottomSandTop, w, lowerHeight + 30)),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(midX, bottomSandTop + 7),
          width: w * (0.10 + 0.12 * v),
          height: h * 0.026,
        ),
        Paint()..color = sandLight.withValues(alpha: 0.72),
      );
    }

    if (v > 0.01 && v < 0.99) {
      final streamX = midX + math.sin(v * math.pi * 24) * 1.6;
      canvas.drawLine(
        Offset(midX, neckY - 5),
        Offset(streamX, neckY + h * 0.24),
        Paint()
          ..color = sandColor.withValues(alpha: 0.90)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    final shinePath = Path()
      ..moveTo(w * 0.36, topY + 18)
      ..cubicTo(w * 0.28, h * 0.28, w * 0.38, h * 0.37, w * 0.47, neckY - 8)
      ..cubicTo(w * 0.38, h * 0.62, w * 0.31, h * 0.76, w * 0.35, bottomY - 22);

    canvas.drawPath(
      shinePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    canvas.restore();

    canvas.drawPath(
      glassPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      glassPath,
      Paint()
        ..color = color.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final rimPaint = Paint()
      ..color = woodDark.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.28, topY + 1),
      Offset(w * 0.72, topY + 1),
      rimPaint,
    );
    canvas.drawLine(
      Offset(w * 0.28, bottomY - 1),
      Offset(w * 0.72, bottomY - 1),
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

class _NoTaskView extends StatelessWidget {
  const _NoTaskView({required this.onSelectTask});

  final VoidCallback onSelectTask;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text('Select a task before starting Focus Time.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onSelectTask,
              child: const Text('Select task'),
            ),
          ],
        ),
      ),
    );
  }
}
