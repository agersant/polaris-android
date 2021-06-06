import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/background/cache.dart' as cache;

void main() {
  test('Missing image returns null', () async {
    final manager = await cache.Manager.create();
    assert(await manager.getImage('polaris.org', 'some image') == null);
  });

  test('Save and read image', () async {
    final manager = await cache.Manager.create();

    final imageData = Uint8List.fromList(const <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, //
      0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, //
      0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, //
      0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, //
      0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
    ]);

    final host = 'http://www.polaris.org';
    final path = 'heron/aegeus/folder.png';
    await manager.putImage(host, path, imageData);

    final File? cacheFile = await manager.getImage(host, path);
    if (cacheFile == null) {
      throw "Image not found in cache";
    }
    final Uint8List cacheFileContent = await cacheFile.readAsBytes();
    expect(cacheFileContent.buffer.asUint8List(), equals(imageData));
  });
}
