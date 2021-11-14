import 'dart:async';
import 'dart:developer' as developer;

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/playlist.dart';

class Manager {
  final connection.Manager connectionManager;
  final download.Manager downloadManager;
  final MediaCacheInterface mediaCache;
  final Playlist playlist;
  late Timer _timer;

  LockCachingAudioSource? _playlistSongBeingFetched;

  Manager({
    required this.connectionManager,
    required this.downloadManager,
    required this.mediaCache,
    required this.playlist,
  }) {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _prefetchPlaylist();
    });
  }

  void dispose() {
    _timer.cancel();
  }

  Future _prefetchPlaylist() async {
    final String? host = connectionManager.url;
    if (host == null) {
      return;
    }

    final playlistSong = _playlistSongBeingFetched;
    if (playlistSong != null) {
      final MediaItem mediaItem = playlistSong.tag;
      final dto.Song song = mediaItem.toSong();
      if (await mediaCache.hasAudio(host, song.path)) {
        _playlistSongBeingFetched = null;
      } else {
        return;
      }
    }

    LockCachingAudioSource? playlistSongToFetch = await _pickPlaylistSongToFetch(host);
    if (playlistSongToFetch != null && playlistSongToFetch != _playlistSongBeingFetched) {
      final MediaItem mediaItem = playlistSongToFetch.tag;
      final String path = mediaItem.toSong().path;
      developer.log("Beginning prefetch for playlist song: $path");
      _playlistSongBeingFetched = playlistSongToFetch;
      try {
        final response = await playlistSongToFetch.request();
        await for (List<int> bytes in response.stream) {
          bytes;
        }
        developer.log("Finished prefetching song: $path");
      } catch (e) {
        developer.log("Error ($e) while prefetching song: $path");
      } finally {
        _playlistSongBeingFetched = null;
      }
    }
  }

  Future<LockCachingAudioSource?> _pickPlaylistSongToFetch(String host) async {
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
}
