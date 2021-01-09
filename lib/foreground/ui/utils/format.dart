import 'package:polaris/shared/dto.dart';
import 'package:polaris/foreground/ui/strings.dart';

final _pathSeparatorRegExp = RegExp(r'[/\\]');

String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
  if (d.inHours > 0) {
    String hours = '${d.inHours}';
    return '$hours:$twoDigitMinutes:$twoDigitSeconds';
  } else {
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}

List<String> splitPath(String path) {
  return path.split(_pathSeparatorRegExp).toList();
}

extension SongFormatting on Song {
  String formatTitle() {
    // TODO empty titles strings for Switched-on Lotus
    return title ?? path.split(_pathSeparatorRegExp).last;
  }

  String formatTrackNumberAndTitle() {
    if (title == null) {
      return formatTitle();
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
