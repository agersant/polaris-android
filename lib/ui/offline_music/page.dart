import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class OfflineMusicPage extends StatelessWidget {
  const OfflineMusicPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(offlineMusicTitle),
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.offline_pin, size: 40),
            title: const Text("1.24 GB"),
            subtitle: Row(
              children: [
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text("21 Directories", style: Theme.of(context).textTheme.caption)),
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text("124 songs", style: Theme.of(context).textTheme.caption)),
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text("5d 20h 31m", style: Theme.of(context).textTheme.caption)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                late Widget stateIcon;
                if (index < 4) {
                  stateIcon = Icon(Icons.check, size: 16, color: Theme.of(context).textTheme.caption?.color);
                } else if (index == 4) {
                  stateIcon = const SizedBox(
                    width: 10,
                    height: 10,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                } else {
                  stateIcon = Icon(Icons.cloud_outlined, size: 16, color: Theme.of(context).textTheme.caption?.color);
                }
                return ListTile(
                  dense: true,
                  leading: const ListThumbnail(
                      'Leviathan/OST - Anime/Howl\'s Moving Castle/2004 - Howl\'s Moving Castle Soundtrack/Folder.jpg'),
                  title: Row(
                    children: [
                      Padding(padding: const EdgeInsets.only(right: 8), child: stateIcon),
                      const Text('Automatic for the People'),
                    ],
                  ),
                  subtitle: Column(
                    children: [
                      Row(
                        children: const [
                          Padding(padding: EdgeInsets.only(right: 8), child: Text('14 songs')),
                          Padding(padding: EdgeInsets.only(right: 8), child: Text('2.58 MB')),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.more_vert),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
