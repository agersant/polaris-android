import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/playlist.dart';
import 'package:rxdart/rxdart.dart';

const _currentVersion = 2;

class PlaylistState {
  final String host;
  final String? name;
  final List<String> songs;

  PlaylistState({
    required this.host,
    required this.name,
    required this.songs,
  });

  factory PlaylistState.fromBytes(List<int> bytes) {
    return PlaylistState.fromJson(jsonDecode(utf8.decode(io.gzip.decode(bytes))));
  }

  List<int> toBytes() {
    return io.gzip.encode(utf8.encode(jsonEncode(this)));
  }

  factory PlaylistState.fromJson(Map<String, dynamic> json) {
    return PlaylistState(
      host: json['host'],
      name: json['name'],
      songs: (json['songs'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'host': host,
        'name': name,
        'songs': songs,
      };
}

class PlaybackState {
  final int currentSongIndex;
  final int currentSongProgressMilliseconds;
  final bool repeat;
  final bool shuffle;

  PlaybackState(
      {required this.currentSongIndex,
      required this.currentSongProgressMilliseconds,
      required this.repeat,
      required this.shuffle});

  factory PlaybackState.fromBytes(List<int> bytes) {
    return PlaybackState.fromJson(jsonDecode(utf8.decode(io.gzip.decode(bytes))));
  }

  List<int> toBytes() {
    return io.gzip.encode(utf8.encode(jsonEncode(this)));
  }

  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    return PlaybackState(
      currentSongIndex: json['currentSongIndex'],
      currentSongProgressMilliseconds: json['currentSongProgressMilliseconds'],
      repeat: json['repeat'],
      shuffle: json['shuffle'],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentSongIndex': currentSongIndex,
        'currentSongProgressMilliseconds': currentSongProgressMilliseconds,
        'repeat': repeat,
        'shuffle': shuffle,
      };
}

class Manager {
  final connection.Manager connectionManager;
  final CollectionCache collectionCache;
  final AudioPlayer audioPlayer;
  final Playlist playlist;

  Manager({
    required this.connectionManager,
    required this.collectionCache,
    required this.audioPlayer,
    required this.playlist,
  });

  static Future<io.File> _getPlaylistStateFile(int version) async {
    final temporaryDirectory = await getTemporaryDirectory();
    return io.File(p.join(temporaryDirectory.path, 'playlist-v$version.savestate'));
  }

  static Future<io.File> _getPlaybackStateFile(int version) async {
    final temporaryDirectory = await getTemporaryDirectory();
    return io.File(p.join(temporaryDirectory.path, 'playback-v$version.savestate'));
  }

  void init() {
    connectionManager.addListener(_handleConnectionStateChanged);
    _handleConnectionStateChanged();
  }

  Future<void> _handleConnectionStateChanged() async {
    if (connectionManager.state == connection.State.connected ||
        connectionManager.state == connection.State.offlineMode) {
      connectionManager.removeListener(_handleConnectionStateChanged);
      await loadFromDisk();

      audioPlayer.sequenceStream.listen((e) => savePlaylistState());
      audioPlayer.currentIndexStream.listen((e) => savePlaybackState());
      audioPlayer.shuffleModeEnabledStream.listen((e) => savePlaybackState());
      audioPlayer.loopModeStream.listen((e) => savePlaybackState());
      audioPlayer.positionStream
          .throttleTime(const Duration(seconds: 5), trailing: true)
          .listen((position) => savePlaybackState());
    }
  }

  Future<void> savePlaylistState() async {
    List<String> songs = playlist.getSongs();
    PlaylistState playlistState = PlaylistState(
      host: connectionManager.url ?? "",
      name: playlist.name,
      songs: songs,
    );
    try {
      final playlistStateFile = await _getPlaylistStateFile(_currentVersion);
      await playlistStateFile.create(recursive: true);
      final playlistData = playlistState.toBytes();
      await playlistStateFile.writeAsBytes(playlistData, flush: true);
      developer.log('Wrote playlist state to: $playlistStateFile');
    } catch (e) {
      developer.log('Error while writing playlist state to disk: ', error: e);
    }
  }

  Future<void> savePlaybackState() async {
    PlaybackState playbackState = PlaybackState(
        currentSongIndex: audioPlayer.currentIndex ?? 0,
        currentSongProgressMilliseconds: audioPlayer.position.inMilliseconds,
        repeat: audioPlayer.loopMode == LoopMode.all,
        shuffle: audioPlayer.shuffleModeEnabled);
    try {
      final playbackStateFile = await _getPlaybackStateFile(_currentVersion);
      await playbackStateFile.create(recursive: true);
      final playbackData = playbackState.toBytes();
      await playbackStateFile.writeAsBytes(playbackData, flush: true);
      developer.log('Wrote playback state to: $playbackStateFile');
    } catch (e) {
      developer.log('Error while writing playback state to disk: ', error: e);
    }
  }

  Future<void> loadFromDisk() async {
    final playlistStateFile = await _getPlaylistStateFile(_currentVersion);
    try {
      if (await playlistStateFile.exists()) {
        final playlistData = await playlistStateFile.readAsBytes();
        PlaylistState playlistState = PlaylistState.fromBytes(playlistData);
        if (playlistState.host != connectionManager.url) {
          developer.log(
              'Ignored disk save state because of mismatch hosts. Current host: ${connectionManager.url}, savestate host: ${playlistState.host}');
          return;
        }
        await playlist.clear();
        await playlist.queueLast(playlistState.songs, autoPlay: false);
        playlist.setName(playlistState.name);
        collectionCache.putFiles(playlistState.host, playlistState.songs);
        developer.log('Read playlist state from: $playlistStateFile');
      }
    } catch (e) {
      developer.log('Error while reading playlist state from disk: ', error: e);
      return;
    }

    final playbackStateFile = await _getPlaybackStateFile(_currentVersion);
    try {
      if (await playbackStateFile.exists()) {
        final playbackData = await playbackStateFile.readAsBytes();
        PlaybackState playbackState = PlaybackState.fromBytes(playbackData);
        if (playbackState.currentSongIndex < (audioPlayer.sequence?.length ?? 0)) {
          await audioPlayer.seek(Duration(milliseconds: playbackState.currentSongProgressMilliseconds),
              index: playbackState.currentSongIndex);
        }
        audioPlayer.setLoopMode(playbackState.repeat ? LoopMode.all : LoopMode.off);
        audioPlayer.setShuffleModeEnabled(playbackState.shuffle);
        developer.log('Read playback state from: $playbackStateFile');
      }
    } catch (e) {
      developer.log('Error while reading playback state from disk: ', error: e);
    }
  }
}
