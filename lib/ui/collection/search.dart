import 'package:async/async.dart';
import 'package:flutter/material.dart' hide Placeholder;
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/context_menu.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/placeholder.dart';
import 'package:polaris/ui/utils/thumbnail.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  String? _query;
  CancelableOperation<dto.SongList>? _activeRequest;
  APIError? _error;
  List<String> _results = [];
  final _scrollController = ScrollController();

  void _startQuery(String query) async {
    final appClient = getIt<AppClient>();
    final apiClient = appClient.apiClient;
    if (apiClient == null) {
      return;
    }

    _activeRequest?.cancel();
    setState(() {
      _query = query;
      _activeRequest = CancelableOperation.fromFuture(apiClient.search(query));
    });

    try {
      final songList = await _activeRequest?.value;
      setState(() {
        _error = null;
        _results = songList?.paths ?? [];
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
    } on APIError catch (e) {
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          SearchBar(
              leading: const Icon(Icons.search),
              padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 16.0)),
              autoFocus: true,
              onSubmitted: (value) => _startQuery(value),
              elevation: const WidgetStatePropertyAll(3.0),
              shape: const WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))))),
          Expanded(child: buildResults(context))
        ],
      ),
    );
  }

  Widget buildResults(BuildContext context) {
    if (_activeRequest?.isCompleted == false) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorMessage(
        searchError,
        action: () => _startQuery(_query!),
        actionLabel: retryButtonLabel,
      );
    }

    if (_query?.trim().isEmpty == false) {
      if (_results.isEmpty) {
        return const ErrorMessage(noSearchResults);
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    numSearchResults(_results.length),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SongsContextMenuButton(
                    paths: _results,
                    icon: Icons.menu,
                    actions: const [SongsAction.queueLast, SongsAction.queueNext],
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                controller: _scrollController,
                itemCount: _results.length,
                itemBuilder: (context, index) => _songWidget(context, _results[index]),
              ),
            ),
          ],
        );
      }
    }

    return Container();
  }
}

Widget _songWidget(BuildContext context, String path) {
  final collectionCache = getIt<CollectionCache>();
  final host = getIt<connection.Manager>().url!;
  final (songStream, initialSong) = collectionCache.getSongStream(host, path);
  return StreamProvider<dto.Song?>.value(
      key: Key(path),
      value: songStream,
      initialData: initialSong,
      builder: (context, snapshot) {
        return StreamBuilder<PlayerState>(
            stream: getIt<AudioPlayer>().playerStateStream,
            builder: (context, snapshot) {
              final song = context.watch<dto.Song?>();
              return Material(
                child: InkWell(
                  onTap: () {
                    final Playlist playlist = getIt<Playlist>();
                    playlist.queueLast([path]);
                  },
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: ListThumbnail(song?.artwork),
                    title: song == null
                        ? const Placeholder(width: 100, height: 8)
                        : Text(song.title ?? unknownSong, overflow: TextOverflow.ellipsis),
                    subtitle: song == null
                        ? const Placeholder(width: 100, height: 8)
                        : Text(song.formatArtistsAndDuration(), overflow: TextOverflow.ellipsis),
                    trailing: SongContextMenuButton(
                      path: path,
                      actions: const [
                        SongAction.queueLast,
                        SongAction.queueNext,
                        SongAction.togglePin,
                        SongAction.songInfo,
                        SongAction.viewAlbum,
                      ],
                    ),
                  ),
                ),
              );
            });
      });
}
