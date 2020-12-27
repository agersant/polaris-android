import 'package:flutter/widgets.dart';
import 'package:polaris/platform/dto.dart';

class Model extends ChangeNotifier {
  List<Song> currentAlbum;

  void openAlbumDetails(List<Song> songs) {
    currentAlbum = songs;
    notifyListeners();
  }

  void closeAlbumDetails() {
    currentAlbum = null;
    notifyListeners();
  }
}
