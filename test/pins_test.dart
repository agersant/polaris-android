import 'mock/client.dart' as mock;
import 'mock/media_cache.dart' as mock;
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/core/dto.dart' as dto;

void main() {
  pin.Manager makePinManager() {
    final mockHttpClient = mock.HttpClient();
    final collectionCache = CollectionCache(Collection());
    final connectionManager = connection.Manager(httpClient: mockHttpClient);
    final mediaCache = mock.MediaCache();
    final authenticationManager = authentication.Manager(
      httpClient: mockHttpClient,
      connectionManager: connectionManager,
    );
    final polarisHttpClient = polaris.HttpClient(
      httpClient: mockHttpClient,
      connectionManager: connectionManager,
      authenticationManager: authenticationManager,
    );
    final polarisOfflineClient = polaris.OfflineClient(
      collectionCache: collectionCache,
      mediaCache: mediaCache,
    );
    final downloadManager = download.Manager(
      mediaCache: mediaCache,
      httpClient: polarisHttpClient,
    );
    final polarisClient = polaris.Client(
      collectionCache: collectionCache,
      connectionManager: connectionManager,
      mediaCache: mediaCache,
      httpClient: polarisHttpClient,
      offlineClient: polarisOfflineClient,
      downloadManager: downloadManager,
    );
    return pin.Manager(
      pin.Storage(),
      connectionManager: connectionManager,
      polarisClient: polarisClient,
    );
  }

  test('Can add/remove song', () async {
    final pin.Manager pinManager = makePinManager();

    final dto.Song song = dto.Song(path: 'root/Heron/Aegeus/Labyrinth.mp3');
    pinManager.pin('host', dto.CollectionFile(Left(song)));
    assert(pinManager.getSongs('host').isNotEmpty);
    assert(pinManager.getSongs('host').first.path == 'root/Heron/Aegeus/Labyrinth.mp3');

    pinManager.unpin('host', dto.CollectionFile(Left(song)));
    assert(pinManager.getSongs('host').isEmpty);
  });

  test('Can add/remove directory', () async {
    final pin.Manager pinManager = makePinManager();

    final dto.Directory directory = dto.Directory(path: 'root/Heron/Aegeus');
    pinManager.pin('host', dto.CollectionFile(Right(directory)));
    assert(pinManager.getDirectories('host').isNotEmpty);
    assert(pinManager.getDirectories('host').first.path == 'root/Heron/Aegeus');

    pinManager.unpin('host', dto.CollectionFile(Right(directory)));
    assert(pinManager.getDirectories('host').isEmpty);
  });

  test('Can serialize pins list to json', () async {
    final storage = pin.Storage();

    final dto.Song song = dto.Song(path: 'root/Heron/Aegeus/Labyrinth.mp3');
    storage.add('host', dto.CollectionFile(Left(song)));

    final dto.Directory directory = dto.Directory(path: 'root/Heron/Eons');
    storage.add('host', dto.CollectionFile(Right(directory)));

    final pin.Storage deserialized = pin.Storage.fromJson(storage.toJson());
    assert(deserialized.contains('host', dto.CollectionFile(Left(song))));
    assert(deserialized.contains('host', dto.CollectionFile(Right(directory))));
  });

  test('Can serialize pins list to bytes', () async {
    final storage = pin.Storage();

    final dto.Song song = dto.Song(path: 'root/Heron/Aegeus/Labyrinth.mp3');
    storage.add('host', dto.CollectionFile(Left(song)));

    final dto.Directory directory = dto.Directory(path: 'root/Heron/Eons');
    storage.add('host', dto.CollectionFile(Right(directory)));

    final pin.Storage deserialized = pin.Storage.fromBytes(storage.toBytes());
    assert(deserialized.contains('host', dto.CollectionFile(Left(song))));
    assert(deserialized.contains('host', dto.CollectionFile(Right(directory))));
  });
}
