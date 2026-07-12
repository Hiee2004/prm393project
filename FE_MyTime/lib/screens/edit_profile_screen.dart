import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/models/user_profile.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/services/profile_api_service.dart';
import 'package:project/services/session_store.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;

  String? _avatarPath;

  @override
  void initState() {
    super.initState();

    final profile = MyTimeStore.instance.profile;

    _fullNameController = TextEditingController(text: profile.fullName);
    _emailController = TextEditingController(text: profile.email);
    _avatarPath = profile.avatarUrl;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null || !mounted) return;

      setState(() => _avatarPath = image.path);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $error')));
    }
  }

  void _removeAvatar() {
    setState(() => _avatarPath = null);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final store = MyTimeStore.instance;
    final token = SessionStore.instance.token;
    final localProfile = UserProfile(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      avatarUrl: _avatarPath,
      timeZone: store.setting.timeZone,
      themeMode: store.setting.themeMode,
    );

    if (token == null || token.isEmpty) {
      store.updateProfile(localProfile);
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

      store.updateProfile(
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                ProfileAvatar(
                  avatarPath: _avatarPath,
                  radius: 44,
                  icon: Icons.person_rounded,
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose photo'),
                    ),
                    if ((_avatarPath ?? '').isNotEmpty)
                      TextButton.icon(
                        onPressed: _removeAvatar,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remove'),
                      ),
                  ],
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
                    textInputAction: TextInputAction.done,
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: AppColors.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Theme and time zone are managed in Settings.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
