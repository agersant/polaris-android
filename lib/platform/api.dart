import 'dart:typed_data';
import 'package:polaris/platform/dto.dart';

enum APIError {
  unspecifiedHost,
  networkError,
  unauthorized,
  responseParseError,
  requestFailed,
}

abstract class API {
  Future<APIVersion> getAPIVersion();
  Future<Authorization> login(String username, String password);
  Future<List<CollectionFile>> browse(String path);
  Future<List<Directory>> random();
  Future<List<Directory>> recent();
  Future<Uint8List> downloadImage(String path);
  Uri getAudioURI(String path);
}
