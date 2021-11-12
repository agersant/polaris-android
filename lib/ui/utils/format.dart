import 'package:polaris/core/dto.dart';
import 'package:polaris/ui/strings.dart';

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
    if (title?.isEmpty ?? true) {
      return path.split(_pathSeparatorRegExp).last;
    }
    return title!;
  }

  String formatTrackNumberAndTitle() {
    if (title?.isEmpty ?? true) {
      return formatTitle();
    }

    List<String> components = [];
    if (trackNumber != null) {
      components.add('$trackNumber');
    }
    components.add(title!);
    return components.join('. ');
  }

  String formatArtist() {
    return artist ?? albumArtist ?? unknownArtist;
  }

  String formatArtistAndDuration() {
    final artist = formatArtist();
    List<String> components = [artist];
    int? songDuration = duration;
    if (songDuration != null) {
      components.add(formatDuration(Duration(seconds: songDuration)));
    }
    return components.join(' · ');
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
