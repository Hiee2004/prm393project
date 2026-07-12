import 'package:audioplayers/audioplayers.dart';

class FocusAudioService {
  FocusAudioService._();

  static final FocusAudioService instance = FocusAudioService._();

  final AudioPlayer _ambientPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.loop);
  final AudioPlayer _cuePlayer = AudioPlayer();

  String? _currentAmbientAsset;

  Future<void> playAmbient(String assetPath) async {
    if (_currentAmbientAsset == assetPath &&
        _ambientPlayer.state == PlayerState.playing) {
      return;
    }

    _currentAmbientAsset = assetPath;
    await _ambientPlayer.stop();
    await _ambientPlayer.setVolume(0.32);
    await _ambientPlayer.play(AssetSource(assetPath));
  }

  Future<void> stopAmbient() async {
    _currentAmbientAsset = null;
    await _ambientPlayer.stop();
  }

  Future<void> playCompletionCue() async {
    await _cuePlayer.stop();
    await _cuePlayer.setReleaseMode(ReleaseMode.release);
    await _cuePlayer.setVolume(0.92);
    await _cuePlayer.play(AssetSource('audio/complete_chime.wav'));
  }

  Future<void> dispose() async {
    await _ambientPlayer.dispose();
    await _cuePlayer.dispose();
  }
}
