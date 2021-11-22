import 'dart:async';
import 'dart:developer' as developer;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/unique_timer.dart';
import 'package:uuid/uuid.dart';

class Manager {
  final Uuid uuid;
  final connection.Manager connectionManager;
  final download.Manager downloadManager;
  final MediaCacheInterface mediaCache;
  final pin.ManagerInterface pinManager;
  final AudioPlayer audioPlayer;

  StreamAudioSource? _playlistSongBeingFetched;
  StreamAudioSource? _pinSongBeingFetched;
  late UniqueTimer _timer;

  Manager({
    required this.uuid,
    required this.connectionManager,
    required this.downloadManager,
    required this.mediaCache,
    required this.pinManager,
    required this.audioPlayer,
  }) {
    _timer = UniqueTimer(duration: const Duration(seconds: 5), callback: _doWork);
    pinManager.addListener(_timer.wake);
    audioPlayer.sequenceStateStream.listen((e) => _timer.wake());
  }

  void dispose() {
    _timer.cancel();
  }

  Future<void> _doWork() async {
    bool allDone = false;
    allDone |= await _prefetchPlaylist();
    allDone |= await _prefetchPins();
    if (!allDone) {
      _timer.reset();
    }
  }

  Future<bool> _prefetchPlaylist() async {
    final String? host = connectionManager.url;
    if (host == null) {
      return false;
    }

    if (_playlistSongBeingFetched != null) {
      return false;
    }

    StreamAudioSource? songToFetch = await _pickPlaylistSongToFetch(host);
    if (songToFetch == null) {
      return true;
    }

    _playlistSongBeingFetched = songToFetch;

    _prefetch(songToFetch).then((value) {
      _playlistSongBeingFetched = null;
      _timer.wake();
    });

    return false;
  }

  Future<StreamAudioSource?> _pickPlaylistSongToFetch(String host) async {
    final SequenceState? sequenceState = audioPlayer.sequenceState;
    final List<IndexedAudioSource> audioSources = sequenceState?.sequence ?? [];
    final int currentIndex = sequenceState?.currentIndex ?? -1;
    const int maxSongsToPreload = 5; // TODO Make this configurable in settings screen
    for (int index = 0; index < audioSources.length; index++) {
      if (index <= currentIndex) {
        continue;
      }
      if ((index - currentIndex) > maxSongsToPreload) {
        return null;
      }
      final audioSource = audioSources[index];
      final MediaItem mediaItem = audioSource.tag;
      final dto.Song song = mediaItem.toSong();
      final bool hasAudio = await mediaCache.hasAudio(host, song.path);
      if (!hasAudio && audioSource is StreamAudioSource) {
        return audioSource;
      }
    }
    return null;
  }

  Future<bool> _prefetchPins() async {
    final String? host = connectionManager.url;
    if (host == null) {
      return false;
    }

    if (_pinSongBeingFetched != null) {
      return false;
    }

    StreamAudioSource? songToFetch;
    try {
      songToFetch = await _pickPinSongToFetch(host);
    } catch (e) {
      developer.log("Error while looking for a pinned song to prefetch: $e");
      return false;
    }

    if (songToFetch == null) {
      return true;
    }

    _pinSongBeingFetched = songToFetch;
    _prefetch(songToFetch).then((value) {
      _pinSongBeingFetched = null;
      _timer.wake();
    });

    return false;
  }

  Future<StreamAudioSource?> _pickPinSongToFetch(String host) async {
    final songs = await pinManager.getAllSongs(host);
    for (dto.Song song in songs) {
      if (await mediaCache.hasAudio(host, song.path)) {
        continue;
      }
      final mediaItem = song.toMediaItem(uuid.v4(), null);
      final audioSource = await downloadManager.getAudio(host, song.path, mediaItem);
      if (audioSource is StreamAudioSource) {
        return audioSource;
      }
    }
    return null;
  }

  // TODO This can deadlock. See https://github.com/ryanheise/just_audio/issues/594
  Future<void> _prefetch(StreamAudioSource audioSource) async {
    final MediaItem mediaItem = audioSource.tag;
    final String path = mediaItem.toSong().path;
    try {
      developer.log("Beginning prefetch for song: $path");
      final response = await audioSource.request();
      await for (List<int> bytes in response.stream) {
        bytes;
      }
      developer.log("Finished prefetching song: $path");
    } catch (e) {
      developer.log("Error ($e) while prefetching song: $path");
    }
  }
}
