import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/ui/playback/queue_model.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';
import 'package:polaris/core/dto.dart';
import 'package:polaris/core/media_item.dart';
import 'package:rxdart/rxdart.dart';

final getIt = GetIt.instance;

class MediaState {
  final SequenceState? sequenceState;
  final Duration position;
  MediaState(this.sequenceState, this.position);
}

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final audioPlayer = getIt<AudioPlayer>();

    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        final MediaItem? mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
        if (mediaItem == null) {
          return Container(); // TODO animate the whole thing in/out
        }
        return SizedBox(
          height: 64,
          child: Material(
            elevation: 8,
            child: InkWell(
              onTap: () {
                QueueModel queueModel = getIt<QueueModel>();
                queueModel.openQueue();
              },
              child: playerContent(context, mediaItem.toSong()),
            ),
          ),
        );
      },
    );
  }
}

Widget playerContent(BuildContext context, Song song) {
  final theme = Theme.of(context);
  final backgroundColor = theme.colorScheme.surface;
  final foregroundColor = theme.colorScheme.onSurface;
  return Container(
      color: backgroundColor,
      child: Stack(children: [
        _trackDetails(song, foregroundColor),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 3,
          child: _progressBar(),
        ),
      ]));
}

Widget _trackDetails(Song song, Color foregroundColor) => LayoutBuilder(
      builder: (context, size) {
        return Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ListThumbnail(song.artwork),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song.formatTitle(),
                    style: Theme.of(context).textTheme.subtitle2?.copyWith(color: foregroundColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    song.formatArtist(),
                    style: Theme.of(context).textTheme.caption?.copyWith(color: foregroundColor.withOpacity(0.75)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            _controls(foregroundColor),
            // TODO Buffering indicator
          ],
        );
      },
    );

Widget _controls(Color foregroundColor) => StreamBuilder<PlayerState>(
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

IconButton _previousButton(Color color) => IconButton(
      icon: Icon(Icons.skip_previous),
      onPressed: getIt<AudioPlayer>().hasPrevious ? getIt<AudioPlayer>().seekToPrevious : null,
      iconSize: 24.0,
      color: color,
    );

IconButton _pauseButton(Color color) => IconButton(
      icon: Icon(Icons.pause),
      onPressed: getIt<AudioPlayer>().pause,
      iconSize: 24.0,
      color: color,
    );

IconButton _playButton(Color color) => IconButton(
      icon: Icon(Icons.play_arrow),
      onPressed: getIt<AudioPlayer>().play,
      iconSize: 24.0,
      color: color,
    );

IconButton _nextButton(Color color) => IconButton(
      icon: Icon(Icons.skip_next),
      onPressed: getIt<AudioPlayer>().hasNext ? getIt<AudioPlayer>().seekToNext : null,
      iconSize: 24.0,
      color: color,
    );

Widget _progressBar() => LayoutBuilder(
      builder: (context, size) {
        final player = getIt<AudioPlayer>();
        final Stream<MediaState> mediaStateStream = Rx.combineLatest2<SequenceState?, Duration, MediaState>(
            player.sequenceStateStream,
            player.positionStream,
            (sequenceState, position) => MediaState(sequenceState, position));

        final Color backgroundColor = Theme.of(context).backgroundColor;
        final Color foregroundColor = Theme.of(context).accentColor;
        return Stack(
          children: [
            Container(color: backgroundColor),
            StreamBuilder<MediaState>(
              stream: mediaStateStream,
              builder: (context, snapshot) {
                double progress = 0.0;
                if (snapshot.hasData) {
                  final int? position = snapshot.data!.position.inMilliseconds;
                  final MediaItem? mediaItem = snapshot.data!.sequenceState?.currentSource?.tag as MediaItem;
                  final int? duration = mediaItem?.duration?.inMilliseconds;
                  if (position != null && duration != null && duration > 0) {
                    progress = (position / duration).clamp(0.0, 1.0);
                  }
                }
                return SizedBox(
                  width: progress * size.maxWidth,
                  child: Container(color: foregroundColor),
                );
              },
            ),
          ],
        );
      },
    );
