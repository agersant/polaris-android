import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/polaris.dart' as polaris;

class _ImageJob {
  String path;
  Future<Uint8List> imageData;
  _ImageJob(this.path, this.imageData);
}

class _AudioJob {
  String path;
  AudioSource audioSource;
  Stream<double> progressStream;
  _AudioJob(this.path, this.audioSource, this.progressStream);
}

class Manager {
  final MediaCacheInterface mediaCache;
  final connection.Manager connectionManager;
  final polaris.HttpClient httpClient;

  final Map<String, _ImageJob> _imageJobs = {};
  final Map<String, _AudioJob> _audioJobs = {};

  Manager({
    required this.mediaCache,
    required this.connectionManager,
    required this.httpClient,
  });

  Future<Uint8List?> getImage(String path) async {
    final host = connectionManager.url;
    if (host == null) {
      return Future.value(null);
    }

    final cacheHit = await mediaCache.getImage(host, path);
    if (cacheHit != null) {
      return cacheHit.readAsBytes();
    }

    final _ImageJob? existingJob = _imageJobs[path];
    if (existingJob != null) {
      return existingJob.imageData;
    }

    developer.log('Downloading image: $path');
    final imageData = httpClient.getImage(path).then((r) => http.Response.fromStream(r)).then((r) {
      if (r.statusCode >= 300) {
        throw r.statusCode;
      }
      mediaCache.putImage(host, path, r.bodyBytes);
      return r.bodyBytes;
    }).catchError((dynamic e) {
      developer.log('Error while downloading image: $path', error: e);
      throw e;
    });

    final job = _ImageJob(path, imageData);
    _imageJobs[path] = job;
    job.imageData.whenComplete(() => _imageJobs.remove(job));

    return job.imageData;
  }

  Future<AudioSource?> getAudio(String path, MediaItem mediaItem) async {
    final host = connectionManager.url;
    if (host == null) {
      return null;
    }

    final File? cacheHit = await mediaCache.getAudio(host, path);
    if (cacheHit != null) {
      return AudioSource.uri(cacheHit.uri, tag: mediaItem);
    }

    final _AudioJob? existingJob = _audioJobs[path];
    if (existingJob != null) {
      // TODO.important when songs are duped in the playlist, this may return an
      // audiosource with a mediaItem.id that doesn't match what the caller requested.
      // We also can't make a new audio source because it will fight for access to the
      // cache file (and dupe the download).
      return existingJob.audioSource;
    }

    final uri = httpClient.getAudioURI(path);
    final cacheFile = mediaCache.getAudioLocation(host, path);
    final audioSource = LockCachingAudioSource(uri, cacheFile: cacheFile, tag: mediaItem);
    final progressStream = audioSource.downloadProgressStream.asBroadcastStream();
    final job = _AudioJob(path, audioSource, progressStream);

    late StreamSubscription progressSubscription;
    progressSubscription = progressStream.listen((progress) {
      if (progress >= 1.0) {
        developer.log('Downloaded audio: $cacheFile');
        progressSubscription.cancel();
        _audioJobs.remove(path);
      }
    });

    _audioJobs[path] = job;

    // TODO remove outdated jobs from _audioJobs (some combination of no longer in playlist, not being pending pin)

    return job.audioSource;
  }
}
