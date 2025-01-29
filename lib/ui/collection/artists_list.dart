import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class ArtistsList extends StatefulWidget {
  final List<dto.ArtistHeader>? _artists;
  final APIError? _error;
  final void Function() _retryAfterError;

  const ArtistsList(this._artists, this._error, this._retryAfterError, {Key? key}) : super(key: key);

  @override
  State<ArtistsList> createState() => _ArtistsListState();
}

class _ArtistsListState extends State<ArtistsList> {
  String _filter = '';
  final TextEditingController _filterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filterController.addListener(refreshFilter);
  }

  @override
  void didUpdateWidget(ArtistsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _filterController.removeListener(refreshFilter);
    super.dispose();
  }

  void refreshFilter() {
    setFilter(_filterController.text);
  }

  void setFilter(String newFilter) {
    if (newFilter == _filter) {
      return;
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
    setState(() {
      _filter = newFilter;
    });
  }

  bool isRelevant(dto.ArtistHeader artist) {
    return artist.numAlbumsAsPerformer > 0 ||
        artist.numAlbumsAsComposer > 0 ||
        artist.numAlbumsAsLyricist > 0 ||
        artist.numAlbumsAsAdditionalPerformer > 1;
  }

  List<dto.ArtistHeader> filter(List<dto.ArtistHeader> allArtists) {
    return allArtists.where((a) {
      if (!isRelevant(a)) {
        return false;
      }
      if (_filter.isEmpty) {
        return true;
      }
      return a.name.toLowerCase().contains(_filter.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
          child: TextField(
            maxLines: 1,
            controller: _filterController,
            decoration: InputDecoration(
              hintText: filterFieldLabel,
              prefixIcon: const Icon(Icons.filter_alt),
              suffixIcon: _filterController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => _filterController.clear(),
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (value) => setFilter(value),
          ),
        ),
        Expanded(child: _buildResults(context))
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    if (widget._error != null) {
      return ErrorMessage(
        artistsError,
        action: widget._retryAfterError,
        actionLabel: retryButtonLabel,
      );
    }

    final allArtists = widget._artists;
    if (allArtists == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredArtists = filter(allArtists);
    if (filteredArtists.isEmpty) {
      return const ErrorMessage(noArtists);
    }

    final pagesModel = getIt<PagesModel>();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24),
      controller: _scrollController,
      itemCount: filteredArtists.length,
      itemBuilder: (BuildContext context, int index) {
        final artist = filteredArtists[index];
        return InkWell(
          onTap: () => pagesModel.openArtistPage(artist.name),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.person),
            ),
            title: Text(
              artist.name,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(nSongs(artist.numSongs)),
            dense: true,
          ),
        );
      },
    );
  }
}
