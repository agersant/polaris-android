import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/dto.dart' as dto;

void main() {
  test('Read missing directory', () async {
    final cache = CollectionCache();
    assert(cache.getDirectory('', '') == null);
    assert(cache.getDirectory('some-host', 'any/bad/path') == null);
  });

  test('Read empty directory', () async {
    final cache = CollectionCache();
    cache.putDirectory('host', 'any/good/path', []);
    assert(cache.getDirectory('host', 'any/good/path') != null);
    assert(cache.getDirectory('host', 'any/good/path')!.isEmpty);
  });

  test('Populate and read song', () async {
    final cache = CollectionCache();
    final labyrinthSong = dto.CollectionFile(Left(dto.Song(path: 'root/Heron/Labyrinth.mp3')));
    cache.putDirectory('host', 'root/Heron', [labyrinthSong]);
    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isSong());
    assert(cachedContent![0].asSong().path == 'root/Heron/Labyrinth.mp3');
  });

  test('Populate and read directory', () async {
    final cache = CollectionCache();
    final aegeusDirectory = dto.CollectionFile(Right(dto.Directory(path: 'root/Heron/Aegeus')));
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isDirectory());
    assert(cachedContent![0].asDirectory().path == 'root/Heron/Aegeus');
  });

  test('Does not return unpopulated directory', () async {
    final cache = CollectionCache();
    final labyrinthSong = dto.CollectionFile(Left(dto.Song(path: 'root/Heron/Labyrinth.mp3')));
    cache.putDirectory('host', 'root/Heron', [labyrinthSong]);
    final cachedContent = cache.getDirectory('host', 'root');
    assert(cachedContent == null);
  });
}
