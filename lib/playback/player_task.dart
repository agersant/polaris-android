import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

void audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => _AudioPlayerTask());
}

// https://pub.dev/documentation/audio_service/latest/audio_service/BackgroundAudioTask-class.html
class _AudioPlayerTask extends BackgroundAudioTask {
  final _player = AudioPlayer();

  // TODO implement much more
  onPlay() => _player.play();
  onPause() => _player.pause();

  @override
  // TODO hello-world only
  Future<void> onPlayMediaItem(MediaItem mediaItem) {
    final uri = mediaItem.extras['uri'];
    _player.setAudioSource(AudioSource.uri(Uri.parse(uri)), preload: false); // TODO handle exceptions
    _player.play();
    return super.onPlayMediaItem(mediaItem);
  }
}
