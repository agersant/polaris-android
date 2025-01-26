import 'package:flutter/material.dart' hide Placeholder;
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
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
  APIError? _error;

  @override
  initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() {
      _playlists = null;
      _error = null;
    });
    try {
      final client = getIt<AppClient>();
      final playlists = await client.apiClient?.listPlaylists();
      setState(() => _playlists = playlists);
    } on APIError catch (e) {
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorMessage(
        listPlaylistsError,
        action: () => _fetchData(),
        actionLabel: retryButtonLabel,
      );
    }

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
          itemBuilder: (context, index) => _playlistWidget(context, playlists[index], _fetchData),
        ),
      );
    }
  }
}

Widget _playlistWidget(BuildContext context, dto.PlaylistHeader playlist, void Function() refresh) {
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
      },
      icon: const Icon(Icons.play_arrow),
    ),
    trailing: PlaylistContextMenuButton(
      name: playlist.name,
      actions: const [PlaylistAction.delete],
      andThen: (action) {
        if (action == PlaylistAction.delete) {
          refresh();
        }
      },
    ),
    title: Text(playlist.name, overflow: TextOverflow.ellipsis),
    subtitle: Text(formatLongDuration(Duration(seconds: playlist.duration))),
  );
}
