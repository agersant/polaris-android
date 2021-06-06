import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/background/entrypoint.dart';
import 'package:polaris/foreground/ui/utils/animated_equalizer.dart';
import 'package:polaris/foreground/ui/utils/thumbnail.dart';
import 'package:polaris/shared/dto.dart' as dto;
import 'package:polaris/foreground/ui/utils/format.dart';
import 'package:polaris/foreground/ui/strings.dart';
import 'package:polaris/shared/media_item.dart';
import 'package:rxdart/rxdart.dart';

final getIt = GetIt.instance;

class QueueState {
  final List<MediaItem>? queue;
  MediaItem? mediaItem;
  QueueState(this.queue, this.mediaItem);
}

Stream<QueueState> get _queueStateStream => Rx.combineLatest2<List<MediaItem>?, MediaItem?, QueueState>(
    AudioService.queueStream, AudioService.currentMediaItemStream, (queue, mediaItem) => QueueState(queue, mediaItem));

class QueuePage extends StatefulWidget {
  @override
  _QueuePageState createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> with SingleTickerProviderStateMixin {
  // Keep a local copy of the queue so we can re-order without waiting for communication with background service
  // Directly reflecting AudioService.queueStream in the UI leads to flicker when finishing a drag and drop
  late QueueState localState;
  late StreamSubscription<QueueState> stateSubscription;

  @override
  void initState() {
    super.initState();
    stateSubscription = _queueStateStream.listen((newState) {
      setState(() {
        localState = newState;
      });
    });
    localState = QueueState(AudioService.queue, AudioService.currentMediaItem);
    // TODO autoscroll to current song?
  }

  @override
  void dispose() {
    stateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(queueTitle),
      ),
      body: StreamBuilder<PlaybackState>(
          // TODO number of songs and duration
          stream: AudioService.playbackStateStream,
          builder: (context, snapshot) {
            List<MediaItem>? queue = localState.queue;
            if (queue == null) {
              return Container();
            } else {
              return ReorderableListView(
                // TODO bounce physics (https://github.com/flutter/flutter/issues/66080)
                children: queue.map((mediaItem) {
                  final bool isCurrent = mediaItem.id == localState.mediaItem?.id;
                  final bool isPlaying = snapshot.data?.playing ?? false;
                  final onTap = () {
                    localState.mediaItem = mediaItem;
                    setState(() {});
                    AudioService.skipToQueueItem(mediaItem.id);
                  };
                  return _songWidget(context, mediaItem, isCurrent, isPlaying, onTap);
                }).toList(),
                onReorder: (int oldIndex, int newIndex) {
                  final int insertIndex = oldIndex > newIndex ? newIndex : newIndex - 1;
                  queue.insert(insertIndex, queue.removeAt(oldIndex));
                  setState(() {});
                  AudioService.customAction(customActionMoveQueueItem, [oldIndex, newIndex]);
                },
              );
            }
          }),
    );
  }
}

Widget _songWidget(BuildContext context, MediaItem mediaItem, bool isCurrent, bool isPlaying, Function() onTap) {
  final dto.Song song = mediaItem.toSong();
  final Color eqColor = Theme.of(context).colorScheme.primary;

  return Material(
    key: Key(mediaItem.id),
    child: InkWell(
      onTap: onTap,
      child: ListTile(
        leading: ListThumbnail(song.artwork),
        title: Row(
          children: [
            if (isCurrent)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                // TODO buffering indicator?
                child: AnimatedEqualizer(eqColor, Size(16, 12), isPlaying),
              ),
            Text(song.formatTitle(), overflow: TextOverflow.ellipsis),
          ],
        ),
        subtitle: Text(song.formatArtist(), overflow: TextOverflow.ellipsis),
        dense: true,
      ),
    ),
  );
}
