import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/playback/media_item.dart';
import 'package:polaris/playback/media_proxy.dart';

void audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => _AudioPlayerTask());
}

// https://pub.dev/documentation/audio_service/latest/audio_service/BackgroundAudioTask-class.html
class _AudioPlayerTask extends BackgroundAudioTask {
  StreamSubscription<PlaybackEvent> _eventSubscription;
  final _player = AudioPlayer();
  final _audioSource = ConcatenatingAudioSource(children: []);
  int proxyServerPort;

  List<MediaItem> _queue = [];
  int get index => _player.currentIndex;
  MediaItem get mediaItem => index == null ? null : _queue[index];

  @override
  Future<void> onPlay() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration(milliseconds: 0), index: index);
    }
    await _player.play();
  }

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onSkipToNext() async {
    final mediaItem = AudioServiceBackground.mediaItem;
    final queue = AudioServiceBackground.queue ?? [];
    int currentIndex = queue.indexOf(mediaItem);
    if (currentIndex == -1) {
      // TODO untested
      await _player.seek(Duration(milliseconds: 0), index: 0);
    } else {
      await _player.seekToNext();
    }
    await onPlay();
  }

  @override
  Future<void> onStop() async {
    await _player.dispose();
    _eventSubscription.cancel();
    await _broadcastState();
    await super.onStop();
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    proxyServerPort = params[MediaProxy.portParam];
    assert(proxyServerPort != null);

    _player.currentIndexStream.listen((index) {
      if (index != null) AudioServiceBackground.setMediaItem(_queue[index]);
    });

    _eventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    await _player.setAudioSource(_audioSource, preload: false);
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {
    await _audioSource.add(AudioSource.uri(_getPlaybackURI(mediaItem)));
    _queue.add(mediaItem);
    await AudioServiceBackground.setQueue(_queue);
    if (_queue.length == 1) {
      await onPlay();
    }
  }

  Future<void> _broadcastState() async {
    final processingState = _getProcessingState();
    final bool isPlaying = _player.playing && processingState != AudioProcessingState.completed;
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious, // TODO implement skip to previous
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo, // TODO implement seeking
      ],
      androidCompactActions: [0, 1, 2],
      processingState: processingState,
      playing: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  AudioProcessingState _getProcessingState() {
    // if (_skipState != null) return _skipState; // TODO
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_player.processingState}");
    }
  }

  Uri _getPlaybackURI(MediaItem mediaItem) {
    final path = mediaItem.extras[extraKeyPath];
    assert(path != null);
    final String host = InternetAddress.loopbackIPv4.host;
    final int port = proxyServerPort;
    return Uri.http('$host:$port', MediaProxy.audioEndpoint, {MediaProxy.pathQueryParameter: path});
  }
}
