import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/collection/browser.dart';
import 'package:polaris/ui/collection/random.dart';
import 'package:polaris/ui/collection/recent.dart';
import 'package:provider/provider.dart';
import '../strings.dart';

final getIt = GetIt.instance;

class CollectionPage extends StatefulWidget {
  const CollectionPage({Key? key}) : super(key: key);

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> with SingleTickerProviderStateMixin {
  final _browserModel = getIt<BrowserModel>();
  // TODO remove random/recent tabs in offline mode
  final List<Tab> tabs = const <Tab>[
    Tab(text: collectionTabBrowseTitle),
    Tab(text: collectionTabRandomTitle),
    Tab(text: collectionTabRecentTitle),
  ];
  late final TabController _tabController = TabController(vsync: this, length: tabs.length);

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_handleActiveTabChanged);
    _handleActiveTabChanged();
  }

  void _handleActiveTabChanged() {
    _browserModel.isBrowserActive = _tabController.index == 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(collectionTitle),
        bottom: TabBar(tabs: tabs, controller: _tabController),
      ),
      drawer: _buildDrawer(context),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Browser(),
          RandomAlbums(),
          RecentAlbums(),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          _buildDrawerHeader(context),
          // TODO implement settings
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text(drawerSettings),
          ),
          // TODO implement offline music
          const ListTile(
            leading: Icon(Icons.offline_pin),
            title: Text(drawerOfflineMusic),
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
                    style: Theme.of(context).textTheme.headline6,
                  );
                },
              ),
              Consumer<connection.Manager>(
                builder: (context, connectionManager, child) {
                  return Text(
                    connectionManager.url ?? unknownHost,
                    style: Theme.of(context).textTheme.caption,
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
