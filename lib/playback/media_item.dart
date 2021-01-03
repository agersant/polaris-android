import 'package:audio_service/audio_service.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

extension IntoMediaItem on Song {
  MediaItem toMediaItem() {
    final Uri uri = getIt<API>().getAudioURI(path);
    assert(uri != null);
    return MediaItem(
      id: path, // TODO This is not unique enough (dupes in playlist)
      playable: true,
      album: album,
      title: title,
      artist: formatArtist(),
      duration: duration != null ? Duration(seconds: duration) : null,
      artUri: null, // TODO Add album art URL to proxy server
      // TODO Replace this with 'path'. Proxy HTTP server can handle credentials (and caching) for us.
      // https://github.com/ryanheise/just_audio/issues/172#issuecomment-685722410
      extras: {'uri': uri.toString()},
    );
  }
}
