import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/ui/collection/artists_list.dart';
import 'package:polaris/ui/strings.dart';

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

  @override
  void initState() {
    super.initState();
    fetchArtists();
  }

  void setRole(Role newRole) {
    if (newRole == _role) {
      return;
    }
    setState(() => _role = newRole);
  }

  List<dto.ArtistHeader> filter(List<dto.ArtistHeader> allArtists, Role role) {
    return allArtists.where((a) {
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
    final artists = _artists == null ? null : filter(_artists!, _role);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        spacing: 16,
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
          Expanded(child: ArtistsList(artists, _error, fetchArtists)),
        ],
      ),
    );
  }
}
