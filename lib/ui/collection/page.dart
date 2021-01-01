import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:polaris/ui/collection/browser.dart';
import 'package:polaris/ui/collection/random.dart';
import 'package:polaris/ui/collection/recent.dart';

import '../strings.dart';

class CollectionPage extends StatefulWidget {
  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> with SingleTickerProviderStateMixin {
  final List<Tab> tabs = <Tab>[
    Tab(text: collectionTabBrowseTitle),
    Tab(text: collectionTabRandomTitle),
    Tab(text: collectionTabRecentTitle),
  ];

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: tabs.length);
    _tabController.addListener(() => setState(() {}));
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
          Browser(handleBackButton: _tabController.index == 0),
          RandomAlbums(),
          RecentAlbums(),
        ],
      ),
    );
  }
}
