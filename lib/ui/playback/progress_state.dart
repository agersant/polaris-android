import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

class ProgressState {
  final Duration position;
  final Duration? duration;

  ProgressState(this.position, this.duration);

  static Stream<ProgressState> createStream(AudioPlayer player) {
    return Rx.combineLatest3<Duration, Duration?, SequenceState?, ProgressState>(
      player.positionStream,
      player.durationStream,
      player.sequenceStateStream,
      (position, duration, sequenceState) {
        final MediaItem? mediaItem = sequenceState?.currentSource?.tag as MediaItem?;
        duration ??= mediaItem?.duration;
        return ProgressState(position, duration);
      },
    );
  }
}
