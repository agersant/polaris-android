import 'package:async/async.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/pin.dart' as pin;

class Manager {
  final connection.Manager connectionManager;
  final MediaCacheInterface mediaCache;
  final pin.ManagerInterface pinManager;
  final AudioPlayer audioPlayer;

  late RestartableTimer _timer;
  bool _working = false;

  Manager({
    required this.connectionManager,
    required this.mediaCache,
    required this.pinManager,
    required this.audioPlayer,
  }) {
    pinManager.addListener(_wake);
    audioPlayer.sequenceStateStream.listen((e) => _wake());
    _timer = RestartableTimer(const Duration(seconds: 30), _doWork);
  }

  void dispose() {
    _timer.cancel();
  }

  void _wake() {
    _timer.reset();
  }

  void _doWork() async {
    if (_working) {
      _timer.reset();
      return;
    }

    _working = true;

    cleanup();

    _working = false;
  }

  Future<void> cleanup() async {
    final String? host = connectionManager.url;
    if (host == null) {
      return;
    }

    Map<String, Set<String>> songsToPreserve = {host: {}};
    Map<String, Set<String>> imagesToPreserve = {host: {}};

    audioPlayer.sequence?.forEach((audioSource) {
      final mediaItem = audioSource.tag as MediaItem;
      final song = mediaItem.toSong();
      songsToPreserve[host]!.add(song.path);

      final artwork = song.artwork;
      if (artwork != null) {
        songsToPreserve[host]!.add(artwork);
      }
    });

    for (String host in pinManager.hosts) {
      final hostPins = await pinManager.getAllSongs(host);
      final hostSongs = songsToPreserve.putIfAbsent(host, () => {});
      final hostImages = imagesToPreserve.putIfAbsent(host, () => {});
      hostSongs.addAll(hostPins.map((s) => s.path));
      hostImages.addAll(hostPins.map((s) => s.artwork).whereType<String>());
    }

    await mediaCache.purge(songsToPreserve, imagesToPreserve);
  }
}
