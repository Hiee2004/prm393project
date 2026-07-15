import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/services/profile_api_service.dart';
import 'package:project/services/session_store.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingProfile = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = SessionStore.instance.token;

    if (token == null || token.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });

    try {
      final profile = await ProfileApiService.instance.getMe(token);
      MyTimeStore.instance.updateProfile(profile);
      await MyTimeStore.instance.loadSessionsFromApi();
      await MyTimeStore.instance.loadTasksFromApi();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MyTimeStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final profile = store.profile;

          return RefreshIndicator(
            onRefresh: _loadProfile,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isLoadingProfile)
                  const LinearProgressIndicator(minHeight: 3),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    color: const Color(0xFFFFF1F2),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _ProfileHeader(
                  fullName: profile.fullName,
                  email: profile.email,
                  avatarUrl: profile.avatarUrl,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${store.completedTaskCount}',
                        label: 'Completed Tasks',
                        icon: Icons.task_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: '${store.focusSessions.length}',
                        label: 'Focus Sessions',
                        icon: Icons.hourglass_bottom_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _FocusSummaryCard(
                  totalFocus: _formatMinutes(store.totalBackendFocusSeconds),
                  tasksDone: store.completedTaskCount,
                  totalTasks: store.tasks.length,
                  themeMode: profile.themeMode,
                ),
                const SizedBox(height: 18),
                _AccountInfoCard(
                  fullName: profile.fullName,
                  email: profile.email,
                  timeZone: profile.timeZone,
                  themeMode: profile.themeMode,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 4),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.fullName,
    required this.email,
    required this.avatarUrl,
  });

  final String fullName;
  final String email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.82 : 0.88,
            ),
            theme.colorScheme.primary.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.34 : 0.68,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scene.navGlow,
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileAvatar(
            avatarPath: avatarUrl,
            radius: 48,
            icon: Icons.person_rounded,
            backgroundColor: theme.colorScheme.surface,
          ),
          const SizedBox(height: 16),
          Text(
            fullName.isEmpty ? 'Your Name' : fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            email.isEmpty ? 'your@email.com' : email,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.62 : 0.74,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Auth: Email',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(height: 10),
          Text(value, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FocusSummaryCard extends StatelessWidget {
  const _FocusSummaryCard({
    required this.totalFocus,
    required this.tasksDone,
    required this.totalTasks,
    required this.themeMode,
  });

  final String totalFocus;
  final int tasksDone;
  final int totalTasks;
  final String themeMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalTasks == 0 ? 0.0 : tasksDone / totalTasks;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus Overview', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.secondary.withValues(
                alpha: 0.20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Total Focus Time', value: totalFocus),
          _InfoRow(label: 'Tasks Done', value: '$tasksDone/$totalTasks'),
          _InfoRow(label: 'Theme', value: AppTheme.labelForMode(themeMode)),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({
    required this.fullName,
    required this.email,
    required this.timeZone,
    required this.themeMode,
  });

  final String fullName;
  final String email;
  final String timeZone;
  final String themeMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Info', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _InfoRow(label: 'Full Name', value: fullName),
          _InfoRow(label: 'Email', value: email),
          _InfoRow(label: 'Time Zone', value: timeZone),
          _InfoRow(label: 'Theme', value: AppTheme.labelForMode(themeMode)),
          const _InfoRow(label: 'Member Since', value: 'May 2026'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.editProfile);
              },
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMinutes(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}
