import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/song_info.dart';

final getIt = GetIt.instance;

void noop() {}

enum DirectoryAction {
  queueLast,
  queueNext,
  refresh,
  togglePin,
}

// TODO v8 make base class for context menus so avoid copy/paste
class DirectoryContextMenuButton extends StatelessWidget {
  final String path;
  final String? host;
  final List<dto.Song>? children;
  final IconData icon;
  final bool compact;
  final List<DirectoryAction> actions;
  final void Function() onRefresh;

  const DirectoryContextMenuButton(
      {required this.path,
      required this.actions,
      this.children,
      this.compact = false,
      this.icon = Icons.more_vert,
      this.onRefresh = noop,
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

    return PopupMenuButton<DirectoryAction>(
      icon: compact ? null : icon,
      iconSize: iconSize,
      onSelected: (DirectoryAction result) async {
        switch (result) {
          case DirectoryAction.queueLast:
            getIt<Playlist>().queueLast(await _listSongs());
            break;
          case DirectoryAction.queueNext:
            getIt<Playlist>().queueNext(await _listSongs());
            break;
          case DirectoryAction.refresh:
            onRefresh();
            break;
          case DirectoryAction.togglePin:
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
        }
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<DirectoryAction>>[
          if (actions.contains(DirectoryAction.queueLast))
            _buildButton(DirectoryAction.queueLast, Icons.playlist_add, contextMenuQueueLast),
          if (actions.contains(DirectoryAction.queueNext))
            _buildButton(DirectoryAction.queueNext, Icons.playlist_play, contextMenuQueueNext),
          if (actions.contains(DirectoryAction.refresh))
            _buildButton(DirectoryAction.refresh, Icons.refresh, contextMenuRefresh),
          if (actions.contains(DirectoryAction.togglePin))
            _buildButton(
                DirectoryAction.togglePin, Icons.offline_pin, _isPinned() ? contextMenuUnpinFile : contextMenuPinFile),
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

  Future<List<String>> _listSongs() async {
    final knownSongs = children;
    if (knownSongs != null) {
      return knownSongs.map((s) => s.path).toList();
    }

    // TODO Show some kind of UI while this is in progress and/or confirm result
    final polaris.Client client = getIt<polaris.Client>();
    final hostOverride = host;
    if (hostOverride != null && hostOverride != client.connectionManager.url) {
      final songList = await client.offlineClient.flatten(hostOverride, path);
      return songList.paths;
    } else {
      final songList = await client.flatten(path);
      return songList.paths;
    }
  }

  PopupMenuItem<DirectoryAction> _buildButton(DirectoryAction action, IconData icon, String label) {
    return PopupMenuItem<DirectoryAction>(
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

enum SongAction {
  queueLast,
  queueNext,
  removeFromQueue,
  togglePin,
  songInfo,
}

class SongContextMenuButton extends StatelessWidget {
  final String path;
  final String? host;
  late final dto.Song? song;
  final IconData icon;
  final bool compact;
  final List<SongAction> actions;
  final void Function() onRemoveFromQueue;

  SongContextMenuButton(
      {required this.path,
      required this.actions,
      this.compact = false,
      this.icon = Icons.more_vert,
      this.onRemoveFromQueue = noop,
      this.host,
      Key? key})
      : super(key: key) {
    final String? useHost = _getHost();
    if (useHost != null) {
      song = getIt<CollectionCache>().getSong(useHost, path);
    }
  }

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

    return PopupMenuButton<SongAction>(
      icon: compact ? null : icon,
      iconSize: iconSize,
      onSelected: (SongAction result) async {
        switch (result) {
          case SongAction.queueLast:
            getIt<Playlist>().queueLast([path]);
            break;
          case SongAction.queueNext:
            getIt<Playlist>().queueNext([path]);
            break;
          case SongAction.removeFromQueue:
            onRemoveFromQueue();
            break;
          case SongAction.songInfo:
            final useSong = song;
            if (useSong != null) {
              SongInfoDialog.openInfoDialog(context, useSong);
            }
            break;
          case SongAction.togglePin:
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
        }
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<SongAction>>[
          if (actions.contains(SongAction.queueLast))
            _buildButton(SongAction.queueLast, Icons.playlist_add, contextMenuQueueLast),
          if (actions.contains(SongAction.queueNext))
            _buildButton(SongAction.queueNext, Icons.playlist_play, contextMenuQueueNext),
          if (actions.contains(SongAction.removeFromQueue))
            _buildButton(SongAction.removeFromQueue, Icons.clear, contextMenuRemoveFromQueue),
          if (actions.contains(SongAction.togglePin))
            _buildButton(
                SongAction.togglePin, Icons.offline_pin, _isPinned() ? contextMenuUnpinFile : contextMenuPinFile),
          if (song != null && actions.contains(SongAction.songInfo))
            _buildButton(SongAction.songInfo, Icons.info_outline, contextMenuSongInfo),
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

  PopupMenuItem<SongAction> _buildButton(SongAction action, IconData icon, String label) {
    return PopupMenuItem<SongAction>(
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
