import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/dto.dart' as dto;

void main() {
  test('Canot read a missing directory', () async {
    final cache = CollectionCache(Collection());
    assert(cache.getDirectory('', '') == null);
    assert(cache.getDirectory('some-host', 'any/bad/path') == null);
  });

  test('Keeps track of populated directories', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    assert(!cache.hasPopulatedDirectory('host', 'root'));
    assert(cache.hasPopulatedDirectory('host', 'root/Heron'));
  });

  test('Distinguishes hosts', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    assert(cache.hasPopulatedDirectory('host', 'root/Heron'));
    assert(!cache.hasPopulatedDirectory('otherHost', 'root/Heron'));
  });

  test('Can read an empty directory', () async {
    final cache = CollectionCache(Collection());
    cache.putDirectory('host', 'any/good/path', []);
    assert(cache.getDirectory('host', 'any/good/path') != null);
    assert(cache.getDirectory('host', 'any/good/path')!.isEmpty);
  });

  test('Can populate and read a song', () async {
    final cache = CollectionCache(Collection());
    final labyrinthSong = dto.CollectionFile(Left(dto.Song(path: 'root/Heron/Labyrinth.mp3')));
    cache.putDirectory('host', 'root/Heron', [labyrinthSong]);
    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isSong());
    assert(cachedContent![0].asSong().path == 'root/Heron/Labyrinth.mp3');
  });

  test('Can populate and read a directory', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isDirectory());
    assert(cachedContent![0].asDirectory().path == 'root/Heron/Aegeus');
  });

  test('Can populate and read an intermediate directory', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    final cachedContent = cache.getDirectory('host', 'root');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isDirectory());
    assert(listEquals(p.split(cachedContent![0].asDirectory().path), ['root', 'Heron']));
  });

  test('Preserves directory content when updating its metadata', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);

    final heronDTODirectory = dto.Directory(path: 'root/Heron');
    heronDTODirectory.artwork = 'some-artwork';
    final heronDirectory = dto.CollectionFile(Right(heronDTODirectory));
    cache.putDirectory('host', 'root', [heronDirectory]);

    {
      final cachedContent = cache.getDirectory('host', 'root');
      assert(cachedContent != null);
      assert(cachedContent!.isNotEmpty);
      assert(cachedContent![0].isDirectory());
      assert(cachedContent![0].asDirectory().path == 'root/Heron');
      assert(cachedContent![0].asDirectory().artwork == 'some-artwork');
    }

    {
      final cachedContent = cache.getDirectory('host', 'root/Heron');
      assert(cachedContent != null);
      assert(cachedContent!.isNotEmpty);
      assert(cachedContent![0].isDirectory());
      assert(cachedContent![0].asDirectory().path == 'root/Heron/Aegeus');
    }
  });

  test('Removes deleted content when populating', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    final bonusTrack = dto.CollectionFile(Left(dto.Song(path: 'root/Heron/bonus-track.mp3')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory, bonusTrack]);

    final eonsDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Eons')));
    cache.putDirectory('host', 'root/Heron', [eonsDirectory]);

    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isDirectory());
    assert(cachedContent![0].asDirectory().path == 'root/Heron/Eons');
  });

  test('Cannot flatten a missing directory', () async {
    final cache = CollectionCache(Collection());
    assert(cache.flattenDirectory('', '') == null);
    assert(cache.flattenDirectory('some-host', 'any/bad/path') == null);
  });

  test('Can flatten an empty directory', () async {
    final cache = CollectionCache(Collection());
    cache.putDirectory('host', 'any/good/path', []);
    assert(cache.flattenDirectory('host', 'any/good/path') != null);
    assert(cache.flattenDirectory('host', 'any/good/path')!.isEmpty);
  });

  test('Can populate and flatten a directory', () async {
    final cache = CollectionCache(Collection());
    final labyrinthSong = dto.CollectionFile(Left(dto.Song(path: 'root/Heron/Labyrinth.mp3')));
    final fallInwardsSong = dto.CollectionFile(Left(dto.Song(path: 'root/Heron/Fall Inwards.mp3')));
    cache.putDirectory('host', 'root/Heron', [labyrinthSong, fallInwardsSong]);
    final cachedContent = cache.flattenDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.length == 2);
  });

  test('Can serialize song', () async {
    final Song song = Song(dto.Song(path: 'root/Heron/Labyrinth.mp3'));
    {
      final Song deserialized = Song.fromJson(song.toJson());
      assert(deserialized.data.path == 'root/Heron/Labyrinth.mp3');
    }
    {
      final File file = File(Left(song));
      final File deserialized = File.fromJson(file.toJson());
      assert(deserialized.asSong().data.path == 'root/Heron/Labyrinth.mp3');
    }
  });

  test('Can serialize directory', () async {
    final Song song = Song(dto.Song(path: 'root/Heron/Labyrinth.mp3'));
    final Directory aegeus = Directory(data: dto.Directory(path: 'root/Heron/Aegeus'));
    final Directory directory = Directory(
      data: dto.Directory(path: 'root/Heron'),
      children: {'Labyrinth.mp3': File(Left(song)), 'Aegeus': File(Right(aegeus))},
    );
    final Directory deserialized = Directory.fromJson(directory.toJson());
    assert(deserialized.data != null);
    assert(deserialized.data!.path == 'root/Heron');
    assert(deserialized.children.isNotEmpty);
    assert(deserialized.children['Labyrinth.mp3']!.asSong().data.path == 'root/Heron/Labyrinth.mp3');
    assert(deserialized.children['Aegeus']!.asDirectory().data!.path == 'root/Heron/Aegeus');
  });

  test('Can serialize collection to json', () async {
    final collection = Collection();
    final dto.Song song = dto.Song(path: 'root/Heron/Aegeus/Labyrinth.mp3');
    collection.populateDirectory('host', 'root/Heron/Aegeus', [dto.CollectionFile(Left(song))]);
    final Collection deserialized = Collection.fromJson(collection.toJson());
    final cachedContent = deserialized.readDirectory('host', 'root/Heron/Aegeus');
    assert(cachedContent != null);
    assert(cachedContent!.children.isNotEmpty);
    assert(cachedContent!.children['Labyrinth.mp3']!.isSong());
    assert(cachedContent!.children['Labyrinth.mp3']!.asSong().data.path == 'root/Heron/Aegeus/Labyrinth.mp3');
  });

  test('Can serialize collection to bytes', () async {
    final collection = Collection();
    final dto.Song song = dto.Song(path: 'root/Heron/Aegeus/Labyrinth.mp3');
    collection.populateDirectory('host', 'root/Heron/Aegeus', [dto.CollectionFile(Left(song))]);
    final Collection deserialized = Collection.fromBytes(collection.toBytes());
    final cachedContent = deserialized.readDirectory('host', 'root/Heron/Aegeus');
    assert(cachedContent != null);
    assert(cachedContent!.children.isNotEmpty);
    assert(cachedContent!.children['Labyrinth.mp3']!.isSong());
    assert(cachedContent!.children['Labyrinth.mp3']!.asSong().data.path == 'root/Heron/Aegeus/Labyrinth.mp3');
  });
}
