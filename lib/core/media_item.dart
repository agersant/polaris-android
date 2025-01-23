import 'package:audio_service/audio_service.dart';
import 'package:polaris/core/client/api/v8_dto.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/utils.dart';

const String extraKeyPath = 'path';

extension MediaItemConversions on Song {
  MediaItem toMediaItem(String id, Uri? artworkUri) {
    return MediaItem(
      id: id,
      playable: true,
      album: album ?? "",
      title: title ?? "",
      artist: formatArtists(),
      duration: duration != null ? Duration(seconds: duration!) : null,
      artUri: artworkUri,
      extras: <String, dynamic>{
        extraKeyPath: path,
      },
    );
  }
}

MediaItem makeMediaItem(String id, String path) {
  return MediaItem(
    id: id,
    playable: true,
    title: basename(path),
    extras: <String, dynamic>{
      extraKeyPath: path,
    },
  );
}

extension PolarisMediaItem on MediaItem {
  String getSongPath() {
    return extras![extraKeyPath];
  }
}
