import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

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
        _buildTrackDetails(context),
        // TODO real slider progress
        // TODO slider interactions
        Slider(value: .25, onChanged: (value) {}),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TODO real timing information
              Text('0:39', style: Theme.of(context).textTheme.caption),
              Text('1:44', style: Theme.of(context).textTheme.caption),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO button interactions
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.skip_previous),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.pause),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.skip_next),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackDetails(BuildContext context) {
    final audioPlayer = getIt<AudioPlayer>();
    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
        final dto.Song? song = mediaItem?.toSong();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(song?.formatTitle() ?? unknownSong, style: Theme.of(context).textTheme.subtitle1),
            ),
            Text(
              song?.formatArtist() ?? unknownArtist,
              style: Theme.of(context).textTheme.bodyText2!.copyWith(color: Theme.of(context).textTheme.caption!.color),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpNextWidget(BuildContext context) {
    return OutlinedButton(
      onPressed: getIt<PagesModel>().openQueue,
      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16),
            child: Text('Up Next', style: Theme.of(context).textTheme.overline),
          ),
          const ListTile(
            // TODO real-queue information
            leading: ListThumbnail(exampleArt),
            title: Text('After the Rain'),
            subtitle: Text('Joe Hisaishi'),
            trailing: Icon(Icons.queue_music),
          ),
        ],
      ),
    );
  }
}
