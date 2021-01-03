import 'package:audio_service/audio_service.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

extension IntoMediaItem on Song {
  MediaItem toMediaItem() {
    return MediaItem(
      id: path, // TODO This is not unique enough (dupes in playlist)
      playable: true,
      album: album,
      title: title,
      artist: formatArtist(),
      duration: duration != null ? Duration(seconds: duration) : null,
      artUri: null, // TODO Support (through proxy? real server? file URI?)
      extras: {'path': path},
    );
  }
}
