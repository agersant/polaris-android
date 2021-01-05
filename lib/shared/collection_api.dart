import 'package:http/http.dart';
import 'package:polaris/shared/dto.dart';

abstract class CollectionAPI {
  Future<List<CollectionFile>> browse(String path);
  Future<List<Directory>> random();
  Future<List<Directory>> recent();
  Uri getImageURI(String path);
  Future<StreamedResponse> downloadImage(String path);
  Future<StreamedResponse> downloadAudio(String path);
}
