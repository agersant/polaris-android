import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/ui/playback/media_state.dart';
import 'package:polaris/ui/playback/playback_controls.dart';
import 'package:polaris/ui/playback/streaming_indicator.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/thumbnail.dart';
import 'package:rxdart/rxdart.dart';

final getIt = GetIt.instance;

const exampleArt = 'Leviathan/OST - Anime/Howl\'s Moving Castle/2004 - Howl\'s Moving Castle Soundtrack/Folder.jpg';

class PlayerPage extends StatelessWidget {
  const PlayerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(nowPlaying),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline))], // TODO implement info button
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return _buildPortraitLayout(context);
          } else {
            return _buildLandscapeLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildArtwork(),
                  ),
                  _buildMainPanel(context),
                ],
              ),
            ),
          ),
          _buildUpNextWidget(context),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildArtwork(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Center(child: _buildMainPanel(context))),
                  _buildUpNextWidget(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    final audioPlayer = getIt<AudioPlayer>();
    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
        final dto.Song? song = mediaItem?.toSong();
        return Material(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: LargeThumbnail(song?.artwork),
          elevation: 2,
        );
      },
    );
  }

  Widget _buildMainPanel(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTrackDetails(),
        // TODO slider interactions
        _buildProgressBar(),
        const PlaybackControls(),
      ],
    );
  }

  Widget _buildTrackDetails() {
    final audioPlayer = getIt<AudioPlayer>();
    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
        final dto.Song? song = mediaItem?.toSong();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const StreamingIndicator(),
                    Flexible(
                      child: Text(
                        song?.formatTitle() ?? unknownSong,
                        style: Theme.of(context).textTheme.subtitle1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                song?.formatArtist() ?? unknownArtist,
                style:
                    Theme.of(context).textTheme.bodyText2!.copyWith(color: Theme.of(context).textTheme.caption!.color),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    final player = getIt<AudioPlayer>();
    final Stream<MediaState> mediaStateStream = Rx.combineLatest2<SequenceState?, Duration, MediaState>(
        player.sequenceStateStream,
        player.positionStream,
        (sequenceState, position) => MediaState(sequenceState, position));

    return StreamBuilder<MediaState>(
      stream: mediaStateStream,
      builder: (context, snapshot) {
        double? progress;
        Duration? position;
        Duration? duration;

        final int? positionMs = snapshot.data?.position.inMilliseconds;
        final MediaItem? mediaItem = snapshot.data?.sequenceState?.currentSource?.tag as MediaItem?;
        final int? durationMs = mediaItem?.duration?.inMilliseconds;
        if (positionMs != null && durationMs != null && durationMs > 0) {
          progress = (positionMs / durationMs).clamp(0.0, 1.0);
        }
        if (positionMs != null) {
          position = Duration(milliseconds: positionMs);
        }
        if (durationMs != null) {
          duration = Duration(milliseconds: durationMs);
        }

        return Column(
          children: [
            Slider(value: progress ?? 0, onChanged: (value) {}),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(position), style: Theme.of(context).textTheme.caption),
                  Text(formatDuration(duration), style: Theme.of(context).textTheme.caption),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpNextWidget(BuildContext context) {
    final player = getIt<AudioPlayer>();

    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream,
      builder: (context, snapshot) {
        final int? nextIndex = player.nextIndex;
        dto.Song? nextSong;
        if (nextIndex != null) {
          final audioSource = snapshot.data?.effectiveSequence[nextIndex];
          final mediaItem = audioSource?.tag as MediaItem?;
          nextSong = mediaItem?.toSong();
        }

        return OutlinedButton(
          onPressed: getIt<PagesModel>().openQueue,
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16),
                child: Text(upNext, style: Theme.of(context).textTheme.overline),
              ),
              if (nextSong == null)
                const ListTile(
                  leading: Icon(Icons.music_off, size: 40),
                  title: Text(upNextNothing),
                  subtitle: Text(upNextNothingSubtitle),
                  trailing: Icon(Icons.queue_music),
                ),
              if (nextSong != null)
                ListTile(
                  leading: ListThumbnail(nextSong.artwork),
                  title: Text(
                    nextSong.formatTitle(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    nextSong.formatArtist(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: const Icon(Icons.queue_music),
                ),
            ],
          ),
        );
      },
    );
  }
}
