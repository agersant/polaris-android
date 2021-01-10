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

final getIt = GetIt.instance;

class QueuePage extends StatefulWidget {
  @override
  _QueuePageState createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> with SingleTickerProviderStateMixin {
  // Keep a local copy of the queue so we can re-order without waiting for communication with background service
  // Directly reflecting AudioService.queueStream in the UI leads to flicker when finishing a drag and drop
  List<MediaItem> queue;

  @override
  void initState() {
    super.initState();
    AudioService.queueStream.listen((newQueue) {
      setState(() {
        queue = newQueue;
      });
    });
    queue = AudioService.queue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(queueTitle),
      ),
      body: StreamBuilder<List<MediaItem>>(
          stream: AudioService.queueStream,
          builder: (context, snapshot) {
            if (queue == null) {
              return Container();
            }
            return ReorderableListView(
              children: queue.map((mediaItem) => _songWidget(mediaItem)).toList(),
              onReorder: (int oldIndex, int newIndex) {
                final int insertIndex = oldIndex > newIndex ? newIndex : newIndex - 1;
                queue.insert(insertIndex, queue.removeAt(oldIndex));
                setState(() {});
                AudioService.customAction(customActionMoveQueueItem, [oldIndex, newIndex]);
              },
            );
          }),
    );
  }
}

Widget _songWidget(MediaItem mediaItem) {
  final dto.Song song = mediaItem.toSong();
  return ListTile(
    key: Key(mediaItem.id),
    leading: ListThumbnail(song.artwork),
    title: Text(song.formatTitle(), overflow: TextOverflow.ellipsis),
    subtitle: Text(song.formatArtist(), overflow: TextOverflow.ellipsis),
    trailing: Icon(Icons.more_vert),
    dense: true,
  );
}
