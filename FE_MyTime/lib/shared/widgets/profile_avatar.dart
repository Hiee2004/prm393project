import 'dart:io';

import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarPath,
    this.radius = 44,
    this.icon = Icons.person_rounded,
    this.backgroundColor,
  });

  final String? avatarPath;
  final double radius;
  final IconData icon;
  final Color? backgroundColor;

  bool get _hasAvatar => avatarPath != null && avatarPath!.trim().isNotEmpty;

  ImageProvider<Object>? get _imageProvider {
    final path = avatarPath?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? AppColors.primary.withValues(alpha: 0.12),
      backgroundImage: _imageProvider,
      child: _hasAvatar
          ? null
          : Icon(icon, size: radius, color: AppColors.primary),
    );
  }
}
