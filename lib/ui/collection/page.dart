import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/collection/browser.dart';
import 'package:polaris/ui/collection/random.dart';
import 'package:polaris/ui/collection/recent.dart';
import '../strings.dart';

final getIt = GetIt.instance;

class CollectionPage extends StatefulWidget {
  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> with SingleTickerProviderStateMixin {
  final _browserModel = getIt<BrowserModel>();
  final List<Tab> tabs = <Tab>[
    Tab(text: collectionTabBrowseTitle),
    Tab(text: collectionTabRandomTitle),
    Tab(text: collectionTabRecentTitle),
  ];
  late final TabController _tabController = new TabController(vsync: this, length: tabs.length);

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_handleActiveTabChanged);
    _handleActiveTabChanged();
  }

  _handleActiveTabChanged() {
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
        title: Text(collectionTitle),
        bottom: TabBar(tabs: tabs, controller: _tabController),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Browser(),
          RandomAlbums(),
          RecentAlbums(),
        ],
      ),
    );
  }
}
