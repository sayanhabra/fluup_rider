import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Helper to play alert sounds from soundlink URLs or local audio files
/// when FCM notifications arrive (e.g. for "RIDER_OFFER").
class NotificationSoundHelper {
  NotificationSoundHelper._();
  static final NotificationSoundHelper instance = NotificationSoundHelper._();

  AudioPlayer? _player;
  String? _lastPlayedSource;
  bool _isPlaying = false;

  String? get lastPlayedSource => _lastPlayedSource;
  bool get isPlaying => _isPlaying;

  /// Plays notification sound from [soundSource].
  /// [soundSource] can be:
  /// - A remote HTTP / HTTPS URL (e.g. https://api.fluup.online/audio/rider_offer.mp3)
  /// - A local asset or file name (e.g. 'rider_new_delivery')
  Future<void> play(String? soundSource) async {
    if (soundSource == null || soundSource.trim().isEmpty) {
      debugPrint('ℹ️ [NotificationSoundHelper] No sound URL provided.');
      return;
    }

    final sound = soundSource.trim();
    _lastPlayedSource = sound;
    _isPlaying = true;

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      debugPrint('🔊 [NotificationSoundHelper] (Test Mode) Simulated playing sound: $sound');
      return;
    }

    try {
      _stopInternalPlayer();
      _isPlaying = true;
      _player = AudioPlayer();

      debugPrint('🔊 [NotificationSoundHelper] Playing notification sound from: $sound');

      if (sound.startsWith('http://') || sound.startsWith('https://')) {
        await _player!.setReleaseMode(ReleaseMode.loop);
        await _player!.play(UrlSource(sound));
      } else {
        // Local asset fallback
        final assetPath = sound.endsWith('.mp3') || sound.endsWith('.wav')
            ? sound
            : '$sound.mp3';
        await _player!.setReleaseMode(ReleaseMode.loop);
        await _player!.play(AssetSource('audio/$assetPath'));
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationSoundHelper] Error playing sound ($sound): $e');
    }
  }

  void _stopInternalPlayer() {
    try {
      _player?.stop();
      _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  /// Stops and disposes active player
  void stop() {
    _isPlaying = false;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    _stopInternalPlayer();
  }
}
