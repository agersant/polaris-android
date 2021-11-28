import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/playback/playback_controls.dart';
import 'package:polaris/ui/playback/progress_state.dart';
import 'package:polaris/ui/playback/streaming_indicator.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';
import 'package:polaris/core/dto.dart';
import 'package:polaris/core/media_item.dart';

final getIt = GetIt.instance;

class MiniPlayer extends StatefulWidget {
  final bool collapse;

  const MiniPlayer({required this.collapse, Key? key}) : super(key: key);

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with TickerProviderStateMixin {
  static const int slideDurationMs = 120;
  static const int slideInDelayMs = 400;

  final audioPlayer = getIt<AudioPlayer>();
  late StreamSubscription stateSubscription;
  late final AnimationController _controller = AnimationController(vsync: this, value: 0);
  bool isVisible = false;
  dto.Song? _song;

  @override
  void initState() {
    super.initState();
    stateSubscription = audioPlayer.sequenceStateStream.listen((event) {
      final MediaItem? mediaItem = event?.currentSource?.tag as MediaItem?;
      if (mediaItem != null) {
        setState(() => _song = mediaItem.toSong());
      }
      _updateVisibility();
    });
  }

  @override
  void dispose() {
    super.dispose();
    stateSubscription.cancel();
    _controller.dispose();
  }

  @override
  void didUpdateWidget(MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateVisibility();
  }

  void _updateVisibility() {
    final bool newIsVisible = !widget.collapse && audioPlayer.sequenceState?.currentSource != null;
    if (newIsVisible == isVisible) {
      return;
    }
    final double height = newIsVisible ? 1 : 0;
    final int durationMs = slideDurationMs + (newIsVisible ? slideInDelayMs : 0);
    _controller.animateTo(height, duration: Duration(milliseconds: durationMs));
    isVisible = newIsVisible;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        final song = _song;
        if (song == null) {
          return Container();
        }
        return SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: _controller,
            curve: _getAnimationCurve(),
          ),
          axisAlignment: -1.0,
          child: SizedBox(
            height: 64,
            child: Material(
              elevation: 8,
              child: InkWell(
                onTap: _handleTap,
                child: playerContent(context, song),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap() {
    final pagesModel = getIt<PagesModel>();
    pagesModel.openPlayer();
    if (pagesModel.isQueueOpen) {
      pagesModel.closeQueue();
    }
  }

  Curve _getAnimationCurve() {
    if (!isVisible) {
      return Curves.fastOutSlowIn;
    }
    return const Interval(
      slideInDelayMs / (slideInDelayMs + slideDurationMs),
      1.0,
      curve: Curves.easeOutCubic,
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
