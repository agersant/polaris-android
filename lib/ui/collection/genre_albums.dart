import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/ui/collection/album_grid.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class GenreAlbums extends StatefulWidget {
  final String genreName;

  const GenreAlbums(this.genreName, {Key? key}) : super(key: key);

  @override
  State<GenreAlbums> createState() => _GenreAlbumsState();
}

class _GenreAlbumsState extends State<GenreAlbums> {
  List<dto.AlbumHeader>? _albums;
  APIError? _error;

  @override
  void didUpdateWidget(covariant GenreAlbums oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.genreName != widget.genreName) {
      fetchAlbums();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void fetchAlbums() async {
    final client = getIt<AppClient>().apiClient;
    if (client == null) {
      return;
    }
    setState(() {
      _albums = null;
      _error = null;
    });
    try {
      final albums = await client.getGenreAlbums(widget.genreName);
      setState(() => _albums = albums);
    } on APIError catch (e) {
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorMessage(
        genreAlbumsError,
        action: fetchAlbums,
        actionLabel: retryButtonLabel,
      );
    }

    final albums = _albums;
    if (albums == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AlbumGrid(
        albums,
        null,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shrinkWrap: false,
      ),
    );
  }
}
