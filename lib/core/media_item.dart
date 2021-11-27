import 'package:audio_service/audio_service.dart';
import 'package:polaris/core/dto.dart';
import 'package:polaris/ui/utils/format.dart';

const String extraKeyPath = 'path';
const String extraKeyTrackNumber = 'trackNumber';
const String extraKeyDiscNumber = 'discNumber';
const String extraKeyArtist = 'artist';
const String extraKeyAlbumArtist = 'albumArtist';
const String extraKeyYear = 'year';
const String extraKeyArtwork = 'artwork';

extension MediaItemConversions on Song {
  MediaItem toMediaItem(String id, Uri? artworkUri) {
    return MediaItem(
      id: id,
      playable: true,
      album: album ?? "",
      title: title ?? "",
      artist: formatArtist(),
      duration: duration != null ? Duration(seconds: duration!) : null,
      artUri: artworkUri,
      extras: <String, dynamic>{
        extraKeyPath: path,
        extraKeyTrackNumber: trackNumber,
        extraKeyDiscNumber: discNumber,
        extraKeyArtist: artist,
        extraKeyAlbumArtist: albumArtist,
        extraKeyYear: year,
        extraKeyArtwork: artwork,
      },
    );
  }
}

extension DTOConversions on MediaItem {
  Song toSong() {
    return Song(path: extras?[extraKeyPath])
      ..trackNumber = extras?[extraKeyTrackNumber]
      ..discNumber = extras?[extraKeyDiscNumber]
      ..title = title
      ..artist = extras?[extraKeyArtist]
      ..albumArtist = extras?[extraKeyAlbumArtist]
      ..year = extras?[extraKeyYear]
      ..album = album
      ..artwork = extras?[extraKeyArtwork]
      ..duration = duration?.inSeconds;
  }
}
