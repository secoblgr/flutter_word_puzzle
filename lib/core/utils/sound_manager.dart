import 'package:audioplayers/audioplayers.dart';

/// Singleton sound manager for game sound effects.
///
/// Call [SoundManager.instance] to access the shared instance.
/// All sounds are loaded from `assets/sounds/` as `.wav` files.
class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();
  final AudioPlayer _hintPlayer = AudioPlayer();
  final AudioPlayer _levelUpPlayer = AudioPlayer();
  final AudioPlayer _timerWarningPlayer = AudioPlayer();

  bool _muted = false;

  /// Whether sound effects are muted.
  bool get isMuted => _muted;

  /// Toggle mute on/off.
  void toggleMute() => _muted = !_muted;

  /// Set mute state directly.
  void setMuted(bool value) => _muted = value;

  /// Play the correct answer sound.
  Future<void> playCorrect() => _play(_correctPlayer, 'correct.wav');

  /// Play the wrong answer sound.
  Future<void> playWrong() => _play(_wrongPlayer, 'wrong.wav');

  /// Play the hint usage sound.
  Future<void> playHint() => _play(_hintPlayer, 'hint.wav');

  /// Play the level-up / victory sound.
  Future<void> playLevelUp() => _play(_levelUpPlayer, 'level_up.wav');

  /// Play the timer warning sound (last 10 seconds).
  Future<void> playTimerWarning() => _play(_timerWarningPlayer, 'timer_warning.wav');

  Future<void> _play(AudioPlayer player, String fileName) async {
    if (_muted) return;
    try {
      await player.stop();
      await player.play(AssetSource('sounds/$fileName'));
    } catch (_) {
      // Silently ignore audio errors — game should not break.
    }
  }

  /// Release all audio resources.
  void dispose() {
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
    _hintPlayer.dispose();
    _levelUpPlayer.dispose();
    _timerWarningPlayer.dispose();
  }
}
