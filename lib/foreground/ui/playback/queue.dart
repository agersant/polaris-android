import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/background/entrypoint.dart';
import 'package:polaris/foreground/ui/utils/thumbnail.dart';
import 'package:polaris/shared/dto.dart' as dto;
import 'package:polaris/foreground/ui/utils/format.dart';
import 'package:polaris/foreground/ui/strings.dart';
import 'package:polaris/shared/media_item.dart';
import 'package:rxdart/rxdart.dart';

final getIt = GetIt.instance;

class QueueState {
  final List<MediaItem> queue;
  MediaItem mediaItem;

  QueueState(this.queue, this.mediaItem);
}

Stream<QueueState> get _queueStateStream => Rx.combineLatest2<List<MediaItem>, MediaItem, QueueState>(
    AudioService.queueStream, AudioService.currentMediaItemStream, (queue, mediaItem) => QueueState(queue, mediaItem));

class QueuePage extends StatefulWidget {
  @override
  _QueuePageState createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> with SingleTickerProviderStateMixin {
  // Keep a local copy of the queue so we can re-order without waiting for communication with background service
  // Directly reflecting AudioService.queueStream in the UI leads to flicker when finishing a drag and drop
  QueueState localState;

  @override
  void initState() {
    super.initState();
    _queueStateStream.listen((newState) {
      setState(() {
        localState = newState;
      });
    });
    localState = QueueState(AudioService.queue, AudioService.currentMediaItem);
    // TODO autoscroll to current song?
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(queueTitle),
      ),
      body: StreamBuilder<List<MediaItem>>(
          // TODO number of songs and duration
          stream: AudioService.queueStream,
          builder: (context, snapshot) {
            return ReorderableListView(
              // TODO bounce physics (https://github.com/flutter/flutter/issues/66080)
              children: localState.queue.map((mediaItem) {
                final bool isCurrent = mediaItem.id == localState.mediaItem.id;
                final onTap = () {
                  localState.mediaItem = mediaItem;
                  setState(() {});
                  AudioService.skipToQueueItem(mediaItem.id);
                };
                return _songWidget(context, mediaItem, isCurrent, onTap);
              }).toList(),
              onReorder: (int oldIndex, int newIndex) {
                final int insertIndex = oldIndex > newIndex ? newIndex : newIndex - 1;
                localState.queue.insert(insertIndex, localState.queue.removeAt(oldIndex));
                setState(() {});
                AudioService.customAction(customActionMoveQueueItem, [oldIndex, newIndex]);
              },
            );
          }),
    );
  }
}

Widget _songWidget(BuildContext context, MediaItem mediaItem, bool isCurrent, Function() onTap) {
  final dto.Song song = mediaItem.toSong();
  final nowPlayingBackground = Colors.pink.shade400;
  final nowPlayingForeground = Colors.white;
  final tileColor = isCurrent ? nowPlayingBackground : ListTileTheme.of(context)?.tileColor;
  final titleTextStyle = TextStyle(color: isCurrent ? nowPlayingForeground : null);
  final subtitleTextStyle = TextStyle(color: isCurrent ? nowPlayingForeground.withOpacity(0.70) : null);
  return Material(
    key: Key(mediaItem.id),
    child: InkWell(
      onTap: onTap,
      child: ListTile(
        tileColor: tileColor,
        leading: ListThumbnail(song.artwork),
        title: Text(song.formatTitle(), overflow: TextOverflow.ellipsis, style: titleTextStyle),
        subtitle: Text(song.formatArtist(), overflow: TextOverflow.ellipsis, style: subtitleTextStyle),
        dense: true,
      ),
    ),
  );
}
