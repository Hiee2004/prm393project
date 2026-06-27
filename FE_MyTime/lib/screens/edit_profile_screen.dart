import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/models/user_profile.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/services/profile_api_service.dart';
import 'package:project/services/session_store.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _avatarUrlController;

  String _timeZone = 'Asia/Ho_Chi_Minh';
  String _themeMode = 'Light';

  @override
  void initState() {
    super.initState();

    final profile = MyTimeStore.instance.profile;

    _fullNameController = TextEditingController(text: profile.fullName);
    _emailController = TextEditingController(text: profile.email);
    _avatarUrlController = TextEditingController(text: profile.avatarUrl ?? '');
    _timeZone = profile.timeZone;
    _themeMode = profile.themeMode;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final token = SessionStore.instance.token;
    final localProfile = UserProfile(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim().isEmpty
          ? null
          : _avatarUrlController.text.trim(),
      timeZone: _timeZone,
      themeMode: _themeMode,
    );

    if (token == null || token.isEmpty) {
      MyTimeStore.instance.updateProfile(localProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved on this device.')),
      );
      Navigator.pop(context);
      return;
    }

    try {
      final updatedProfile = await ProfileApiService.instance.updateProfile(
        token: token,
        fullName: localProfile.fullName,
        email: localProfile.email,
        avatarUrl: localProfile.avatarUrl,
      );

      MyTimeStore.instance.updateProfile(
        updatedProfile.copyWith(
          timeZone: localProfile.timeZone,
          themeMode: localProfile.themeMode,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _avatarUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundImage: avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 46,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _fullNameController.text.trim().isEmpty
                      ? 'Your Name'
                      : _fullNameController.text.trim(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _emailController.text.trim(),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name.';
                      }
                      if (value.trim().length > 120) {
                        return 'Full name must be under 120 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Please enter your email.';
                      }
                      if (!text.contains('@')) {
                        return 'Please enter a valid email.';
                      }
                      if (text.length > 180) {
                        return 'Email must be under 180 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _avatarUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Avatar URL',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      if (!text.startsWith('http')) {
                        return 'Avatar URL should start with http or https.';
                      }
                      if (text.length > 500) {
                        return 'Avatar URL must be under 500 characters.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _timeZone,
                  decoration: const InputDecoration(
                    labelText: 'Time zone',
                    prefixIcon: Icon(Icons.public_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Asia/Ho_Chi_Minh',
                      child: Text('Asia/Ho_Chi_Minh'),
                    ),
                    DropdownMenuItem(
                      value: 'Asia/Bangkok',
                      child: Text('Asia/Bangkok'),
                    ),
                    DropdownMenuItem(
                      value: 'Asia/Tokyo',
                      child: Text('Asia/Tokyo'),
                    ),
                    DropdownMenuItem(
                      value: 'Europe/Berlin',
                      child: Text('Europe/Berlin'),
                    ),
                    DropdownMenuItem(
                      value: 'America/New_York',
                      child: Text('America/New_York'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _timeZone = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _themeMode,
                  decoration: const InputDecoration(
                    labelText: 'Theme',
                    prefixIcon: Icon(Icons.palette_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Light', child: Text('Light')),
                    DropdownMenuItem(value: 'Yellow', child: Text('Yellow')),
                    DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _themeMode = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
