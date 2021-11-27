import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/playback/playback_controls.dart';
import 'package:polaris/ui/playback/progress_state.dart';
import 'package:polaris/ui/playback/streaming_indicator.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';
import 'package:polaris/core/dto.dart';
import 'package:polaris/core/media_item.dart';

final getIt = GetIt.instance;

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

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
              onTap: getIt<PagesModel>().openPlayer,
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
                  Row(
                    children: [
                      const StreamingIndicator(),
                      Expanded(
                        child: Text(
                          song.formatTitle(),
                          style: Theme.of(context).textTheme.subtitle2?.copyWith(color: foregroundColor),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )
                    ],
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
            const PlaybackControls(),
          ],
        );
      },
    );

Widget _progressBar() => LayoutBuilder(
      builder: (context, size) {
        final player = getIt<AudioPlayer>();
        final Stream<ProgressState> progressStream = ProgressState.createStream(player);

        final Color backgroundColor = Theme.of(context).backgroundColor;
        final Color foregroundColor = Theme.of(context).colorScheme.primary;
        return Stack(
          children: [
            Container(color: backgroundColor),
            StreamBuilder<ProgressState>(
              stream: progressStream,
              builder: (context, snapshot) {
                double progress = 0.0;
                if (snapshot.hasData) {
                  final Duration? position = snapshot.data?.position;
                  final Duration? duration = snapshot.data?.duration;
                  if (position != null && duration != null && duration.inMilliseconds > 0) {
                    progress = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
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
