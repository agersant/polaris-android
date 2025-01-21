import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:rxdart/rxdart.dart';

Future<PolarisAudioHandler> initAudioService({
  required connection.Manager connectionManager,
  required CollectionCache collectionCache,
  required polaris.Client polarisClient,
}) async {
  return await AudioService.init(
    builder: () => PolarisAudioHandler(
      connectionManager: connectionManager,
      collectionCache: collectionCache,
      polarisClient: polarisClient,
    ),
    config: const AudioServiceConfig(
      androidNotificationIcon: "drawable/notification_icon",
      androidNotificationChannelName: 'Polaris Audio Playback',
      androidNotificationOngoing: true,
    ),
  );
}

class PolarisAudioHandler extends BaseAudioHandler with SeekHandler {
  final connection.Manager connectionManager;
  final CollectionCache collectionCache;
  final polaris.Client polarisClient;

  final audioPlayer = AudioPlayer();
  final BehaviorSubject<dto.Song?> _currentSong = BehaviorSubject.seeded(null);
  Stream<dto.Song?> get currentSong => _currentSong.stream;

  PolarisAudioHandler({
    required this.collectionCache,
    required this.connectionManager,
    required this.polarisClient,
  }) {
    _forwardPlaybackState();
    _forwardSongMetadata();
  }

  void _forwardSongMetadata() {
    audioPlayer.sequenceStateStream.listen((sequenceState) async {
      final host = connectionManager.url;
      final currentMediaItem = sequenceState?.currentSource?.tag as MediaItem?;
      if (currentMediaItem == null || host == null) {
        _currentSong.value = null;
        mediaItem.add(null);
        return;
      }

      final path = currentMediaItem.getSongPath();
      final song = collectionCache.getSong(host, path);
      _currentSong.value = song;
      if (song == null) {
        mediaItem.add(currentMediaItem);
        return;
      }

      final String? artwork = song.artwork;
      Uri? artworkUri;
      if (artwork != null) {
        artworkUri = await polarisClient.getImageURI(artwork);
      }
      mediaItem.add(song.toMediaItem(currentMediaItem.id, artworkUri));
    });
  }

  void _forwardPlaybackState() {
    audioPlayer.playbackEventStream.listen((PlaybackEvent event) {
      final playing = audioPlayer.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [1, 3],
        processingState: switch (audioPlayer.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: audioPlayer.position,
        bufferedPosition: audioPlayer.bufferedPosition,
        speed: audioPlayer.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  @override
  Future<void> play() => audioPlayer.play();

  @override
  Future<void> pause() => audioPlayer.pause();

  @override
  Future<void> stop() async {
    audioPlayer.stop();
    super.stop();
  }

  @override
  Future<void> seek(Duration position) => audioPlayer.seek(position);

  @override
  Future<void> skipToQueueItem(int index) => audioPlayer.seek(Duration.zero, index: index);

  Future<void> resume(int index, Duration position) => audioPlayer.seek(position, index: index);

  @override
  Future<void> skipToNext() => audioPlayer.seekToNext();

  @override
  Future<void> skipToPrevious() => audioPlayer.seekToPrevious();
}
