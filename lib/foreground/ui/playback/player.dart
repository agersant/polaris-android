import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/main.dart';
import 'package:polaris/foreground/ui/playback/queue.dart';
import 'package:polaris/foreground/ui/utils/thumbnail.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/media_item.dart';
import 'package:rxdart/rxdart.dart';

final getIt = GetIt.instance;

class MediaState {
  final MediaItem mediaItem;
  final Duration position;
  MediaState(this.mediaItem, this.position);
}

Stream<MediaState> get _mediaStateStream => Rx.combineLatest2<MediaItem, Duration, MediaState>(
    AudioService.currentMediaItemStream,
    AudioService.positionStream,
    (mediaItem, position) => MediaState(mediaItem, position));

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem>(
      stream: AudioService.currentMediaItemStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(); // TODO animate the whole thing out when no data
        }
        return SizedBox(
          height: 64,
          child: Material(
            elevation: 8,
            child: InkWell(
              onTap: () {
                globalNavigatorKey.currentState.push(
                  // TODO prevent opening multiple instances
                  MaterialPageRoute(builder: (context) => QueuePage()),
                );
              },
              child: playerContent(context, snapshot.data.toSong()),
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
                    song.title,
                    style: Theme.of(context).textTheme.subtitle2.copyWith(color: foregroundColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    song.artist,
                    style: Theme.of(context).textTheme.caption.copyWith(color: foregroundColor.withOpacity(0.75)),
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

Widget _controls(Color foregroundColor) => StreamBuilder<PlaybackState>(
      stream: AudioService.playbackStateStream,
      builder: (context, snapshot) {
        bool playing = false;
        if (snapshot.hasData) {
          playing = snapshot.data.playing && snapshot.data.processingState != AudioProcessingState.completed;
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO add previous button
            if (playing) _pauseButton(foregroundColor) else _playButton(foregroundColor),
            _nextButton(foregroundColor), // TODO grey out when cannot skip next
          ],
        );
      },
    );

IconButton _pauseButton(Color color) => IconButton(
      icon: Icon(Icons.pause),
      onPressed: AudioService.pause,
      iconSize: 24.0,
      color: color,
    );

IconButton _playButton(Color color) => IconButton(
      icon: Icon(Icons.play_arrow),
      onPressed: AudioService.play,
      iconSize: 24.0,
      color: color,
    );

IconButton _nextButton(Color color) => IconButton(
      icon: Icon(Icons.skip_next),
      onPressed: AudioService.skipToNext,
      iconSize: 24.0,
      color: color,
    );

Widget _progressBar() => LayoutBuilder(
      builder: (context, size) {
        final Color backgroundColor = Theme.of(context).backgroundColor;
        final Color foregroundColor = Theme.of(context).accentColor;
        return Stack(
          children: [
            Container(color: backgroundColor),
            StreamBuilder<MediaState>(
              stream: _mediaStateStream,
              builder: (context, snapshot) {
                double progress = 0.0;
                if (snapshot.hasData) {
                  final int position = snapshot.data.position?.inMilliseconds;
                  final int duration = snapshot.data.mediaItem?.duration?.inMilliseconds;
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
