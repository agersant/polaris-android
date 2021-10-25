import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/cache.dart' as cache;
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
  _AudioJob(this.path, this.audioSource);
}

class Manager {
  final cache.Interface _cacheManager;
  final connection.Manager _connectionManager;
  final polaris.HttpClient _httpClient;

  final Map<String, _ImageJob> _imageJobs = {};
  final Map<String, _AudioJob> _audioJobs = {};

  Manager({
    required cacheManager,
    required connectionManager,
    required httpClient,
  })  : _cacheManager = cacheManager,
        _connectionManager = connectionManager,
        _httpClient = httpClient;

  Future<Uint8List?> getImage(String path) async {
    final host = _connectionManager.url;
    if (host == null) {
      return Future.value(null);
    }

    final cacheHit = await _cacheManager.getImage(host, path);
    if (cacheHit != null) {
      return cacheHit.readAsBytes();
    }

    final _ImageJob? existingJob = _imageJobs[path];
    if (existingJob != null) {
      return existingJob.imageData;
    }

    developer.log('Downloading image: $path');
    final imageData = _httpClient.getImage(path).then((r) => http.Response.fromStream(r)).then((r) {
      if (r.statusCode >= 300) {
        throw r.statusCode;
      }
      _cacheManager.putImage(host, path, r.bodyBytes);
      return r.bodyBytes;
    }).catchError((e) {
      developer.log('Error while downloading image: $path', error: e);
      throw e;
    });

    final job = _ImageJob(path, imageData);
    _imageJobs[path] = job;
    job.imageData.whenComplete(() => _imageJobs.remove(job));

    return job.imageData;
  }

  Future<AudioSource?> getAudio(String path, MediaItem mediaItem) async {
    final host = _connectionManager.url;
    if (host == null) {
      return null;
    }

    final File? cacheHit = await _cacheManager.getAudio(host, path);
    if (cacheHit != null) {
      return AudioSource.uri(cacheHit.uri, tag: mediaItem);
    }

    final _AudioJob? existingJob = _audioJobs[path];
    if (existingJob != null) {
      // TODO.important when songs are duped in the playlist, this may return an audiosource
      // with a mediaItem.id that doesn't match what the caller requested.
      return existingJob.audioSource;
    }

    final uri = _httpClient.getAudioURI(path);
    // TODO.important https://github.com/ryanheise/just_audio/issues/569
    // final cacheFile = _cacheManager.getAudioLocation(host, path);
    // final audioSource = LockCachingAudioSource(uri, cacheFile: cacheFile, tag: mediaItem);
    final audioSource = AudioSource.uri(uri, tag: mediaItem);

    final job = _AudioJob(path, audioSource);
    _audioJobs[path] = job;

    // TODO eventually remove the job from _audioJobs (some combination of no longer in playlist, being played, being pre-fetched, fully downloaded)

    return job.audioSource;
  }
}
