import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/unique_timer.dart';

class Manager {
  final connection.Manager connectionManager;
  final MediaCacheInterface mediaCache;
  final pin.ManagerInterface pinManager;
  final AudioPlayer audioPlayer;

  late UniqueTimer _timer;

  Manager({
    required this.connectionManager,
    required this.mediaCache,
    required this.pinManager,
    required this.audioPlayer,
  }) {
    _timer = UniqueTimer(
      duration: const Duration(seconds: 30),
      callback: _doWork,
    );
    pinManager.addListener(_timer.reset);
    audioPlayer.sequenceStateStream.listen((e) => _timer.reset());
  }

  void dispose() {
    _timer.cancel();
  }

  Future<void> _doWork() async {
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
