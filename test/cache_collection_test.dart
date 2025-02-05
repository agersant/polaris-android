import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;

void main() {
  test('Canot read a missing directory', () async {
    final cache = CollectionCache(Collection());
    assert(cache.getDirectory('', '') == null);
    assert(cache.getDirectory('some-host', 'any/bad/path') == null);
  });

  test('Keeps track of populated directories', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.BrowserEntry(path: 'root/Heron/Aegeus', isDirectory: true);
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    assert(!cache.hasPopulatedDirectory('host', 'root'));
    assert(cache.hasPopulatedDirectory('host', 'root/Heron'));
  });

  test('Distinguishes hosts', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.BrowserEntry(path: 'root/Heron/Aegeus', isDirectory: true);
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

  test('Can read directory with one file', () async {
    final cache = CollectionCache(Collection());
    final labyrinthSong = dto.BrowserEntry(path: 'root/Heron/Labyrinth.mp3', isDirectory: false);
    cache.putDirectory('host', 'root/Heron', [labyrinthSong]);
    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(!cachedContent![0].isDirectory);
    assert(cachedContent![0].path == 'root/Heron/Labyrinth.mp3');
  });

  test('Can read directory with one subdirectory', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.BrowserEntry(path: 'root/Heron/Aegeus', isDirectory: true);
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);
    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isDirectory);
    assert(cachedContent![0].path == 'root/Heron/Aegeus');
  });

  test('Can read implicit parent directory', () async {
    final cache = CollectionCache(Collection());
    cache.putFiles('host', ['root/Heron/Aegeus/Labyrinth.mp3']);
    final cachedContent = cache.getDirectory('host', 'root');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isDirectory);
    assert(listEquals(p.split(cachedContent![0].path), ['root', 'Heron']));
  });

  test('Preserves directory content when updating its parent', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.BrowserEntry(path: 'root/Heron/Aegeus', isDirectory: true);
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory]);

    final heronDirectory = dto.BrowserEntry(path: 'root/Heron', isDirectory: true);
    cache.putDirectory('host', 'root', [heronDirectory]);

    {
      final cachedContent = cache.getDirectory('host', 'root');
      assert(cachedContent != null);
      assert(cachedContent!.isNotEmpty);
      assert(cachedContent![0].isDirectory);
      assert(cachedContent![0].path == 'root/Heron');
    }

    {
      final cachedContent = cache.getDirectory('host', 'root/Heron');
      assert(cachedContent != null);
      assert(cachedContent!.isNotEmpty);
      assert(cachedContent![0].isDirectory);
      assert(cachedContent![0].path == 'root/Heron/Aegeus');
    }
  });

  test('Removes deleted content when populating directory', () async {
    final cache = CollectionCache(Collection());
    final aegeusDirectory = dto.BrowserEntry(path: 'root/Heron/Aegeus', isDirectory: true);
    final bonusTrack = dto.BrowserEntry(path: 'root/Heron/bonus-track.mp3', isDirectory: false);
    cache.putDirectory('host', 'root/Heron', [aegeusDirectory, bonusTrack]);

    final eonsDirectory = dto.BrowserEntry(path: 'root/Heron/Eons', isDirectory: true);
    cache.putDirectory('host', 'root/Heron', [eonsDirectory]);

    final cachedContent = cache.getDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(cachedContent!.isNotEmpty);
    assert(cachedContent![0].isDirectory);
    assert(cachedContent![0].path == 'root/Heron/Eons');
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
    final labyrinthSong = dto.BrowserEntry(path: 'root/Heron/Labyrinth.mp3', isDirectory: false);
    final fallInwardsSong = dto.BrowserEntry(path: 'root/Heron/Fall Inwards.mp3', isDirectory: false);
    cache.putDirectory('host', 'root/Heron', [labyrinthSong, fallInwardsSong]);
    final cachedContent = cache.flattenDirectory('host', 'root/Heron');
    assert(cachedContent != null);
    assert(listEquals(cachedContent, [
      'root/Heron/Fall Inwards.mp3',
      'root/Heron/Labyrinth.mp3',
    ]));
  });
}
