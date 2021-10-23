import 'package:audio_service/audio_service.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/ui/utils/format.dart';
import 'package:uuid/uuid.dart';

final String extraKeyPath = 'path';
final String extraKeyTrackNumber = 'trackNumber';
final String extraKeyDiscNumber = 'discNumber';
final String extraKeyArtist = 'artist';
final String extraKeyAlbumArtist = 'albumArtist';
final String extraKeyYear = 'year';
final String extraKeyArtwork = 'artwork';

extension MediaItemConversions on Song {
  MediaItem toMediaItem(Uuid uuid, polaris.API polarisAPI) {
    return MediaItem(
      id: uuid.v4(),
      playable: true,
      album: album ?? "",
      title: title ?? "",
      artist: formatArtist(),
      duration: duration != null ? Duration(seconds: duration!) : null,
      artUri: artwork != null ? polarisAPI.getImageURI(artwork!) : null,
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
    return new Song(path: extras?[extraKeyPath])
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
