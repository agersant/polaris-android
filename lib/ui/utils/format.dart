import 'dart:math';
import 'package:polaris/core/client/api/v8_dto.dart';
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
  final value = ((bytes / pow(1024, suffixIndex)).toStringAsFixed(decimals));
  final suffix = suffixes[suffixIndex];
  return '$value $suffix';
}

extension BrowserEntryFormatting on BrowserEntry {
  String formatName() {
    final components = splitPath(path);
    return components.last;
  }
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

  String formatArtists() {
    if (artists.isNotEmpty) {
      return artists.join(', ');
    }
    if (albumArtists.isNotEmpty) {
      return albumArtists.join(', ');
    }
    return unknownArtist;
  }

  String formatArtistsAndDuration() {
    final artists = formatArtists();
    List<String> components = [artists];
    int? songDuration = duration;
    if (songDuration != null) {
      components.add(formatDuration(Duration(seconds: songDuration)));
    }
    return components.join(' · ');
  }
}

extension AlbumHeaderFormatting on AlbumHeader {
  String formatArtists() {
    return mainArtists.isNotEmpty ? mainArtists.join(', ') : unknownArtist;
  }
}
