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

  Manager({
    required this.uuid,
    required this.connectionManager,
    required this.downloadManager,
    required this.mediaCache,
    required this.pinManager,
    required this.playlist,
  }) {
    _timer = RestartableTimer(const Duration(seconds: 5), _doWork);
  }

  void dispose() {
    _timer.cancel();
  }

  void _doWork() async {
    await _prefetchPlaylist();
    await _prefetchPins();
    _timer.reset();
  }

  Future _prefetchPlaylist() async {
    final String? host = connectionManager.url;
    if (host == null) {
      return;
    }

    if (_playlistSongBeingFetched != null) {
      return;
    }

    StreamAudioSource? songToFetch = await _pickPlaylistSongToFetch(host);
    if (songToFetch != null && songToFetch != _playlistSongBeingFetched) {
      _playlistSongBeingFetched = songToFetch;
      _prefetch(songToFetch)
          .then((value) => _playlistSongBeingFetched = null)
          .catchError((dynamic error) => _playlistSongBeingFetched = null);
    }
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

  Future _prefetchPins() async {
    final String? host = connectionManager.url;
    if (host == null) {
      return;
    }

    if (_pinSongBeingFetched != null) {
      return;
    }

    StreamAudioSource? songToFetch = await _pickPinSongToFetch(host);
    if (songToFetch != null && songToFetch != _pinSongBeingFetched) {
      _pinSongBeingFetched = songToFetch;
      _prefetch(songToFetch)
          .then((value) => _pinSongBeingFetched = null)
          .catchError((dynamic error) => _pinSongBeingFetched = null);
    }
  }

  Future<StreamAudioSource?> _pickPinSongToFetch(String host) async {
    final songs = pinManager.getSongs(host);
    if (songs == null) {
      return null;
    }
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
    // TODO look at pinned directories
  }

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
      rethrow;
    }
  }
}
