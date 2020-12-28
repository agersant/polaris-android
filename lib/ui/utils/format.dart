import 'package:polaris/platform/dto.dart';
import 'package:polaris/ui/strings.dart';

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

extension Formatting on Song {
  String formatArtist() {
    return artist ?? albumArtist ?? unknownArtist;
  }
}
