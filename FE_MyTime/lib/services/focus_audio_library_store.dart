import 'dart:convert';

import 'package:project/models/custom_focus_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusAudioLibraryStore {
  FocusAudioLibraryStore._();

  static const _customAudiosKey = 'mytime_custom_focus_audios';
  static final FocusAudioLibraryStore instance = FocusAudioLibraryStore._();

  Future<List<CustomFocusAudio>> getAudios() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_customAudiosKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map(
          (item) => CustomFocusAudio.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<CustomFocusAudio?> getAudioForSlot(String slotId) async {
    final audios = await getAudios();
    for (final audio in audios) {
      if (audio.id == slotId) return audio;
    }
    return null;
  }

  Future<void> upsertAudio(CustomFocusAudio audio) async {
    final audios = await getAudios();
    final existingIndex = audios.indexWhere((item) => item.id == audio.id);
    if (existingIndex >= 0) {
      audios[existingIndex] = audio;
    } else {
      audios.add(audio);
    }
    await saveAudios(audios);
  }

  Future<void> removeAudio(String slotId) async {
    final audios = await getAudios();
    audios.removeWhere((item) => item.id == slotId);
    await saveAudios(audios);
  }

  Future<void> saveAudios(List<CustomFocusAudio> audios) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _customAudiosKey,
      jsonEncode([for (final audio in audios) audio.toJson()]),
    );
  }
}
