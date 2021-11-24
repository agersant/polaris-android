import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polaris/core/unique_timer.dart';

const _firstVersion = 1;
const _currentVersion = 4;

abstract class MediaCacheInterface {
  void dispose();
  Future<bool> hasImage(String host, String path);
  Future<io.File?> getImage(String host, String path);
  io.File getImageLocation(String host, String path);
  Future<void> putImage(String host, String path, Uint8List bytes);
  Future<bool> hasAudio(String host, String path);
  Future<void> putAudio(String host, String path, io.File source);
  bool hasAudioSync(String host, String path);
  Future<io.File?> getAudio(String host, String path);
  io.File getAudioLocation(String host, String path);
  Future<void> purge(Map<String, Set<String>> songsToPreserve, Map<String, Set<String>> imagesToPreserve);
}

class MediaCache implements MediaCacheInterface {
  final io.Directory _root;
  final LRU _lru;
  late UniqueTimer _lruWriteTimer;

  MediaCache(this._root, this._lru) {
    _lruWriteTimer = UniqueTimer(duration: const Duration(seconds: 5), callback: _saveLRUToDisk);
    _lruWriteTimer.cancel();
  }

  static io.File _getLRUFile(io.Directory root) {
    return io.File(p.join(root.path, 'usage.lru'));
  }

  static Future<MediaCache> create() async {
    final temporaryDirectory = await getTemporaryDirectory();
    makeRoot(int version) => io.Directory(p.join(temporaryDirectory.path, 'media', 'v$version'));

    for (int version = _firstVersion; version < _currentVersion; version++) {
      final oldRoot = makeRoot(version);
      oldRoot.exists().then((exists) {
        if (exists) {
          oldRoot.delete(recursive: true);
        }
      });
    }

    final root = makeRoot(_currentVersion);
    await root.create(recursive: true);

    LRU lru = LRU();
    final lruFile = _getLRUFile(root);
    try {
      if (await lruFile.exists()) {
        final lruData = await lruFile.readAsBytes();
        lru = LRU.fromBytes(lruData);
        developer.log('Read media cache LRU data from: $lruFile');
      }
    } catch (e) {
      developer.log('Error while reading media cache LRU from disk: ', error: e);
    }

    return MediaCache(root, lru);
  }

  @override
  void dispose() {
    _lruWriteTimer.cancel();
  }

  Future<void> _saveLRUToDisk() async {
    try {
      final lruFile = _getLRUFile(_root);
      await lruFile.create(recursive: true);
      final serializedData = _lru.toBytes();
      await lruFile.writeAsBytes(serializedData, flush: true);
      developer.log('Wrote media cache LRU data to: $lruFile');
    } catch (e) {
      developer.log('Error while writing media cache LRU data to disk: ', error: e);
    }
  }

  @override
  Future<bool> hasImage(String host, String path) async {
    final file = getImageLocation(host, path);
    return file.exists();
  }

  @override
  Future<io.File?> getImage(String host, String path) async {
    final fullPath = _buildImagePath(host, path);
    final file = io.File(fullPath);
    try {
      if (await file.exists()) {
        developer.log('Found image in disk cache: $path');
        _lru.upsert(fullPath);
        _lruWriteTimer.reset();
        return file;
      }
    } catch (e) {
      developer.log('Error while accessing image from disk cache: $path', error: e);
    }
    return null;
  }

  @override
  io.File getImageLocation(String host, String path) {
    final fullPath = _buildImagePath(host, path);
    return io.File(fullPath);
  }

  @override
  io.File getAudioLocation(String host, String path) {
    final fullPath = _buildAudioPath(host, path);
    return io.File(fullPath);
  }

  @override
  Future<bool> hasAudio(String host, String path) async {
    final file = getAudioLocation(host, path);
    return file.exists();
  }

  @override
  Future<void> putAudio(String host, String path, io.File source) async {
    developer.log('Adding audio to disk cache: $path');
    final targetFile = getAudioLocation(host, path);
    try {
      _lru.upsert(targetFile.path);
      _lruWriteTimer.reset();
      {
        // We already download audio file where they should end up
        assert(source.path == targetFile.path);
        // await source.copy(targetFile.path);
      }
    } catch (e) {
      developer.log('Error while adding audio to disk cache: $path', error: e);
    }
  }

  @override
  bool hasAudioSync(String host, String path) {
    final file = getAudioLocation(host, path);
    return file.existsSync();
  }

