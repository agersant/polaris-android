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
const String extraKeyLyricist = 'lyricist';
const String extraKeyComposer = 'composer';
const String extraKeyGenre = 'genre';
const String extraKeyLabel = 'label';

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
        extraKeyTrackNumber: trackNumber,
        extraKeyDiscNumber: discNumber,
        extraKeyArtist: artists,
        extraKeyAlbumArtist: albumArtists,
        extraKeyYear: year,
        extraKeyArtwork: artwork,
        extraKeyLyricist: lyricists,
        extraKeyComposer: composers,
        extraKeyGenre: genres,
        extraKeyLabel: labels,
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
      ..artists = extras?[extraKeyArtist]
      ..albumArtists = extras?[extraKeyAlbumArtist]
      ..year = extras?[extraKeyYear]
      ..album = album
      ..artwork = extras?[extraKeyArtwork]
      ..duration = duration?.inSeconds
      ..lyricists = extras?[extraKeyLyricist]
      ..composers = extras?[extraKeyComposer]
      ..genres = extras?[extraKeyGenre]
      ..labels = extras?[extraKeyLabel];
  }
}
