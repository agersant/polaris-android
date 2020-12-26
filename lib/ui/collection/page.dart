import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../strings.dart';

class CollectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(collectionTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: collectionTabBrowseTitle),
              Tab(text: collectionTabRandomTitle),
              Tab(text: collectionTabRecentTitle),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Icon(Icons.folder),
            Icon(Icons.shuffle),
            Icon(Icons.new_releases),
          ],
        ),
      ),
    );
  }
}
