import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';

final getIt = GetIt.instance;

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final foregroundColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _previousButton(foregroundColor),
        _playPauseButton(foregroundColor),
        _nextButton(foregroundColor),
      ],
    );
  }
}

Widget _previousButton(Color color) => StreamBuilder<SequenceState?>(
      stream: getIt<AudioPlayer>().sequenceStateStream,
      builder: (context, snapshot) {
        return _button(
          Icons.skip_previous,
          getIt<AudioPlayer>().hasPrevious ? getIt<AudioPlayer>().seekToPrevious : null,
          color,
        );
      },
    );

Widget _nextButton(Color color) => StreamBuilder<SequenceState?>(
      stream: getIt<AudioPlayer>().sequenceStateStream,
      builder: (context, snapshot) {
        return _button(
          Icons.skip_next,
          getIt<AudioPlayer>().hasNext ? getIt<AudioPlayer>().seekToNext : null,
          color,
        );
      },
    );

Widget _playPauseButton(Color color) => StreamBuilder<PlayerState>(
      stream: getIt<AudioPlayer>().playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing == true && snapshot.data?.processingState != ProcessingState.completed;
        if (isPlaying) {
          return _pauseButton(color);
        } else {
          return _playButton(color);
        }
      },
    );

Widget _pauseButton(Color color) => _button(Icons.pause, getIt<AudioPlayer>().pause, color);

Widget _playButton(Color color) => _button(Icons.play_arrow, getIt<AudioPlayer>().play, color);

IconButton _button(IconData icon, Future<void> Function()? onPressed, Color color) => IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.compact,
      color: color,
    );
