import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/ui/collection/artists_list.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/format.dart';

final getIt = GetIt.instance;

class GenreArtists extends StatefulWidget {
  final String genreName;

  const GenreArtists(this.genreName, {Key? key}) : super(key: key);

  @override
  State<GenreArtists> createState() => _GenreArtistsState();
}

class _GenreArtistsState extends State<GenreArtists> {
  List<dto.ArtistHeader>? _artists;
  APIError? _error;

  @override
  void didUpdateWidget(covariant GenreArtists oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.genreName != widget.genreName) {
      fetchArtists();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchArtists();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void fetchArtists() async {
    final client = getIt<AppClient>().apiClient;
    if (client == null) {
      return;
    }
    setState(() {
      _artists = null;
      _error = null;
    });
    try {
      final artists = await client.getGenreArtists(widget.genreName);
      setState(() {
        _artists = artists.where((a) => !isFakeArtist(a.name)).toList();
      });
    } on APIError catch (e) {
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorMessage(
        genreArtistsError,
        action: fetchArtists,
        actionLabel: retryButtonLabel,
      );
    }

    final artists = _artists;
    if (artists == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: ArtistsList(_artists, _error, fetchArtists),
    );
  }
}
