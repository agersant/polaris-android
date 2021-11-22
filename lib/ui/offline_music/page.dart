import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/ui/strings.dart';

final getIt = GetIt.instance;

class OfflineMusicPage extends StatelessWidget {
  const OfflineMusicPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(offlineMusicTitle),
      ),
      body: Container(),
    );
  }
}
