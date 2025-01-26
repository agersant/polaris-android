import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/ui/collection/album_grid.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class Artist extends StatefulWidget {
  final String name;

  const Artist(this.name, {Key? key}) : super(key: key);

  @override
  State<Artist> createState() => _ArtistState();
}

class _ArtistState extends State<Artist> {
  dto.Artist? _artist;
  APIError? _error;

  @override
  void initState() {
    super.initState();
    _fetchArtist();
  }

  void _fetchArtist() async {
    final client = getIt<AppClient>();
    setState(() {
      _artist = null;
      _error = null;
    });
    try {
      final artist = await client.apiClient?.getArtist(widget.name);
      setState(() => _artist = artist);
    } on APIError catch (e) {
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return ErrorMessage(
        artistError,
        action: _fetchArtist,
        actionLabel: retryButtonLabel,
      );
    }

    final artist = _artist;
    if (artist == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: ListBody(
        children: [
          // TODO v8 add genres
          Text('Main Releases'),
          AlbumGrid(artist.albums, null),
          Text('Featured On'),
          AlbumGrid(artist.albums, null),
        ],
      ),
    );
  }
}
