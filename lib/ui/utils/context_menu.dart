import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/song_info.dart';

final getIt = GetIt.instance;

void noop() {}

enum CollectionFileAction {
  queueLast,
  queueNext,
  refresh,
  removeFromQueue,
  togglePin,
  songInfo,
}

class CollectionFileContextMenuButton extends StatelessWidget {
  final String path;
  final String? host;
  final List<dto.Song>? children;
  final IconData icon;
  final bool compact;
  final List<CollectionFileAction> actions;
  final void Function() onRefresh;
  final void Function() onRemoveFromQueue;

  const CollectionFileContextMenuButton(
      {required this.path,
      required this.actions,
      this.children,
      this.compact = false,
      this.icon = Icons.more_vert,
      this.onRefresh = noop,
      this.onRemoveFromQueue = noop,
      this.host,
      Key? key})
      : super(key: key);

  String? _getHost() {
    return host ?? getIt<connection.Manager>().url;
  }

  @override
  Widget build(BuildContext context) {
    // Mimic logic from ListTile._iconColor
    const iconSize = 20.0;
    final theme = Theme.of(context);
    final ListTileThemeData tileTheme = ListTileTheme.of(context);
    var iconColor = tileTheme.iconColor;
    iconColor ??= theme.brightness == Brightness.light ? Colors.black45 : theme.iconTheme.color;

    final icon = Icon(
      this.icon,
      color: iconColor,
      size: iconSize,
    );

    return PopupMenuButton<CollectionFileAction>(
      icon: compact ? null : icon,
      iconSize: iconSize,
      onSelected: (CollectionFileAction result) async {
        switch (result) {
          case CollectionFileAction.queueLast:
            // TODO v8 fixme
            // getIt<Playlist>().queueLast(await _listSongs());
            break;
          case CollectionFileAction.queueNext:
            // TODO v8 fixme
            // getIt<Playlist>().queueNext(await _listSongs());
            break;
          case CollectionFileAction.refresh:
            onRefresh();
            break;
          case CollectionFileAction.removeFromQueue:
            onRemoveFromQueue();
            break;
          case CollectionFileAction.togglePin:
            final pinManager = getIt<pin.Manager>();
            final String? useHost = _getHost();
            if (useHost != null) {
              if (_isPinned()) {
                // TODO v8 fixme
                // pinManager.unpin(useHost, file);
              } else {
                // TODO v8 fixme
                // pinManager.pin(useHost, file);
              }
            }
            break;
          case CollectionFileAction.songInfo:
            // TODO v8 fixme
            // if (file.isSong()) {
            //   SongInfoDialog.openInfoDialog(context, file.asSong());
            // }
            break;
          default:
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<CollectionFileAction>>[
          if (actions.contains(CollectionFileAction.queueLast))
            _buildButton(CollectionFileAction.queueLast, Icons.playlist_add, contextMenuQueueLast),
          if (actions.contains(CollectionFileAction.queueNext))
            _buildButton(CollectionFileAction.queueNext, Icons.playlist_play, contextMenuQueueNext),
          if (actions.contains(CollectionFileAction.refresh))
            _buildButton(CollectionFileAction.refresh, Icons.refresh, contextMenuRefresh),
          if (actions.contains(CollectionFileAction.removeFromQueue))
            _buildButton(CollectionFileAction.removeFromQueue, Icons.clear, contextMenuRemoveFromQueue),
          if (actions.contains(CollectionFileAction.togglePin))
            _buildButton(CollectionFileAction.togglePin, Icons.offline_pin,
                _isPinned() ? contextMenuUnpinFile : contextMenuPinFile),
          if (actions.contains(CollectionFileAction.songInfo))
            _buildButton(CollectionFileAction.songInfo, Icons.info_outline, contextMenuSongInfo),
        ];
      },
      // Manually specify child because default IconButton comes with an excessive minimum size of 48x48
      child: compact ? icon : null,
    );
  }

  bool _isPinned() {
    final pinManager = getIt<pin.Manager>();
    final String? useHost = _getHost();
    if (useHost == null) {
      return false;
    } else {
      // TODO v8 fixme
      // return pinManager.isPinned(useHost, file);
      return false;
    }
  }

  Future<List<dto.Song>> _listSongs() async {
    // TODO v8 fixme
    return [];

    // final knownSongs = children;
    // if (file.isDirectory()) {
    //   if (knownSongs == null) {
    //     // TODO Show some kind of UI while this is in progress and/or confirm result
    //     final polaris.Client client = getIt<polaris.Client>();
    //     final hostOverride = host;
    //     if (hostOverride != null && hostOverride != client.connectionManager.url) {
    //       return await client.offlineClient.flatten(hostOverride, file.path);
    //     }
    //     return await client.flatten(file.path);
    //   } else {
    //     return knownSongs;
    //   }
    // } else {
    //   return [file.asSong()];
    // }
  }

  PopupMenuItem<CollectionFileAction> _buildButton(CollectionFileAction action, IconData icon, String label) {
    return PopupMenuItem<CollectionFileAction>(
      value: action,
      child: Row(
        children: [
          Padding(padding: const EdgeInsets.only(right: 16.0), child: Icon(icon)),
          Text(label),
        ],
      ),
    );
  }
}
