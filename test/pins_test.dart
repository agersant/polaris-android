import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/dto.dart' as dto;

void main() {
  test('Can add/remove song', () async {
    final pin.Manager pinManager = pin.Manager(pin.Pins());

    final dto.Song song = dto.Song(path: 'root/Heron/Aegeus/Labyrinth.mp3');
    pinManager.pin('host', dto.CollectionFile(Left(song)));
    assert(pinManager.getSongs('host') != null);
    assert(pinManager.getSongs('host')!.isNotEmpty);
    assert(pinManager.getSongs('host')!.first.path == 'root/Heron/Aegeus/Labyrinth.mp3');

    pinManager.unpin('host', dto.CollectionFile(Left(song)));
    assert(pinManager.getSongs('host') != null);
    assert(pinManager.getSongs('host')!.isEmpty);
  });

  test('Can add/remove directory', () async {
    final pin.Manager pinManager = pin.Manager(pin.Pins());

    final dto.Directory directory = dto.Directory(path: 'root/Heron/Aegeus');
    pinManager.pin('host', dto.CollectionFile(Right(directory)));
    assert(pinManager.getDirectories('host') != null);
    assert(pinManager.getDirectories('host')!.isNotEmpty);
    assert(pinManager.getDirectories('host')!.first.path == 'root/Heron/Aegeus');

    pinManager.unpin('host', dto.CollectionFile(Right(directory)));
    assert(pinManager.getDirectories('host') != null);
    assert(pinManager.getDirectories('host')!.isEmpty);
  });

  test('Can serialize pins list to json', () async {
    final pins = pin.Pins();

    final dto.Song song = dto.Song(path: 'root/Heron/Aegeus/Labyrinth.mp3');
    pins.add('host', dto.CollectionFile(Left(song)));

    final dto.Directory directory = dto.Directory(path: 'root/Heron/Eons');
    pins.add('host', dto.CollectionFile(Right(directory)));

    final pin.Pins deserialized = pin.Pins.fromJson(pins.toJson());
    assert(deserialized.contains('host', dto.CollectionFile(Left(song))));
    assert(deserialized.contains('host', dto.CollectionFile(Right(directory))));
  });

  test('Can serialize pins list to bytes', () async {
    final pins = pin.Pins();

    final dto.Song song = dto.Song(path: 'root/Heron/Aegeus/Labyrinth.mp3');
    pins.add('host', dto.CollectionFile(Left(song)));

    final dto.Directory directory = dto.Directory(path: 'root/Heron/Eons');
    pins.add('host', dto.CollectionFile(Right(directory)));

    final pin.Pins deserialized = pin.Pins.fromBytes(pins.toBytes());
    assert(deserialized.contains('host', dto.CollectionFile(Left(song))));
    assert(deserialized.contains('host', dto.CollectionFile(Right(directory))));
  });
}