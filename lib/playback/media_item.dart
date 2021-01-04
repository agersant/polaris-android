import 'package:audio_service/audio_service.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

final String extraKeyPath = 'path';
final String extraKeyTrackNumber = 'trackNumber';
final String extraKeyDiscNumber = 'discNumber';
final String extraKeyArtist = 'artist';
final String extraKeyAlbumArtist = 'albumArtist';
final String extraKeyYear = 'year';
final String extraKeyArtwork = 'artwork';

extension MediaItemConversions on Song {
  MediaItem toMediaItem() {
    return MediaItem(
      id: path, // TODO This is not unique enough (dupes in playlist)
      playable: true,
      album: album,
      title: title,
      artist: formatArtist(),
      duration: duration != null ? Duration(seconds: duration) : null,
      artUri: null, // TODO Support (through proxy? real server? file URI?)
      extras: {
        extraKeyPath: path,
        extraKeyTrackNumber: trackNumber,
        extraKeyDiscNumber: discNumber,
        extraKeyArtist: artist,
        extraKeyAlbumArtist: albumArtist,
        extraKeyArtwork: artwork,
      },
    );
  }
}

extension DTOConversions on MediaItem {
  Song toSong() {
    return new Song()
      ..path = extras[extraKeyPath]
      ..trackNumber = extras[extraKeyTrackNumber]
      ..discNumber = extras[extraKeyDiscNumber]
      ..title = title
      ..artist = extras[extraKeyArtist]
      ..albumArtist = extras[extraKeyAlbumArtist]
      ..year = extras[extraKeyYear]
      ..album = album
      ..artwork = extras[extraKeyArtwork]
      ..duration = duration.inSeconds;
  }
}
