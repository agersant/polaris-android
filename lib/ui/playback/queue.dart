import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/ui/utils/animated_equalizer.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/thumbnail.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/media_item.dart';

final getIt = GetIt.instance;

class QueuePage extends StatelessWidget {
  const QueuePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AudioPlayer audioPlayer = getIt<AudioPlayer>();

    // TODO autoscroll to current song
    // TODO display number of songs and total duration

    // TODO there is a visual bug when re-ordering songs in a way that shifts the currently playing song.
    // It is caused by just_audio updating the sequenceState partially through the re-order operation

    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        Widget body;
        final isEmpty = snapshot.data?.sequence.isEmpty ?? true;
        if (isEmpty) {
          body = const ErrorMessage(queueEmpty);
        } else {
          body = ReorderableListView.builder(
            itemBuilder: (context, index) {
              final SequenceState sequenceState = snapshot.data!;
              final MediaItem mediaItem = sequenceState.sequence[index].tag as MediaItem;
              final bool isCurrent = mediaItem.id == (sequenceState.currentSource?.tag as MediaItem).id;
              onTap() => getIt<AudioPlayer>().seek(null, index: index);
              return _songWidget(context, mediaItem, isCurrent, onTap);
            },
            itemCount: snapshot.data?.sequence.length ?? 0,
            onReorder: (int oldIndex, int newIndex) {
              getIt<Playlist>().moveSong(oldIndex, newIndex);
            },
            physics: const BouncingScrollPhysics(),
          );
        }

        final clearAction = isEmpty ? null : _clearQueue;

        return Scaffold(
          appBar: AppBar(
            title: const Text(queueTitle),
            actions: [IconButton(onPressed: clearAction, icon: const Icon(Icons.delete))],
          ),
          body: body,
        );
      },
    );
  }

  void _clearQueue() {
    final playlist = getIt<Playlist>();
    playlist.clear();
  }
}

Widget _songWidget(BuildContext context, MediaItem mediaItem, bool isCurrent, Function() onTap) =>
    StreamBuilder<PlayerState>(
        key: Key(mediaItem.id),
        stream: getIt<AudioPlayer>().playerStateStream,
        builder: (context, snapshot) {
          final dto.Song song = mediaItem.toSong();
          final isPlaying = snapshot.data?.playing ?? false;
          final ProcessingState state = snapshot.data?.processingState ?? ProcessingState.idle;
          return Material(
            child: InkWell(
              onTap: onTap,
              child: ListTile(
                leading: ListThumbnail(song.artwork),
                title: Row(
                  children: [
                    if (isCurrent && state != ProcessingState.completed)
                      Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                          child: _currentSongIcon(context, isPlaying, state)),
                    Expanded(child: Text(song.formatTitle(), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                subtitle: Text(song.formatArtist(), overflow: TextOverflow.ellipsis),
                dense: true,
              ),
            ),
          );
        });

Widget _currentSongIcon(BuildContext context, bool isPlaying, ProcessingState state) {
  final Color color = Theme.of(context).colorScheme.primary;
  final bool isBuffering = state != ProcessingState.ready && state != ProcessingState.completed;

  if (isBuffering) {
    return Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: SizedBox(
            width: 16,
            height: 10,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            )));
  } else {
    return AnimatedEqualizer(color, const Size(16, 12), isPlaying);
  }
}
