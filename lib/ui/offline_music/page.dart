import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/dto.dart' as dto;
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
              children: const [
                Caption('21 Directories'),
                Caption('124 songs'),
                Caption('5d 20h 31m'),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PinsByServer(),
                  PinsByServer(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PinsByServer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ServerHeader(),
        ListView.builder(
          itemCount: 20,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return PinListTile();
          },
        ),
      ],
    );
  }
}

class ServerHeader extends StatelessWidget {
  const ServerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.desktop_windows, size: 16)),
              Text('From polaris.agersant.com', style: Theme.of(context).textTheme.bodyText2),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class PinListTile extends StatelessWidget {
  // final String host;
  // final dto.CollectionFile file;

  const PinListTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const ListThumbnail(
          'Leviathan/OST - Anime/Howl\'s Moving Castle/2004 - Howl\'s Moving Castle Soundtrack/Folder.jpg'),
      title: Row(
        children: [
          Padding(padding: const EdgeInsets.only(right: 8), child: PinState()),
          const Text('Automatic for the People'),
        ],
      ),
      subtitle: Column(
        children: [
          Row(
            children: const [
              Caption('14 songs'),
              Caption('2.58 MB'),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.more_vert),
    );
  }
}

class PinState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final index = 5;
    if (index < 4) {
      return Icon(Icons.check, size: 16, color: Theme.of(context).textTheme.caption?.color);
    } else if (index == 4) {
      return const SizedBox(
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
      return Icon(Icons.cloud_outlined, size: 16, color: Theme.of(context).textTheme.caption?.color);
    }
  }
}

class Caption extends StatelessWidget {
  final String text;
  const Caption(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 8), child: Text(text));
}
