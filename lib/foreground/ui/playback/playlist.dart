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

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlistTitle),
      ),
      body: StreamBuilder<List<MediaItem>>(
          stream: AudioService.queueStream,
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return Container();
            }
            return ReorderableListView(
              children: snapshot.data.map((mediaItem) => _songWidget(mediaItem)).toList(),
              onReorder: (int a, int b) async {
                await AudioService.customAction(customActionMoveQueueItem, [a, b]);
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
