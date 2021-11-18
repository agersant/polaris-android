import 'dart:async';
import 'dart:developer' as developer;
import 'package:async/async.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/playlist.dart';
import 'package:uuid/uuid.dart';

class Manager {
  final Uuid uuid;
  final connection.Manager connectionManager;
  final download.Manager downloadManager;
  final MediaCacheInterface mediaCache;
  final pin.ManagerInterface pinManager;
  final Playlist playlist;

  StreamAudioSource? _playlistSongBeingFetched;
  StreamAudioSource? _pinSongBeingFetched;
  late RestartableTimer _timer;
  bool _working = false;

  Manager({
    required this.uuid,
    required this.connectionManager,
    required this.downloadManager,
    required this.mediaCache,
    required this.pinManager,
    required this.playlist,
  }) {
    pinManager.addListener(_wake);
    playlist.addListener(_wake);
    // TODO we need tp call _wake when current playlist song changes (as this may prompt us to load more upcoming songs)
    _timer = RestartableTimer(const Duration(seconds: 5), _doWork);
  }

  void dispose() {
    _timer.cancel();
  }

  void _wake() {
    if (!_timer.isActive) {
      _doWork();
    }
  }

  void _doWork() async {
    if (_working) {
      _timer.reset();
      return;
    }

    _working = true;

    bool allDone = await _prefetchPlaylist();
    allDone |= await _prefetchPins();
    if (!allDone) {
      _timer.reset();
    }

    _working = false;
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
      _wake();
    });

    return false;
  }

  Future<StreamAudioSource?> _pickPlaylistSongToFetch(String host) async {
    final List<dto.Song> upcomingSongs = playlist.songs;
    final int currentIndex = playlist.currentIndex ?? -1;
    const int maxSongsToPreload = 5; // TODO Make this configurable in settings screen
    for (int index = 0; index < upcomingSongs.length; index++) {
      if (index <= currentIndex) {
        continue;
      }
      if ((index - currentIndex) > maxSongsToPreload) {
        return null;
      }
      final dto.Song song = upcomingSongs[index];
      final bool hasAudio = await mediaCache.hasAudio(host, song.path);
      if (!hasAudio) {
        return playlist.getAudioSourceAt(index);
      }
    }
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
      _wake();
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
