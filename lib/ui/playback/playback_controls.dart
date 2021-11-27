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
    // TODO needs to update based on sequence stream too so skip arrows properly change color when songs are queued
    return StreamBuilder<PlayerState>(
      stream: getIt<AudioPlayer>().playerStateStream,
      builder: (context, snapshot) {
        bool playing = false;
        if (snapshot.hasData) {
          playing = snapshot.data!.playing && snapshot.data!.processingState != ProcessingState.completed;
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _previousButton(foregroundColor),
            if (playing) _pauseButton(foregroundColor) else _playButton(foregroundColor),
            _nextButton(foregroundColor),
          ],
        );
      },
    );
  }
}

IconButton _previousButton(Color color) => IconButton(
      icon: const Icon(Icons.skip_previous),
      onPressed: getIt<AudioPlayer>().hasPrevious ? getIt<AudioPlayer>().seekToPrevious : null,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.compact,
      color: color,
    );

IconButton _pauseButton(Color color) => IconButton(
      icon: const Icon(Icons.pause),
      onPressed: getIt<AudioPlayer>().pause,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.compact,
      color: color,
    );

IconButton _playButton(Color color) => IconButton(
      icon: const Icon(Icons.play_arrow),
      onPressed: getIt<AudioPlayer>().play,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.compact,
      color: color,
    );

IconButton _nextButton(Color color) => IconButton(
      icon: const Icon(Icons.skip_next),
      onPressed: getIt<AudioPlayer>().hasNext ? getIt<AudioPlayer>().seekToNext : null,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.compact,
      color: color,
    );
