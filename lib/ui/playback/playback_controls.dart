import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';

final getIt = GetIt.instance;

class PlaybackControls extends StatelessWidget {
  final bool mini;

  const PlaybackControls({Key? key, this.mini = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final foregroundColor = Theme.of(context).colorScheme.onSurface;
    final activeColor = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!mini) _repeatButton(foregroundColor, activeColor, 24.0),
        Row(children: [
          _previousButton(foregroundColor, mini ? 24.0 : 40.0),
          _playPauseButton(foregroundColor, mini ? 24.0 : 40.0),
          _nextButton(foregroundColor, mini ? 24.0 : 40.0),
        ]),
        if (!mini) _shuffleButton(foregroundColor, activeColor, 24.0),
      ],
    );
  }
}

Widget _repeatButton(Color foregroundColor, Color activeColor, double size) => StreamBuilder<LoopMode?>(
      stream: getIt<AudioPlayer>().loopModeStream,
      builder: (context, snapshot) {
        final loopMode = getIt<AudioPlayer>().loopMode;
        final isLooping = loopMode != LoopMode.off;
        return _button(
          isLooping ? Icons.repeat_on_rounded : Icons.repeat_rounded,
          () async {
            getIt<AudioPlayer>().setLoopMode(isLooping ? LoopMode.off : LoopMode.all);
          },
          isLooping ? activeColor : foregroundColor,
          size,
        );
      },
    );

Widget _shuffleButton(Color foregroundColor, Color activeColor, double size) => StreamBuilder<bool?>(
      stream: getIt<AudioPlayer>().shuffleModeEnabledStream,
      builder: (context, snapshot) {
        final shuffleEnabled = getIt<AudioPlayer>().shuffleModeEnabled;
        return _button(
          shuffleEnabled ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
          () async {
            getIt<AudioPlayer>().setShuffleModeEnabled(!shuffleEnabled);
          },
          shuffleEnabled ? activeColor : foregroundColor,
          size,
        );
      },
    );

Widget _previousButton(Color color, double size) => StreamBuilder<SequenceState?>(
      stream: getIt<AudioPlayer>().sequenceStateStream,
      builder: (context, snapshot) {
        return _button(Icons.skip_previous_rounded,
            getIt<AudioPlayer>().hasPrevious ? getIt<AudioPlayer>().seekToPrevious : null, color, size);
      },
    );

Widget _nextButton(Color color, double size) => StreamBuilder<SequenceState?>(
      stream: getIt<AudioPlayer>().sequenceStateStream,
      builder: (context, snapshot) {
        return _button(
          Icons.skip_next_rounded,
          getIt<AudioPlayer>().hasNext ? getIt<AudioPlayer>().seekToNext : null,
          color,
          size,
        );
      },
    );

Widget _playPauseButton(Color color, double size) => StreamBuilder<PlayerState>(
      stream: getIt<AudioPlayer>().playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing == true && snapshot.data?.processingState != ProcessingState.completed;
        if (isPlaying) {
          return _pauseButton(color, size);
        } else {
          return _playButton(color, size);
        }
      },
    );

Widget _pauseButton(Color color, double size) => _button(Icons.pause_rounded, getIt<AudioPlayer>().pause, color, size);

Widget _playButton(Color color, double size) =>
    _button(Icons.play_arrow_rounded, getIt<AudioPlayer>().play, color, size);

IconButton _button(IconData icon, Future<void> Function()? onPressed, Color color, double size) => IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: size,
      color: color,
    );
