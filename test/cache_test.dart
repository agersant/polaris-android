import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:polaris/core/cache/media.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  test('Missing image returns null', () async {
    final manager = await MediaCache.create();
    expect(await manager.getImage('polaris.org', 'some image', ArtworkSize.small), isNull);
  });

  test('Save and read image', () async {
    final manager = await MediaCache.create();

    final imageData = Uint8List.fromList(const <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, //
      0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, //
      0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, //
      0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, //
      0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
    ]);

    const host = 'http://www.polaris.org';
    const path = 'heron/aegeus/folder.png';
    await manager.putImage(host, path, ArtworkSize.tiny, imageData);

    final File? cacheFile = await manager.getImage(host, path, ArtworkSize.tiny);
    if (cacheFile == null) {
      throw "Image not found in cache";
    }
    final Uint8List cacheFileContent = await cacheFile.readAsBytes();
    expect(cacheFileContent.buffer.asUint8List(), equals(imageData));
  });

  test('Can fallback to other image size', () async {
    final manager = await MediaCache.create();

    final imageData = Uint8List.fromList(const <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, //
      0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, //
      0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, //
      0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, //
      0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
    ]);

    const host = 'http://www.polaris.org';
    const path = 'heron/aegeus/folder.png';
    await manager.putImage(host, path, ArtworkSize.tiny, imageData);

    final File? smallFile = await manager.getImage(host, path, ArtworkSize.small);
    assert(smallFile == null);

    final File? fallbackFile = await manager.getImageAnySize(host, path);
    if (fallbackFile == null) {
      throw "Image not found in cache";
    }
    final Uint8List cacheFileContent = await fallbackFile.readAsBytes();
    expect(cacheFileContent.buffer.asUint8List(), equals(imageData));
  });

  test('Serialize LRU', () async {
    final lru = LRU();
    lru.upsert('some-path');
    expect(lru.data['some-path'], isNotNull);
    final lastUsed = lru.data['some-path']!;
    final lruFromDisk = LRU.fromBytes(lru.toBytes());
    expect(lruFromDisk.data['some-path'], isNotNull);
    expect(lruFromDisk.data['some-path'], equals(lastUsed));
  });
}

const String kTemporaryPath = 'temporaryPath';
const String kApplicationSupportPath = 'applicationSupportPath';
const String kDownloadsPath = 'downloadsPath';
const String kLibraryPath = 'libraryPath';
const String kApplicationDocumentsPath = 'applicationDocumentsPath';
const String kExternalCachePath = 'externalCachePath';
const String kExternalStoragePath = 'externalStoragePath';

class FakePathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return kTemporaryPath;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return kApplicationSupportPath;
  }

  @override
  Future<String?> getLibraryPath() async {
    return kLibraryPath;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return kApplicationDocumentsPath;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return kExternalStoragePath;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return <String>[kExternalCachePath];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return <String>[kExternalStoragePath];
  }

  @override
  Future<String?> getDownloadsPath() async {
    return kDownloadsPath;
  }
}
