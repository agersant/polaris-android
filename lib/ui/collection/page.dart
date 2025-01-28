import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/collection/artists.dart';
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/collection/browser.dart';
import 'package:polaris/ui/collection/genres.dart';
import 'package:polaris/ui/collection/playlists.dart';
import 'package:polaris/ui/collection/albums.dart';
import 'package:polaris/ui/collection/search.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:provider/provider.dart';
import '../strings.dart';

final getIt = GetIt.instance;

class CollectionPage extends StatefulWidget {
  const CollectionPage({Key? key}) : super(key: key);

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

enum CollectionTab {
  browse,
  albums,
  artists,
  genres,
  playlists,
  search,
}

class _CollectionPageState extends State<CollectionPage> with TickerProviderStateMixin {
  final _connectionManager = getIt<connection.Manager>();
  final _browserModel = getIt<BrowserModel>();
  late TabController _tabController = TabController(vsync: this, length: 0);
  late Set<CollectionTab> visibleTabs;

  @override
  void initState() {
    super.initState();
    _connectionManager.addListener(_handleConnectionStateChanged);
    _handleConnectionStateChanged();
  }

  void _handleConnectionStateChanged() {
    setState(() {
      final isOnline = _connectionManager.isConnected();
      // TODO legacy API cleanup
      final supportsPlaylists = (_connectionManager.apiVersion ?? 0) >= 8;
      final supportsArtists = (_connectionManager.apiVersion ?? 0) >= 8;
      final supportsGenres = (_connectionManager.apiVersion ?? 0) >= 8;
      visibleTabs = {
        CollectionTab.browse,
        if (isOnline) CollectionTab.albums,
        if (isOnline && supportsArtists) CollectionTab.artists,
        if (isOnline && supportsPlaylists) CollectionTab.playlists,
        if (isOnline && supportsGenres) CollectionTab.genres,
        if (isOnline) CollectionTab.search,
      };

      _tabController.dispose();
      // TODO slightly buggy due to https://github.com/flutter/flutter/issues/93237
      _tabController = TabController(vsync: this, length: visibleTabs.length);
      if (!isOnline) {
        _tabController.index = 0;
      }
      _tabController.addListener(_handleActiveTabChanged);
      _handleActiveTabChanged();
    });
  }

  void _handleActiveTabChanged() {
    _browserModel.setBrowserActive(_tabController.index == 0);
  }

  @override
  void dispose() {
    _connectionManager.removeListener(_handleConnectionStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(collectionTitle),
        bottom: TabBar(tabs: <Tab>[
          // TODO v8 add label for current tab?
          if (visibleTabs.contains(CollectionTab.browse)) const Tab(icon: Icon(Icons.folder)),
          if (visibleTabs.contains(CollectionTab.albums)) const Tab(icon: Icon(Icons.album)),
          if (visibleTabs.contains(CollectionTab.artists)) const Tab(icon: Icon(Icons.person)),
          if (visibleTabs.contains(CollectionTab.genres)) const Tab(icon: Icon(Icons.label)),
          if (visibleTabs.contains(CollectionTab.playlists)) const Tab(icon: Icon(Icons.playlist_play)),
          if (visibleTabs.contains(CollectionTab.search)) const Tab(icon: Icon(Icons.search)),
        ], controller: _tabController),
      ),
      drawer: _buildDrawer(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (visibleTabs.contains(CollectionTab.browse)) const Browser(),
          if (visibleTabs.contains(CollectionTab.albums)) const Albums(),
          if (visibleTabs.contains(CollectionTab.artists)) const Artists(),
          if (visibleTabs.contains(CollectionTab.genres)) const Genres(),
          if (visibleTabs.contains(CollectionTab.playlists)) const Playlists(),
          if (visibleTabs.contains(CollectionTab.search)) const Search(),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          _buildDrawerHeader(context),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text(drawerSettings),
            onTap: () {
              Navigator.pop(context);
              getIt<PagesModel>().openSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.offline_pin),
            title: const Text(drawerOfflineMusic),
            onTap: () {
              Navigator.pop(context);
              getIt<PagesModel>().openOfflineMusic();
            },
          ),
          _buildOfflineModeToggle(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text(drawerLogOut),
            onTap: () async {
              final connectionManager = getIt<connection.Manager>();
              connectionManager.disconnect();
            },
          ),
        ],
      ),
    );
  }

  Container _buildDrawerHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(border: Border(bottom: Divider.createBorderSide(context))),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            transform: Matrix4.translationValues(0, 3, 0),
            child: SvgPicture.asset('assets/images/logo.svg', semanticsLabel: 'Polaris logo', width: 40.0),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<authentication.Manager>(
                builder: (context, authenticationManager, child) {
                  return Text(
                    authenticationManager.username ?? unknownUser,
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
              Consumer<connection.Manager>(
                builder: (context, connectionManager, child) {
                  return Text(
                    connectionManager.url ?? unknownHost,
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineModeToggle() {
    return Consumer<connection.Manager>(
      builder: (context, connectionManager, child) {
        final Function(bool)? onChanged;
        if (connectionManager.canToggleOfflineMode()) {
          onChanged = (bool? value) {
            connectionManager.toggleOfflineMode();
          };
        } else {
          onChanged = null;
        }
        return SwitchListTile(
          title: const Text(drawerOfflineMode),
          value: connectionManager.state == connection.State.offlineMode,
          onChanged: onChanged,
          secondary: const Icon(Icons.cloud_off),
        );
      },
    );
  }
}
