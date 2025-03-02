import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/song_info.dart';
import 'package:polaris/utils.dart';

final getIt = GetIt.instance;

void noop() {}

abstract class ContextMenuButton<T> extends StatelessWidget {
  final IconData icon;
  final bool compact;
  final List<T> actions;
  final String? host;

  ContextMenuButton({
    required this.actions,
    this.icon = Icons.more_vert,
    this.compact = false,
    Key? key,
  })  : host = getIt<connection.Manager>().url,
        super(key: key);

  bool isActionPossible(T action) {
    return true;
  }

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
        return actions.where(isActionPossible).map((action) {
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
  final void Function() onRefresh;

  DirectoryContextMenuButton({
    required this.path,
    required super.actions,
    super.compact,
    super.icon,
    this.onRefresh = noop,
    Key? key,
  }) : super(key: key);

  @override
  (IconData, String) getActionVisuals(DirectoryAction action) {
    return switch (action) {
      DirectoryAction.queueLast => (Icons.playlist_add, contextMenuQueueLast),
      DirectoryAction.queueNext => (Icons.playlist_play, contextMenuQueueNext),
      DirectoryAction.refresh => (Icons.refresh, contextMenuRefresh),
      DirectoryAction.togglePin => (Icons.offline_pin, _isPinned() ? contextMenuUnpin : contextMenuPin),
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
        if (_isPinned()) {
          pinManager.unpinDirectory(host, path);
        } else {
          pinManager.pinDirectory(host, path);
        }
        break;
    }
  }

  bool _isPinned() {
    final pinManager = getIt<pin.Manager>();
    return pinManager.isDirectoryPinned(host, path);
  }

  Future<List<String>> _listSongs() async {
    final AppClient client = getIt<AppClient>();
    final songList = await client.flatten(path);
    return songList.paths;
  }
}

enum SongAction {
  queueLast,
  queueNext,
  removeFromQueue,
  togglePin,
  songInfo,
  viewAlbum,
  viewFolder,
}

class SongContextMenuButton extends ContextMenuButton<SongAction> {
  final String path;
  late final dto.Song? song;
  final void Function() onRemoveFromQueue;

  SongContextMenuButton({
    required this.path,
    required super.actions,
    super.compact,
    this.onRemoveFromQueue = noop,
    Key? key,
  }) : super(key: key) {
    final String? useHost = host;
    if (useHost != null) {
      song = getIt<CollectionCache>().getSong(useHost, path);
    }
  }

  @override
  bool isActionPossible(SongAction action) {
    return switch (action) {
      SongAction.queueLast => true,
      SongAction.queueNext => true,
      SongAction.removeFromQueue => true,
      SongAction.togglePin => true,
      SongAction.songInfo => song != null,
      SongAction.viewAlbum => song?.toAlbumHeader() != null && (getIt<connection.Manager>().apiVersion ?? 0) >= 8,
      SongAction.viewFolder => true,
    };
  }

  @override
  (IconData, String) getActionVisuals(SongAction action) {
    return switch (action) {
      SongAction.queueLast => (Icons.playlist_add, contextMenuQueueLast),
      SongAction.queueNext => (Icons.playlist_play, contextMenuQueueNext),
      SongAction.removeFromQueue => (Icons.clear, contextMenuRemoveFromQueue),
      SongAction.togglePin => (Icons.offline_pin, _isPinned() ? contextMenuUnpin : contextMenuPin),
      SongAction.songInfo => (Icons.info_outline, contextMenuSongInfo),
      SongAction.viewAlbum => (Icons.album, contextMenuViewAlbum),
      SongAction.viewFolder => (Icons.folder, contextMenuViewFolder),
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
        if (_isPinned()) {
          pinManager.unpinSong(host, path);
        } else {
          pinManager.pinSong(host, path);
        }
        break;
      case SongAction.viewAlbum:
        final pagesModel = getIt<PagesModel>();
        final albumHeader = song?.toAlbumHeader();
        if (albumHeader != null) {
          pagesModel.openAlbumPage(albumHeader);
        }
        break;
      case SongAction.viewFolder:
        final pagesModel = getIt<PagesModel>();
        final browserModel = getIt<BrowserModel>();
        pagesModel.closeAll();
        browserModel.jumpTo(dirname(path));
        break;
    }
  }

  bool _isPinned() {
    final pinManager = getIt<pin.Manager>();
    return pinManager.isSongPinned(host, path);
  }
}

enum SongsAction {
  queueLast,
  queueNext,
}

class SongsContextMenuButton extends ContextMenuButton<SongsAction> {
  final List<String> paths;

  SongsContextMenuButton({
    required this.paths,
    required super.actions,
    super.compact,
    super.icon,
    Key? key,
  }) : super(key: key);

  @override
  (IconData, String) getActionVisuals(SongsAction action) {
    return switch (action) {
      SongsAction.queueLast => (Icons.playlist_add, contextMenuQueueLast),
      SongsAction.queueNext => (Icons.playlist_play, contextMenuQueueNext),
    };
  }

  @override
  void executeAction(BuildContext context, SongsAction action) async {
    switch (action) {
      case SongsAction.queueLast:
        getIt<Playlist>().queueLast(paths);
        break;
      case SongsAction.queueNext:
        getIt<Playlist>().queueNext(paths);
        break;
    }
  }
}

enum AlbumAction {
  queueLast,
  queueNext,
  togglePin,
}

class AlbumContextMenuButton extends ContextMenuButton<AlbumAction> {
  final String name;
  final List<String> mainArtists;
  final List<dto.Song>? songs;

  AlbumContextMenuButton({
    required this.name,
    required this.mainArtists,
    required super.actions,
    super.compact,
    super.icon,
    this.songs,
    Key? key,
  }) : super(key: key);

  @override
  (IconData, String) getActionVisuals(AlbumAction action) {
    return switch (action) {
      AlbumAction.queueLast => (Icons.playlist_add, contextMenuQueueLast),
      AlbumAction.queueNext => (Icons.playlist_play, contextMenuQueueNext),
      AlbumAction.togglePin => (Icons.offline_pin, _isPinned() ? contextMenuUnpin : contextMenuPin),
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
      case AlbumAction.togglePin:
        final pinManager = getIt<pin.Manager>();
        if (_isPinned()) {
          pinManager.unpinAlbum(host, name, mainArtists);
        } else {
          pinManager.pinAlbum(host, name, mainArtists);
        }
        break;
    }
  }

  Future<List<String>> _listSongs() async {
    final knownSongs = songs;
    if (knownSongs != null) {
      return knownSongs.map((s) => s.path).toList();
    }
    final AppClient client = getIt<AppClient>();
    final listedSongs = (await client.apiClient?.getAlbum(name, mainArtists))?.songs ?? [];
    return listedSongs.map((s) => s.path).toList();
  }

  bool _isPinned() {
    final pinManager = getIt<pin.Manager>();
    return pinManager.isAlbumPinned(host, name, mainArtists);
  }
}

enum PinAction {
  unpin,
}

class PinContextMenuButton extends ContextMenuButton<PinAction> {
  final pin.Pin myPin;

  PinContextMenuButton({
    required this.myPin,
    required super.actions,
    super.compact,
    super.icon,
    Key? key,
  }) : super(key: key);

  @override
  (IconData, String) getActionVisuals(PinAction action) {
    return switch (action) {
      PinAction.unpin => (Icons.offline_pin, contextMenuUnpin),
    };
  }

  @override
  void executeAction(BuildContext context, PinAction action) async {
    switch (action) {
      case PinAction.unpin:
        final pinManager = getIt<pin.Manager>();
        switch (myPin) {
          case final pin.DirectoryPin p:
            pinManager.unpinDirectory(p.host, p.path);
          case final pin.SongPin p:
            pinManager.unpinSong(p.host, p.path);
          case final pin.AlbumPin p:
            pinManager.unpinAlbum(p.host, p.name, p.mainArtists);
        }
        break;
    }
  }
}

enum PlaylistAction {
  delete,
}

class PlaylistContextMenuButton extends ContextMenuButton<PlaylistAction> {
  final String name;

  PlaylistContextMenuButton({
    required this.name,
    required super.actions,
    super.compact,
    super.icon,
    Key? key,
  }) : super(key: key);

  @override
  (IconData, String) getActionVisuals(PlaylistAction action) {
    return switch (action) {
      PlaylistAction.delete => (Icons.delete, contextMenuDeletePlaylist),
    };
  }

  @override
  void executeAction(BuildContext context, PlaylistAction action) async {
    switch (action) {
      case PlaylistAction.delete:
        final client = getIt<AppClient>();
        await client.apiClient?.deletePlaylist(name);
        break;
    }
  }
}
