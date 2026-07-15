import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project/models/custom_focus_audio.dart';
import 'package:project/services/focus_audio_library_store.dart';
import 'package:project/shared/widgets/app_card.dart';

class FocusAudioSettingsScreen extends StatefulWidget {
  const FocusAudioSettingsScreen({super.key});

  @override
  State<FocusAudioSettingsScreen> createState() =>
      _FocusAudioSettingsScreenState();
}

class _FocusAudioSettingsScreenState extends State<FocusAudioSettingsScreen> {
  static const _audioSlots = [
    _AudioSlot(
      id: 'rain',
      title: 'Rain',
      subtitle: 'Replace the Rain ambient sound with your own file.',
      icon: Icons.water_drop_rounded,
    ),
    _AudioSlot(
      id: 'cafe',
      title: 'Cafe',
      subtitle: 'Replace the Cafe ambient sound with your own file.',
      icon: Icons.local_cafe_rounded,
    ),
    _AudioSlot(
      id: 'white_noise',
      title: 'White Noise',
      subtitle: 'Replace the White Noise ambient sound with your own file.',
      icon: Icons.graphic_eq_rounded,
    ),
    _AudioSlot(
      id: 'ocean',
      title: 'Ocean',
      subtitle: 'Replace the Ocean ambient sound with your own file.',
      icon: Icons.waves_rounded,
    ),
  ];

  bool _busy = false;
  List<CustomFocusAudio> _assignments = const [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final assignments = await FocusAudioLibraryStore.instance.getAudios();
    if (!mounted) return;
    setState(() => _assignments = assignments);
  }

  CustomFocusAudio? _assignmentFor(String slotId) {
    for (final item in _assignments) {
      if (item.id == slotId) return item;
    }
    return null;
  }

  Future<void> _pickForSlot(_AudioSlot slot) async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: false,
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      final filePath = picked.path;
      if (filePath == null || filePath.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected audio file.')),
        );
        return;
      }

      final fileName = picked.name.trim().isEmpty
          ? _basenameFromPath(filePath)
          : picked.name.trim();
      final previous = _assignmentFor(slot.id);
      final copiedPath = await _copyAudioIntoAppStorage(
        sourcePath: filePath,
        slotId: slot.id,
        fileName: fileName,
      );
      final assignment = CustomFocusAudio(
        id: slot.id,
        label: _stripExtension(fileName),
        filePath: copiedPath,
      );

      await FocusAudioLibraryStore.instance.upsertAudio(assignment);
      if (previous != null && previous.filePath != copiedPath) {
        await _deleteIfExists(previous.filePath);
      }
      await _loadAssignments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${slot.title} audio updated.')),
      );
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Audio browser was not loaded into this app build yet. Stop the app and run it again on the phone.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick audio file: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _clearSlot(_AudioSlot slot) async {
    final existing = _assignmentFor(slot.id);
    if (existing != null) {
      await _deleteIfExists(existing.filePath);
    }
    await FocusAudioLibraryStore.instance.removeAudio(slot.id);
    await _loadAssignments();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${slot.title} audio reset to default.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Audio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ambient audio library', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Pick one file for each ambient type. Focus Time will loop that file continuously when the sound is selected.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'If file picker was just added, do a full app restart instead of hot reload so browsing works on device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._audioSlots.map((slot) {
            final assignment = _assignmentFor(slot.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(slot.icon, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.title, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(slot.subtitle, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: assignment == null
                          ? const Text('Using built-in default audio.')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignment.label.isEmpty
                                      ? 'Custom audio selected'
                                      : assignment.label,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _shortenPath(assignment.filePath),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _pickForSlot(slot),
                            icon: _busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.audio_file_outlined),
                            label: const Text('Browse file'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (assignment != null)
                          IconButton(
                            tooltip: 'Reset to default',
                            onPressed: _busy ? null : () => _clearSlot(slot),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<String> _copyAudioIntoAppStorage({
    required String sourcePath,
    required String slotId,
    required String fileName,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Selected audio file is not accessible on this device.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final audioDirectory = Directory('${directory.path}/focus_audio');
    if (!await audioDirectory.exists()) {
      await audioDirectory.create(recursive: true);
    }

    final extension = _extensionFromFileName(fileName);
    final safeName = _sanitizeName(slotId);
    final targetPath = '${audioDirectory.path}/$safeName$extension';
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    final copied = await sourceFile.copy(targetPath);
    return copied.path;
  }

  Future<void> _deleteIfExists(String path) async {
    if (path.trim().isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class _AudioSlot {
  const _AudioSlot({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

String _basenameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final segments = normalized.split('/');
  return segments.isEmpty ? path : segments.last;
}

String _stripExtension(String value) {
  final dotIndex = value.lastIndexOf('.');
  if (dotIndex <= 0) return value;
  return value.substring(0, dotIndex);
}

String _shortenPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (normalized.length <= 46) return normalized;
  return '...${normalized.substring(normalized.length - 46)}';
}

String _extensionFromFileName(String value) {
  final dotIndex = value.lastIndexOf('.');
  if (dotIndex < 0) return '.mp3';
  return value.substring(dotIndex);
}

String _sanitizeName(String value) {
  final normalized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return normalized.isEmpty ? 'focus_audio' : normalized;
}
