import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/ui/strings.dart';

final getIt = GetIt.instance;

enum CollectionFileAction {
  queueLast,
  queueNext,
}

class CollectionFileContextMenuButton extends StatelessWidget {
  final dto.CollectionFile file;

  const CollectionFileContextMenuButton({required this.file, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CollectionFileAction>(
      onSelected: (CollectionFileAction result) async {
        final Playlist playlist = getIt<Playlist>();
        final polaris.Client client = getIt<polaris.Client>();

        late List<dto.Song> songs;
        if (file.isDirectory()) {
          // TODO show some kind of UI while this is in progress (+ confirm)
          songs = await client.flatten(file.asDirectory().path);
        } else {
          songs = [file.asSong()];
        }
        switch (result) {
          case CollectionFileAction.queueLast:
            playlist.queueLast(songs);
            break;
          case CollectionFileAction.queueNext:
            playlist.queueNext(songs);
            break;
          default:
            break;
        }
      },
      itemBuilder: (BuildContext context) => const <PopupMenuEntry<CollectionFileAction>>[
        PopupMenuItem<CollectionFileAction>(
          value: CollectionFileAction.queueLast,
          child: Text(queueLast),
        ),
        PopupMenuItem<CollectionFileAction>(
          value: CollectionFileAction.queueNext,
          child: Text(queueNext),
        ),
      ],
    );
  }
}
