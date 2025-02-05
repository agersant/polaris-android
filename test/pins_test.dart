import 'mock/client.dart' as mock;
import 'mock/connection.dart' as mock;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/pin.dart' as pin;
import 'package:shared_preferences/shared_preferences.dart';

const host = 'host';
const song = 'root/Heron/Aegeus/Labyrinth.mp3';
const directory = 'root/Heron/Aegeus';
const album = 'Aegeus';
const mainArtists = ['Heron'];
const artwork = '$directory/art.jpg';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  pin.Manager makePinManager() {
    final connectionManager = mock.ConnectionManager(host);
    final apiClient = mock.APIClient();
    final appClient = mock.AppClient(apiClient);

    return pin.Manager(
      pin.Pins([]),
      connectionManager: connectionManager,
      appClient: appClient,
    );
  }

  test('Can add/remove song', () async {
    final pin.Manager pinManager = makePinManager();

    assert(pinManager.countSongs() == 0);
    pinManager.pinSong(host, song);
    assert(pinManager.countSongs() == 1);
    assert(pinManager.getPinsForHost(host).whereType<pin.SongPin>().length == 1);
    assert(pinManager.getSongsInHost(host).length == 1);
    assert(pinManager.getSongsInHost(host).contains(song));

    pinManager.unpinSong(host, song);
    assert(pinManager.countSongs() == 0);
  });

  test('Can add/remove directory', () async {
    final pin.Manager pinManager = makePinManager();

    await pinManager.pinDirectory(host, directory);
    assert(pinManager.getPinsForHost(host).whereType<pin.DirectoryPin>().length == 1);

    pinManager.unpinDirectory(host, directory);
    assert(pinManager.getPinsForHost(host).isEmpty);
  });

  test('Can serialize pins list to json', () async {
    final storage = pin.Pins([]);
    storage.pins.addAll([
      pin.SongPin(host, song),
      pin.DirectoryPin(host, directory, [song]),
      pin.AlbumPin(host, album, mainArtists, [song], artwork),
    ]);

    final pin.Pins deserialized = pin.Pins.fromJson(storage.toJson());

    assert(deserialized.pins.whereType<pin.SongPin>().any((p) => p.path == song));
    assert(
        deserialized.pins.whereType<pin.DirectoryPin>().any((p) => p.path == directory && listEquals(p.songs, [song])));
    assert(deserialized.pins
        .whereType<pin.AlbumPin>()
        .any((p) => p.name == album && listEquals(p.mainArtists, mainArtists) && listEquals(p.songs, [song])));
  });

  test('Can serialize pins list to bytes', () async {
    final storage = pin.Pins([]);
    storage.pins.addAll([
      pin.SongPin(host, song),
      pin.DirectoryPin(host, directory, [song]),
      pin.AlbumPin(host, album, mainArtists, [song], artwork),
    ]);

    final pin.Pins deserialized = pin.Pins.fromJson(storage.toJson());

    assert(deserialized.pins.whereType<pin.SongPin>().any((p) => p.path == song));
    assert(
        deserialized.pins.whereType<pin.DirectoryPin>().any((p) => p.path == directory && listEquals(p.songs, [song])));
    assert(deserialized.pins
        .whereType<pin.AlbumPin>()
        .any((p) => p.name == album && listEquals(p.mainArtists, mainArtists) && listEquals(p.songs, [song])));
  });
}
