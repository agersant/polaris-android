import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../strings.dart';

class CollectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(collectionTitle),
      ),
      body: Center(child: Text('Hello')),
    );
  }
}
