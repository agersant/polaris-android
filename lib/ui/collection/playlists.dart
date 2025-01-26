import 'dart:async';
import 'package:flutter/material.dart' hide Placeholder;
import 'package:get_it/get_it.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/context_menu.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/format.dart';

final getIt = GetIt.instance;

class Playlists extends StatefulWidget {
  const Playlists({Key? key}) : super(key: key);

  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {
  List<dto.PlaylistHeader>? _playlists;
  late final StreamSubscription playlistsSubscription;

  @override
  initState() {
    super.initState();

    final connectionManager = getIt<connection.Manager>();
    final collectionCache = getIt<CollectionCache>();
    playlistsSubscription = collectionCache.onPlaylistsUpdated.listen((_) {
      final host = connectionManager.url;
      if (host != null) {
        setState(() => _playlists = collectionCache.getPlaylists(host));
      }
    });

    final client = getIt<AppClient>();
    client.apiClient?.listPlaylists();
  }

  @override
  void dispose() {
    super.dispose();
    playlistsSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final playlists = _playlists;
    if (playlists == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (playlists.isEmpty) {
      return const ErrorMessage(noSavedPlaylists);
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          itemCount: playlists.length,
          itemBuilder: (context, index) => _playlistWidget(context, playlists[index]),
        ),
      );
    }
  }
}

Widget _playlistWidget(BuildContext context, dto.PlaylistHeader playlist) {
  final queue = getIt<Playlist>();
  final client = getIt<AppClient>();

  return ListTile(
    leading: IconButton.outlined(
      onPressed: () async {
        final playlistDetails = await client.apiClient?.getPlaylist(playlist.name);
        if (playlistDetails == null) {
          return;
        }
        await queue.clear();
        await queue.queueLast(playlistDetails.songs.paths);
        queue.setName(playlist.name);
      },
      icon: const Icon(Icons.play_arrow),
    ),
    trailing: PlaylistContextMenuButton(
      name: playlist.name,
      actions: const [PlaylistAction.delete],
    ),
    title: Text(playlist.name, overflow: TextOverflow.ellipsis),
    subtitle: Text(formatLongDuration(Duration(seconds: playlist.duration))),
  );
}
