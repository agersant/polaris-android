import 'dart:math';
import 'package:polaris/core/dto.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/utils.dart';

String formatDuration(Duration? d) {
  if (d == null) {
    return '-:--';
  }
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String oneDigitMinutes = d.inMinutes.remainder(60).toString();
  String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
  if (d.inHours > 0) {
    String hours = '${d.inHours}';
    return '$hours:$twoDigitMinutes:$twoDigitSeconds';
  } else {
    return '$oneDigitMinutes:$twoDigitSeconds';
  }
}

String formatBytes(int bytes, int decimals) {
  if (bytes <= 0) {
    return "0 B";
  }
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  final int suffixIndex = (log(bytes) / log(1024)).floor();
  return ((bytes / pow(1024, suffixIndex)).toStringAsFixed(decimals)) + ' ' + suffixes[suffixIndex];
}

extension SongFormatting on Song {
  String formatTitle() {
    if (title?.isEmpty ?? true) {
      final components = splitPath(path);
      return components.last;
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
    return album ?? splitPath(path).last;
  }

  String formatArtist() {
    return artist ?? unknownArtist;
  }
}
