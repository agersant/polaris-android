import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class Genres extends StatefulWidget {
  const Genres({Key? key}) : super(key: key);

  @override
  State<Genres> createState() => _GenresState();
}

class _GenresState extends State<Genres> {
  List<dto.GenreHeader>? _genres;
  APIError? _error;
  String _filter = '';
  final TextEditingController _filterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filterController.addListener(refreshFilter);
    fetchGenres();
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

  List<dto.GenreHeader> filter(List<dto.GenreHeader> allGenres) {
    return allGenres.where((g) {
      return g.name.toLowerCase().contains(_filter.toLowerCase());
    }).toList();
  }

  void fetchGenres() async {
    final APIClientInterface? client = getIt<AppClient>().apiClient;
    if (client == null) {
      return;
    }
    try {
      setState(() => _error = null);
      final genres = await client.getGenres();
      setState(() => _genres = genres);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_error != null) {
      return ErrorMessage(
        genresError,
        action: fetchGenres,
        actionLabel: retryButtonLabel,
      );
    }

    final allGenres = _genres;
    if (allGenres == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredGenres = filter(allGenres);
    if (filteredGenres.isEmpty) {
      return const ErrorMessage(noGenres);
    }

    final pagesModel = getIt<PagesModel>();

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredGenres.length,
      itemBuilder: (BuildContext context, int index) {
        final genre = filteredGenres[index];
        return InkWell(
          // onTap: () => pagesModel.openArtistPage(artist.name),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.label),
            ),
            title: Text(
              genre.name,
              overflow: TextOverflow.ellipsis,
            ),
            dense: true,
          ),
        );
      },
    );
  }
}
