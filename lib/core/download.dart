import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:polaris/core/polaris.dart' as polaris;

class _ImageJob {
  String path;
  Future<Uint8List> imageData;
  _ImageJob(this.path, this.imageData);
}

class Manager {
  final _imageJobs = Map<String, _ImageJob>();
  final polaris.HttpClient _httpClient;

  Manager({required httpClient}) : _httpClient = httpClient;

  Future<Uint8List?> downloadImage(String path) {
    final _ImageJob? existingJob = _imageJobs[path];
    if (existingJob != null) {
      return existingJob.imageData;
    }

    final imageData = _httpClient.getImage(path).then((r) => http.Response.fromStream(r)).then((r) {
      if (r.statusCode >= 300) {
        throw r.statusCode;
      }
      return r.bodyBytes;
    }).catchError((e) {
      developer.log('Error downloading image: $path', error: e);
      throw e;
    });

    final job = _ImageJob(path, imageData);
    _imageJobs[path] = job;
    job.imageData.whenComplete(() async {
      _imageJobs.remove(job);
    });

    return job.imageData;
  }
}
