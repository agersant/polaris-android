import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/client/api/api_client.dart';

class _ImageJob {
  Future<Uint8List> imageData;
  _ImageJob(this.imageData);
}

class _AudioJob {
  String path;
  LockCachingAudioSource audioSource;
  Map<String, AudioSource> dupeAudioSources = {};
  Stream<double> progressStream;
  _AudioJob(this.path, this.audioSource, this.progressStream);
}

class Manager {
  final MediaCacheInterface mediaCache;
  final APIClient apiClient;

  final Map<(String, ArtworkSize), _ImageJob> _imageJobs = {};
  final Map<String, _AudioJob> _audioJobs = {};

  Manager({
    required this.mediaCache,
    required this.apiClient,
  });

  Future<Uint8List?> getImage(String host, String path, ArtworkSize size) async {
    final cacheHit = await mediaCache.getImage(host, path, size);
    if (cacheHit != null) {
      return cacheHit.readAsBytes();
    }

    final _ImageJob? existingJob = _imageJobs[(path, size)];
    if (existingJob != null) {
      return existingJob.imageData;
    }

    developer.log('Downloading ${size.name} image: $path');
    final imageData = apiClient.getImage(path, size).then((r) => http.Response.fromStream(r)).then((r) {
      mediaCache.putImage(host, path, size, r.bodyBytes);
      return r.bodyBytes;
    });

    final job = _ImageJob(imageData);
    _imageJobs[(path, size)] = job;
    job.imageData.whenComplete(() => _imageJobs.remove(job));

    return job.imageData;
  }

  Future<AudioSource?> getAudio(String host, String path, MediaItem mediaItem) async {
    final File? cacheHit = await mediaCache.getAudio(host, path);
    if (cacheHit != null) {
      return AudioSource.uri(cacheHit.uri, tag: mediaItem);
    }

    final _AudioJob? existingJob = _audioJobs[path];
    if (existingJob != null) {
      final MediaItem canonicalMediaItem = existingJob.audioSource.tag;
      if (canonicalMediaItem.id == mediaItem.id) {
        return existingJob.audioSource;
      }
      final existingAudioSource = existingJob.dupeAudioSources[mediaItem.id];
      if (existingAudioSource != null) {
        return existingAudioSource;
      }
      final newAudioSource = DupeCachingAudioSource(existingJob.audioSource, mediaItem);
      existingJob.dupeAudioSources[mediaItem.id] = newAudioSource;
      return newAudioSource;
    }

    final uri = apiClient.getAudioURI(path);
    final cacheFile = mediaCache.getAudioLocation(host, path);
    final audioSource = LockCachingAudioSource(uri, cacheFile: cacheFile, tag: mediaItem);
    final progressStream = audioSource.downloadProgressStream.asBroadcastStream();
    final job = _AudioJob(path, audioSource, progressStream);

    late StreamSubscription progressSubscription;
    progressSubscription = progressStream.listen((progress) async {
      if (progress >= 1.0) {
        developer.log('Downloaded audio: $cacheFile');
        mediaCache.putAudio(host, path, await audioSource.cacheFile);
        progressSubscription.cancel();
        _audioJobs.remove(path);
      }
    });

    _audioJobs[path] = job;

    return job.audioSource;
  }
}

class DupeCachingAudioSource extends StreamAudioSource {
  LockCachingAudioSource originalAudioSource;

  DupeCachingAudioSource(this.originalAudioSource, dynamic tag) : super(tag: tag);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return originalAudioSource.request(start, end);
  }
}
