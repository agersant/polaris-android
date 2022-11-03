import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/settings.dart' as settings;
import 'package:polaris/core/unique_timer.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class Manager {
  final Uuid uuid;
  final connection.Manager connectionManager;
  final authentication.Manager authenticationManager;
  final download.Manager downloadManager;
  final MediaCacheInterface mediaCache;
  final pin.ManagerInterface pinManager;
  final AudioPlayer audioPlayer;
  final settings.Manager settingsManager;

  StreamAudioSource? _playlistSongBeingFetched;
  StreamAudioSource? _pinSongBeingFetched;
  late UniqueTimer _timer;

  final _songsBeingFetchedSubject = BehaviorSubject<Set<dto.Song>>.seeded({});
  Set<dto.Song> get songsBeingFetched => _songsBeingFetchedSubject.value;
  Stream<Set<dto.Song>> get songsBeingFetchedStream => _songsBeingFetchedSubject.stream;

  Manager({
    required this.uuid,
    required this.connectionManager,
    required this.authenticationManager,
    required this.downloadManager,
    required this.mediaCache,
    required this.pinManager,
    required this.audioPlayer,
    required this.settingsManager,
  }) {
    _timer = UniqueTimer(duration: const Duration(seconds: 5), callback: _doWork);
    pinManager.addListener(_timer.wake);
    connectionManager.addListener(_timer.wake);
    authenticationManager.addListener(_timer.wake);
    audioPlayer.sequenceStateStream.listen((e) => _timer.wake());
    settingsManager.addListener(_timer.wake);
  }

  void dispose() {
    _timer.cancel();
  }

  Future<void> _doWork() async {
    bool allDone = true;
    if (connectionManager.isConnected() && authenticationManager.isAuthenticated()) {
      allDone &= await _prefetchPlaylist();
      allDone &= await _prefetchPins();
    }
    _updateSongsBeingFetched();
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
    _updateSongsBeingFetched();

    _prefetch(songToFetch).then((value) {
      _playlistSongBeingFetched = null;
      _timer.wake();
    });

    return false;
  }

  Future<StreamAudioSource?> _pickPlaylistSongToFetch(String host) async {
    final int maxSongsToPreload =
        Settings.getValue<int>(settings.keyNumSongsToPreload, settings.defaultNumSongsToPreload);
    final SequenceState? sequenceState = audioPlayer.sequenceState;
    final List<IndexedAudioSource> effectiveSequence = sequenceState?.effectiveSequence ?? [];
    final int currentIndex = sequenceState?.currentIndex ?? -1;

    int currentEffectiveIndex;
    if (audioPlayer.shuffleModeEnabled) {
      currentEffectiveIndex = sequenceState?.shuffleIndices.indexOf(currentIndex) ?? -1;
    } else {
      currentEffectiveIndex = currentIndex;
    }

    if (effectiveSequence.isEmpty) {
      return null;
    }

    int numSongsConsidered = 0;
    while (numSongsConsidered < maxSongsToPreload) {
      numSongsConsidered++;
      int index = (currentEffectiveIndex + numSongsConsidered) % effectiveSequence.length;

      final audioSource = effectiveSequence[index];
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
    _updateSongsBeingFetched();

    _prefetch(songToFetch).then((value) {
      _pinSongBeingFetched = null;
      _timer.wake();
    });

    return false;
  }

  Future<StreamAudioSource?> _pickPinSongToFetch(String host) async {
    final songs = await pinManager.getAllSongs(host);
    if (songs == null) {
      throw "Could not list pinned songs";
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

  void _updateSongsBeingFetched() {
    final songs = <dto.Song>{};
    if (_playlistSongBeingFetched != null) {
      songs.add((_playlistSongBeingFetched!.tag as MediaItem).toSong());
    }
    if (_pinSongBeingFetched != null) {
      songs.add((_pinSongBeingFetched!.tag as MediaItem).toSong());
    }
    _songsBeingFetchedSubject.add(songs);
  }
}
