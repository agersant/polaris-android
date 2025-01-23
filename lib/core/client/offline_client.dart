import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/client/constants.dart';
import 'package:polaris/core/dto.dart' as dto;

class OfflineClient {
  final MediaCacheInterface mediaCache;
  final CollectionCache collectionCache;

  OfflineClient({required this.mediaCache, required this.collectionCache});

  Future<List<dto.BrowserEntry>> browse(String host, String path) async {
    final cachedContent = collectionCache.getDirectory(host, path);
    if (cachedContent == null) {
      throw APIError.unexpectedCacheMiss;
    }

    return cachedContent.where((entry) {
      if (!entry.isDirectory) {
        return mediaCache.hasAudioSync(host, entry.path);
      } else {
        final flattened = collectionCache.flattenDirectory(host, entry.path);
        return flattened?.any((path) => mediaCache.hasAudioSync(host, path)) ?? false;
      }
    }).toList();
  }

  Future<dto.SongList> flatten(String host, String path) async {
    final cachedContent = collectionCache.flattenDirectory(host, path);
    if (cachedContent == null) {
      throw APIError.unexpectedCacheMiss;
    }
    final paths = cachedContent.where((path) => mediaCache.hasAudioSync(host, path)).toList();
    return dto.SongList(paths: paths, firstSongs: []);
  }

  Future<Uint8List?> getImage(String host, String path) async {
    final cacheFile = await mediaCache.getImage(host, path);
    return cacheFile?.readAsBytes();
  }

  Future<AudioSource?> getAudio(String host, String path, MediaItem mediaItem) async {
    final cacheFile = await mediaCache.getAudio(host, path);
    if (cacheFile == null) {
      return null;
    }
    return AudioSource.uri(cacheFile.uri, tag: mediaItem);
  }
}
