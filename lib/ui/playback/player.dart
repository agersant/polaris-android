import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart' hide Placeholder;
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/audio_handler.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/ui/playback/playback_controls.dart';
import 'package:polaris/ui/playback/progress_state.dart';
import 'package:polaris/ui/playback/seekbar.dart';
import 'package:polaris/ui/playback/streaming_indicator.dart';
import 'package:polaris/ui/utils/artist_links.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/placeholder.dart';
import 'package:polaris/ui/utils/song_info.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

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
        actions: [_buildInfoButton(context)],
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

  Widget _buildInfoButton(BuildContext context) {
    final audioHandler = getIt<PolarisAudioHandler>();
    return StreamBuilder<dto.Song?>(
        stream: audioHandler.currentSong,
        builder: (context, snapshot) {
          final song = snapshot.data;
          return IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: song == null ? null : () => SongInfoDialog.openInfoDialog(context, song),
          );
        });
  }

  Widget _buildArtwork() {
    final audioHandler = getIt<PolarisAudioHandler>();
    final pagesModel = getIt<PagesModel>();
    final connectionManager = getIt<connection.Manager>();

    return StreamBuilder<dto.Song?>(
      stream: audioHandler.currentSong,
      builder: (context, snapshot) {
        final dto.Song? song = snapshot.data;
        final albumHeader = song?.toAlbumHeader();
        return GestureDetector(
          onTap: () {
            if (albumHeader != null && (connectionManager.apiVersion ?? 0) >= 8) {
              pagesModel.openAlbumPage(albumHeader);
            }
          },
          child: Material(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            elevation: 2,
            child: LargeThumbnail(song?.artwork),
          ),
        );
      },
    );
  }

  Widget _buildMainPanel(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildTrackDetails(),
        _buildProgressBar(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: PlaybackControls(),
        ),
      ],
    );
  }

  Widget _buildTrackDetails() {
    final audioHandler = getIt<PolarisAudioHandler>();

    return StreamBuilder<dto.Song?>(
      stream: audioHandler.currentSong,
      builder: (context, snapshot) {
        final dto.Song? song = snapshot.data;

        final titleText = Text(
          song?.formatTitle() ?? unknownSong,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          softWrap: false,
        );

        final artists = (song?.artists.isEmpty == false ? song?.artists : song?.albumArtists) ?? [];

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
                    Flexible(child: titleText),
                  ],
                ),
              ),
              ArtistLinks(artists),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    final player = getIt<AudioPlayer>();
    final Stream<ProgressState> progressStream = ProgressState.createStream(player);

    return StreamBuilder<ProgressState>(
      stream: progressStream,
      builder: (context, snapshot) {
        final Duration? position = snapshot.data?.position;
        final Duration? duration = snapshot.data?.duration;
        return Column(
          children: [
            SeekBar(
              duration: duration ?? Duration.zero,
              position: position ?? Duration.zero,
              // TODO More often than not, this restarts playback from the beginning, while
              // still moving the current position forward.
              // Seems to happen more reliably on real device than emulator, and when song
              // isn't streaming from disk.
              // May or may not coincide with the audioplayer's durationStream not having
              // a value to report (and the displayed duration being from the dto.Song).
              onChangeEnd: player.seek,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(position), style: Theme.of(context).textTheme.bodySmall),
                  Text(formatDuration(duration), style: Theme.of(context).textTheme.bodySmall),
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
    final collectionCache = getIt<CollectionCache>();

    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream,
      builder: (context, snapshot) {
        final int? nextIndex = player.nextIndex;
        String? songPath;
        if (nextIndex != null) {
          songPath = (snapshot.data?.sequence[nextIndex].tag as MediaItem?)?.getSongPath();
        }
        return StreamBuilder<()>(
            stream: collectionCache.onSongsIngested,
            builder: (context, _) {
              dto.Song? nextSong;
              final host = getIt.get<connection.Manager>().url;
              if (host != null && songPath != null) {
                nextSong = collectionCache.getSong(host, songPath);
              }
              return OutlinedButton(
                onPressed: getIt<PagesModel>().openQueue,
                style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, left: 16),
                      child: Text(upNext, style: Theme.of(context).textTheme.labelSmall),
                    ),
                    songPath == null
                        ? const ListTile(
                            leading: Icon(Icons.music_off, size: 40),
                            title: Text(upNextNothing),
                            subtitle: Text(upNextNothingSubtitle),
                            trailing: Icon(Icons.queue_music),
                          )
                        : ListTile(
                            leading: ListThumbnail(nextSong?.artwork),
                            title: nextSong == null
                                ? const Placeholder(width: 80, height: 8)
                                : Text(
                                    nextSong.formatTitle(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                            subtitle: nextSong == null
                                ? const Placeholder(width: 80, height: 8)
                                : Text(
                                    nextSong.formatArtists(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                            trailing: const Icon(Icons.queue_music),
                          ),
                  ],
                ),
              );
            });
      },
    );
  }
}
