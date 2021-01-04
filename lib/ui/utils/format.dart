import 'package:polaris/shared/dto.dart';
import 'package:polaris/ui/strings.dart';

final _pathSeparatorRegExp = RegExp(r'[/\\]');

String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
  String hours = '$d.inHours';
  if (d.inHours > 0) {
    return '$hours:$twoDigitMinutes:$twoDigitSeconds';
  } else {
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}

List<String> splitPath(String path) {
  return path.split(_pathSeparatorRegExp).toList();
}

extension SongFormatting on Song {
  String formatTrackNumberAndTitle() {
    if (title == null) {
      return path.split(_pathSeparatorRegExp).last;
    }

    List<String> components = [];
    if (trackNumber != null) {
      components.add('$trackNumber');
    }
    components.add(title);
    return components.join('. ');
  }

  String formatArtist() {
    return artist ?? albumArtist ?? unknownArtist;
  }
}

extension DirectoryFormatting on Directory {
  String formatName() {
    return album ?? path.split(_pathSeparatorRegExp).last;
  }

  String formatArtist() {
    return artist ?? unknownArtist;
  }
}
