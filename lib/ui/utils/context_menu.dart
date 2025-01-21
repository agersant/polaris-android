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

abstract class ContextMenuButton<T> extends StatelessWidget {
  final IconData icon;
  final bool compact;
  final List<T> actions;

  const ContextMenuButton({
    required this.actions,
    this.icon = Icons.more_vert,
    this.compact = false,
    Key? key,
  }) : super(key: key);

  (IconData, String) getActionVisuals(T action);

  void executeAction(BuildContext context, T action);

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

    return PopupMenuButton<T>(
      icon: compact ? null : icon,
      iconSize: iconSize,
      onSelected: (action) => executeAction(context, action),
      itemBuilder: (BuildContext context) {
        return actions.map((action) {
          final (icon, label) = getActionVisuals(action);
          return _buildButton(action, icon, label);
        }).toList();
      },
      // Manually specify child because default IconButton comes with an excessive minimum size of 48x48
      child: compact ? icon : null,
    );
  }

  PopupMenuItem<T> _buildButton(T action, IconData icon, String label) {
    return PopupMenuItem<T>(
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

enum DirectoryAction {
  queueLast,
  queueNext,
  refresh,
  togglePin,
}

class DirectoryContextMenuButton extends ContextMenuButton<DirectoryAction> {
  final String path;
  final String? host;
  final void Function() onRefresh;

  const DirectoryContextMenuButton({
    required this.path,
    required super.actions,
    super.compact,
    this.onRefresh = noop,
    this.host,
    Key? key,
  }) : super(key: key);

  @override
  (IconData, String) getActionVisuals(DirectoryAction action) {
    return switch (action) {
      DirectoryAction.queueLast => (Icons.playlist_add, contextMenuQueueLast),
      DirectoryAction.queueNext => (Icons.playlist_play, contextMenuQueueNext),
      DirectoryAction.refresh => (Icons.refresh, contextMenuRefresh),
      DirectoryAction.togglePin => (Icons.offline_pin, _isPinned() ? contextMenuUnpinFile : contextMenuPinFile),
    };
  }

  @override
  void executeAction(BuildContext context, DirectoryAction action) async {
    switch (action) {
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
  }

  String? _getHost() {
    return host ?? getIt<connection.Manager>().url;
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
}

enum SongAction {
  queueLast,
  queueNext,
  removeFromQueue,
  togglePin,
  songInfo,
}

class SongContextMenuButton extends ContextMenuButton<SongAction> {
  final String path;
  final String? host;
  late final dto.Song? song;
  final void Function() onRemoveFromQueue;

  SongContextMenuButton({
    required this.path,
    required super.actions,
    super.compact,
    this.onRemoveFromQueue = noop,
    this.host,
    Key? key,
  }) : super(key: key) {
    final String? useHost = _getHost();
    if (useHost != null) {
      song = getIt<CollectionCache>().getSong(useHost, path);
    }
  }

  @override
  (IconData, String) getActionVisuals(SongAction action) {
    return switch (action) {
      SongAction.queueLast => (Icons.playlist_add, contextMenuQueueLast),
      SongAction.queueNext => (Icons.playlist_play, contextMenuQueueNext),
      SongAction.removeFromQueue => (Icons.clear, contextMenuRemoveFromQueue),
      SongAction.togglePin => (Icons.offline_pin, _isPinned() ? contextMenuUnpinFile : contextMenuPinFile),
      SongAction.songInfo => (Icons.info_outline, contextMenuSongInfo),
    };
  }

  @override
  void executeAction(BuildContext context, SongAction action) async {
    switch (action) {
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
  }

  String? _getHost() {
    return host ?? getIt<connection.Manager>().url;
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
}

enum AlbumAction {
  queueLast,
  queueNext,
  refresh,
  // TODO v8 pinnable albums
}

class AlbumContextMenuButton extends ContextMenuButton<AlbumAction> {
  final String name;
  final List<String> mainArtists;
  final List<dto.Song>? songs;
  final void Function() onRefresh;

  const AlbumContextMenuButton({
    required this.name,
    required this.mainArtists,
    required super.actions,
    super.compact,
    super.icon,
    this.onRefresh = noop,
    this.songs,
    Key? key,
  }) : super(key: key);

  @override
  (IconData, String) getActionVisuals(AlbumAction action) {
    return switch (action) {
      AlbumAction.queueLast => (Icons.playlist_add, contextMenuQueueLast),
      AlbumAction.queueNext => (Icons.playlist_play, contextMenuQueueNext),
      AlbumAction.refresh => (Icons.refresh, contextMenuRefresh),
    };
  }

  @override
  void executeAction(BuildContext context, AlbumAction action) async {
    switch (action) {
      case AlbumAction.queueLast:
        getIt<Playlist>().queueLast(await _listSongs());
        break;
      case AlbumAction.queueNext:
        getIt<Playlist>().queueNext(await _listSongs());
        break;
      case AlbumAction.refresh:
        onRefresh();
        break;
    }
  }

  Future<List<String>> _listSongs() async {
    final knownSongs = songs;
    if (knownSongs != null) {
      return knownSongs.map((s) => s.path).toList();
    }
    final polaris.Client client = getIt<polaris.Client>();
    final listedSongs = (await client.httpClient?.getAlbum(name, mainArtists))?.songs ?? [];
    return listedSongs.map((s) => s.path).toList();
  }
}
