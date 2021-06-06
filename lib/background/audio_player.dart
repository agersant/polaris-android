import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/background/entrypoint.dart';
import 'package:polaris/background/proxy_server.dart';
import 'package:polaris/shared/media_item.dart';

// https://pub.dev/documentation/audio_service/latest/audio_service/BackgroundAudioTask-class.html
class AudioPlayerTask extends BackgroundAudioTask {
  late StreamSubscription<PlaybackEvent> _eventSubscription;
  final _player = AudioPlayer();
  final _audioSource = ConcatenatingAudioSource(children: []);
  final int proxyServerPort;

  AudioPlayerTask({required this.proxyServerPort});

  List<MediaItem> _queue = [];
  int? get index => _player.currentIndex;
  MediaItem? get mediaItem => index == null ? null : _queue[index!];

  @override
  Future<dynamic> onCustomAction(String name, dynamic arguments) async {
    if (name == customActionGetPort) {
      return proxyServerPort;
    } else if (name == customActionAddNextQueueItem) {
      return onAddNextQueueItem(MediaItem.fromJson(arguments[0]));
    } else if (name == customActionMoveQueueItem) {
      return onMoveQueueItem(arguments[0], arguments[1]);
    }
  }

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
    if (mediaItem == null) {
      // TODO untested
      await _player.seek(Duration(milliseconds: 0), index: 0);
    } else {
      final queue = AudioServiceBackground.queue ?? [];
      int currentIndex = queue.indexOf(mediaItem);
      if (currentIndex == -1) {
        // TODO untested
        await _player.seek(Duration(milliseconds: 0), index: 0);
      } else {
        await _player.seekToNext();
      }
    }
    await onPlay();
  }

  @override
  Future<void> onSkipToQueueItem(String mediaID) async {
    final queue = AudioServiceBackground.queue;
    final mediaItem = AudioServiceBackground.mediaItem;

    int currentIndex = -1;
    if (mediaItem != null) {
      currentIndex = queue?.indexOf(mediaItem) ?? -1;
    }

    var newIndex = queue?.indexWhere((mediaItem) => mediaItem.id == mediaID);
    if (newIndex == null || newIndex == -1 || newIndex == currentIndex) {
      return;
    }

    await _player.seek(Duration(milliseconds: 0), index: newIndex);
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
  Future<void> onStart(Map<String, dynamic>? params) async {
    _player.currentIndexStream.listen((index) {
      // TODO https://github.com/ryanheise/just_audio/issues/392
      // This prevents player UI from showing up until one song is done playing
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

  Future<void> onAddNextQueueItem(MediaItem mediaItem) async {
    int? currentIndex = _player.currentIndex;
    if (currentIndex == null || currentIndex >= _queue.length) {
      return await onAddQueueItem(mediaItem);
    }
    currentIndex++;

    await _audioSource.insert(currentIndex, AudioSource.uri(_getPlaybackURI(mediaItem)));
    _queue.insert(currentIndex, mediaItem);

    await AudioServiceBackground.setQueue(_queue);
    if (_queue.length == 1) {
      await onPlay();
    }
  }

  Future<void> onMoveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex || oldIndex < 0 || oldIndex >= _queue.length || newIndex < 0 || newIndex > _queue.length) {
      return;
    }
    final MediaItem mediaItem = _queue.removeAt(oldIndex);
    final int insertIndex = oldIndex > newIndex ? newIndex : newIndex - 1;
    _queue.insert(insertIndex, mediaItem);
    await _audioSource.move(oldIndex, insertIndex);
    await AudioServiceBackground.setQueue(_queue);
  }

  Future<void> _broadcastState() async {
    final processingState = _getProcessingState();
    final bool isPlaying = _player.playing && processingState != AudioProcessingState.completed;
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
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
    final path = mediaItem.extras![extraKeyPath];
    assert(path != null);
    final String host = InternetAddress.loopbackIPv4.host;
    final int port = proxyServerPort;
    return Uri.http('$host:$port', ProxyServer.audioEndpoint, {ProxyServer.pathQueryParameter: path});
  }
}
