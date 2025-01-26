import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchArtists();
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

  bool isRelevant(dto.ArtistHeader artist) {
    return artist.numAlbumsAsPerformer > 0 ||
        artist.numAlbumsAsComposer > 0 ||
        artist.numAlbumsAsLyricist > 0 ||
        artist.numAlbumsAsAdditionalPerformer > 1;
  }

  List<dto.ArtistHeader> _filter(List<dto.ArtistHeader> allArtists, Role role) {
    return allArtists.where((a) {
      if (!isRelevant(a)) {
        return false;
      }
      switch (_role) {
        case Role.performer:
          return a.numAlbumsAsPerformer > 0 || a.numAlbumsAsAdditionalPerformer > 1;
        case Role.composer:
          return a.numAlbumsAsComposer > 0;
        case Role.lyricist:
          return a.numAlbumsAsLyricist > 0;
      }
    }).toList();
  }

  void _fetchArtists() async {
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
        spacing: 24,
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
          Expanded(child: _buildResults(context))
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_error != null) {
      return ErrorMessage(
        artistsError,
        action: _fetchArtists,
        actionLabel: retryButtonLabel,
      );
    }

    final allArtists = _artists;
    if (allArtists == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredArtists = _filter(allArtists, _role);
    if (filteredArtists.isEmpty) {
      return const ErrorMessage(noArtists);
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredArtists.length,
      itemBuilder: (BuildContext context, int index) {
        final artist = filteredArtists[index];
        return ListTile(
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
        );
      },
    );
  }
}
