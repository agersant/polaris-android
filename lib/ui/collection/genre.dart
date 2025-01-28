import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/ui/collection/genre_overview.dart';
import 'package:polaris/ui/strings.dart';

final getIt = GetIt.instance;

class Genre extends StatefulWidget {
  final String genreName;

  const Genre(this.genreName, {Key? key}) : super(key: key);

  @override
  State<Genre> createState() => _GenreState();
}

class _GenreState extends State<Genre> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 3);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.genreName),
        bottom: TabBar(tabs: <Tab>[
          Tab(text: genreOverview.toUpperCase()),
          Tab(text: genreArtists.toUpperCase()),
          Tab(text: genreAlbums.toUpperCase()),
        ], controller: _tabController),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GenreOverview(widget.genreName),
          GenreOverview(widget.genreName), // TODO v8 implement full list of genre artists
          GenreOverview(widget.genreName), // TODO v8 implement full list of genre albums
        ],
      ),
    );
  }
}
