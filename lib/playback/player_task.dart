import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/playback/media_proxy.dart';

void audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => _AudioPlayerTask());
}

// https://pub.dev/documentation/audio_service/latest/audio_service/BackgroundAudioTask-class.html
class _AudioPlayerTask extends BackgroundAudioTask {
  final _player = AudioPlayer();
  int proxyServerPort;

  // TODO implement much more
  onPlay() => _player.play();
  onPause() => _player.pause();

  Future<void> onStart(Map<String, dynamic> params) async {
    proxyServerPort = params[MediaProxy.portParam];
    assert(proxyServerPort != null);
  }

  @override
  // TODO hello-world only
  Future<void> onPlayMediaItem(MediaItem mediaItem) {
    final path = mediaItem.extras['path'];
    assert(path != null);
    final String host = InternetAddress.loopbackIPv4.host;
    final int port = proxyServerPort;
    final Uri uri = Uri.http('$host:$port', MediaProxy.audioEndpoint, {MediaProxy.pathQueryParameter: path});
    _player.setAudioSource(AudioSource.uri(uri), preload: false); // TODO handle exceptions
    _player.play();
    return super.onPlayMediaItem(mediaItem);
  }
}
