import 'package:audioplayers/audioplayers.dart';

class FocusAudioService {
  FocusAudioService._();

  static final FocusAudioService instance = FocusAudioService._();

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _cuePlayer = AudioPlayer();

  String? _currentAmbientAsset;

  Future<void> _preparePlayers() async {
    await _ambientPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
    await _ambientPlayer.setReleaseMode(ReleaseMode.loop);

    await _cuePlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notificationEvent,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
      ),
    );
  }

  Future<void> playAmbient(String assetPath) async {
    if (_currentAmbientAsset == assetPath &&
        _ambientPlayer.state == PlayerState.playing) {
      return;
    }

    await _preparePlayers();
    _currentAmbientAsset = assetPath;
    await _ambientPlayer.stop();
    await _ambientPlayer.setVolume(0.65);
    await _ambientPlayer.play(AssetSource(assetPath));
  }

  Future<void> stopAmbient() async {
    _currentAmbientAsset = null;
    await _ambientPlayer.stop();
  }

  Future<void> playCompletionCue() async {
    await _preparePlayers();
    await _cuePlayer.stop();
    await _cuePlayer.setReleaseMode(ReleaseMode.release);
    await _cuePlayer.setVolume(1.0);
    await _cuePlayer.play(AssetSource('audio/complete_chime.wav'));
  }

  Future<void> dispose() async {
    await _ambientPlayer.dispose();
    await _cuePlayer.dispose();
  }
}
