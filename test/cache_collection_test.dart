import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/dto.dart' as dto;

void main() {
  test('Canot read a missing directory', () async {
    final cache = CollectionCache();
    assert(cache.getDirectory('', '') == null);
    assert(cache.getDirectory('some-host', 'any/bad/path') == null);
  });

  test('Keeps track of populated directories', () async {
    final cache = CollectionCache();
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    assert(!cache.hasPopulatedDirectory('host', 'root'));
    assert(cache.hasPopulatedDirectory('host', 'root/Heron'));
  });

  test('Distinguishes hosts', () async {
    final cache = CollectionCache();
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    assert(cache.hasPopulatedDirectory('host', 'root/Heron'));
    assert(!cache.hasPopulatedDirectory('otherHost', 'root/Heron'));
  });

  test('Can read an empty directory', () async {
    final cache = CollectionCache();
    cache.putDirectory('host', 'any/good/path', []);
    assert(cache.getDirectory('host', 'any/good/path') != null);
    assert(cache.getDirectory('host', 'any/good/path')!.isEmpty);
  });

  test('Can populate and read a song', () async {
    final cache = CollectionCache();
    final labyrinthSong = dto.CollectionFile(Left(dto.Song(path: 'root/Heron/Labyrinth.mp3')));
    cache.putDirectory('host', 'root/Heron', [labyrinthSong]);
    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isSong());
    assert(cachedContent![0].asSong().path == 'root/Heron/Labyrinth.mp3');
  });

  test('Can populate and read a directory', () async {
    final cache = CollectionCache();
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isDirectory());
    assert(cachedContent![0].asDirectory().path == 'root/Heron/Aegeus');
  });

  test('Can populate and read an intermediate directory', () async {
    final cache = CollectionCache();
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    final cachedContent = cache.getDirectory('host', 'root');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isDirectory());
    assert(listEquals(p.split(cachedContent![0].asDirectory().path), ['root', 'Heron']));
  });

  test('Cannot flatten a missing directory', () async {
    final cache = CollectionCache();
    assert(cache.flattenDirectory('', '') == null);
    assert(cache.flattenDirectory('some-host', 'any/bad/path') == null);
  });

  test('Can flatten an empty directory', () async {
    final cache = CollectionCache();
    cache.putDirectory('host', 'any/good/path', []);
    assert(cache.flattenDirectory('host', 'any/good/path') != null);
    assert(cache.flattenDirectory('host', 'any/good/path')!.isEmpty);
  });

  test('Can populate and flatten a directory', () async {
    final cache = CollectionCache();
    final labyrinthSong = dto.CollectionFile(Left(dto.Song(path: 'root/Heron/Labyrinth.mp3')));
    final fallInwardsSong = dto.CollectionFile(Left(dto.Song(path: 'root/Heron/Fall Inwards.mp3')));
    cache.putDirectory('host', 'root/Heron', [labyrinthSong, fallInwardsSong]);
    final cachedContent = cache.flattenDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.length == 2);
  });
}
