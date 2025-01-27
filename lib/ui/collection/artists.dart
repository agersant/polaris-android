import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

enum Role {
  performer,
  composer,
  lyricist,
}

class Artists extends StatefulWidget {
  const Artists({Key? key}) : super(key: key);

  @override
  State<Artists> createState() => _ArtistsState();
}

class _ArtistsState extends State<Artists> {
  Role _role = Role.performer;
  List<dto.ArtistHeader>? _artists;
  APIError? _error;
  String _filter = '';
  final TextEditingController _filterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filterController.addListener(refresh);
    fetchArtists();
  }

  @override
  void dispose() {
    _filterController.removeListener(refresh);
    super.dispose();
  }

  void refresh() {
    setState(() {});
  }

  void setRole(Role newRole) {
    if (newRole == _role) {
      return;
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
    setState(() {
      _role = newRole;
    });
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

  List<dto.ArtistHeader> filter(List<dto.ArtistHeader> allArtists, Role role) {
    return allArtists.where((a) {
      if (!isRelevant(a)) {
        return false;
      }
      switch (_role) {
        case Role.performer:
          if (a.numAlbumsAsPerformer <= 0 && a.numAlbumsAsAdditionalPerformer <= 1) {
            return false;
          }
        case Role.composer:
          if (a.numAlbumsAsComposer <= 0) {
            return false;
          }
        case Role.lyricist:
          if (a.numAlbumsAsLyricist <= 0) {
            return false;
          }
      }
      if (_filter.isEmpty) {
        return true;
      }
      return a.name.toLowerCase().contains(_filter.toLowerCase());
    }).toList();
  }

  void fetchArtists() async {
    final APIClientInterface? client = getIt<AppClient>().apiClient;
    if (client == null) {
      return;
    }
    try {
      setState(() => _error = null);
      final artists = await client.getArtists();
      setState(() => _artists = artists);
    } on APIError catch (e) {
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          ToggleButtons(
            borderRadius: BorderRadius.circular(4),
            isSelected: Role.values.map((r) => r == _role).toList(),
            children: Role.values
                .map((m) => Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(switch (m) {
                        Role.performer => rolePerformer,
                        Role.composer => roleComposer,
                        Role.lyricist => roleLyricist,
                      }),
                    ))
                .toList(),
            onPressed: (index) => setRole(Role.values[index]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            child: TextField(
              maxLines: 1,
              controller: _filterController,
              decoration: InputDecoration(
                icon: const Icon(Icons.filter_alt),
                hintText: filterFieldLabel,
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
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_error != null) {
      return ErrorMessage(
        artistsError,
        action: fetchArtists,
        actionLabel: retryButtonLabel,
      );
    }

    final allArtists = _artists;
    if (allArtists == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredArtists = filter(allArtists, _role);
    if (filteredArtists.isEmpty) {
      return const ErrorMessage(noArtists);
    }

    final pagesModel = getIt<PagesModel>();

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredArtists.length,
      itemBuilder: (BuildContext context, int index) {
        final artist = filteredArtists[index];
        return InkWell(
          onTap: () => pagesModel.openArtistPage(artist.name),
          child: ListTile(
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