  @override
  Future<io.File?> getAudio(String host, String path) async {
    final file = getAudioLocation(host, path);
    try {
      if (await file.exists()) {
        developer.log('Found audio in disk cache: $path');
        _lru.upsert(file.path);
        _lruWriteTimer.reset();
        return file;
      }
    } catch (e) {
      developer.log('Error while accessing audio from disk cache: $path', error: e);
    }
    return null;
  }

  @override
  putImage(String host, String path, Uint8List bytes) async {
    developer.log('Adding image to disk cache: $path');
    final fullPath = _buildImagePath(host, path);
    final file = io.File(fullPath);
    try {
      _lru.upsert(fullPath);
      _lruWriteTimer.reset();
      await file.writeAsBytes(bytes, mode: io.FileMode.writeOnly, flush: true);
    } catch (e) {
      developer.log('Error while adding image to disk cache: $path', error: e);
    }
  }

  @override
  Future<void> purge(
    Map<String, Set<String>> songsToPreserve,
    Map<String, Set<String>> imagesToPreserve,
  ) async {
    try {
      developer.log('Purging unused files from disk cache');

      final List<String> deletionCandidates = await _listDeletionCandidates(songsToPreserve, imagesToPreserve);
      final List<int> sizes = await Future.wait(deletionCandidates.map((path) async {
        final file = io.File(path);
        final stat = await file.stat();
        return stat.size;
      }));
      int cacheSize = sizes.fold(0, (a, b) => a + b);
      const maxCacheSize = 800 * 1024 * 1024; // 800MB, TODO make adjustable in settings

      int numFilesRemoved = 0;
      io.File lruFile = _getLRUFile(_root);
      while (cacheSize > maxCacheSize && deletionCandidates.isNotEmpty) {
        final String path = deletionCandidates.removeAt(0);
        final io.File file = io.File(path);
        final stat = await file.stat();
        final isPartFile = p.extension(file.path) == '.part';
        final isLRUFile = file.path == lruFile.path;
        final isStale = stat.modified.difference(DateTime.now()) > const Duration(hours: 1);
        if (isLRUFile || (isPartFile && !isStale)) {
          continue;
        }
        await file.delete();
        _lru.data.remove(path);
        cacheSize -= stat.size;
        numFilesRemoved += 1;
      }
      developer.log(
          'Deleted $numFilesRemoved files from media cache. ${deletionCandidates.length} eligible files left intact, totalling ${cacheSize / (1024 * 1024)} MB.');
    } catch (e) {
      developer.log('Error purging files from media cache', error: e);
    }
  }

  Future<List<String>> _listDeletionCandidates(
    Map<String, Set<String>> songsToPreserve,
    Map<String, Set<String>> imagesToPreserve,
  ) async {
    final Set<String> filesToPreserve = {};
    songsToPreserve.forEach((host, songs) {
      filesToPreserve.addAll(songs.map((path) => _buildAudioPath(host, path)));
    });
    imagesToPreserve.forEach((host, images) {
      filesToPreserve.addAll(images.map((path) => _buildImagePath(host, path)));
    });

    final List<String> deletionCandidates = [];

    await for (final fileEntity in _root.list()) {
      if (!filesToPreserve.contains(fileEntity.path)) {
        deletionCandidates.add(fileEntity.path);
      }
    }

    deletionCandidates.sort((a, b) {
      final aUsed = _lru.data[a] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bUsed = _lru.data[b] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aUsed.compareTo(bUsed);
    });

    return deletionCandidates;
  }

  String _sanitize(String input) {
    return sha1.convert(utf8.encode(input)).toString();
  }

  String _buildImagePath(String host, String path) {
    return p.join(_root.path, 'image_' + _sanitize(host + '::' + path));
  }

  String _buildAudioPath(String host, String path) {
    return p.join(_root.path, 'audio_' + _sanitize(host + '::' + path));
  }
}

class LRU {
  final Map<String, DateTime> data = {};

  LRU();

  void upsert(String path) {
    data[path] = DateTime.now();
  }

  factory LRU.fromBytes(List<int> bytes) {
    return LRU.fromJson(jsonDecode(utf8.decode(io.gzip.decode(bytes))));
  }

  List<int> toBytes() {
    return io.gzip.encode(utf8.encode(jsonEncode(this)));
  }

  LRU.fromJson(Map<String, dynamic> json) {
    json['data'].forEach((String path, dynamic dateTime) {
      final lastUsed = DateTime.tryParse(dateTime);
      if (lastUsed != null) {
        data[path] = lastUsed;
      }
    });
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'data': data.map(
          (path, lastUsed) => MapEntry(path, lastUsed.toIso8601String()),
        ),
      };
}
