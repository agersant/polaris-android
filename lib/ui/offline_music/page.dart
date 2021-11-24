import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/ui/collection/context_menu.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class OfflineMusicPage extends StatefulWidget {
  const OfflineMusicPage({Key? key}) : super(key: key);

  @override
  State<OfflineMusicPage> createState() => _OfflineMusicPageState();
}

class _OfflineMusicPageState extends State<OfflineMusicPage> {
  late Stream<List<pin.Host>> _hosts;
  late StreamSubscription _statsSubscription;
  int numDirectories = 0;
  int numSongs = 0;

  @override
  initState() {
    super.initState();
    final pinManager = getIt<pin.Manager>();
    final String? host = getIt<connection.Manager>().url;
    _hosts = pinManager.hostsStream.map((Set<pin.Host> hosts) {
      return hosts.toList()
        ..sort((a, b) {
          if (a.url == host) return -1;
          if (b.url == host) return 1;
          return a.url.compareTo(b.url);
        });
    });

    _statsSubscription = pinManager.hostsStream.listen(_updateStats);
  }

  @override
  void dispose() {
    super.dispose();
    _statsSubscription.cancel();
  }

  void _updateStats(Set<pin.Host> hosts) {
    int newNumDirectories = 0;
    int newNumSongs = 0;
    for (pin.Host host in hosts) {
      for (dto.CollectionFile file in host.content) {
        if (file.isDirectory()) {
          newNumDirectories += 1;
        } else {
          newNumSongs += 1;
        }
      }
    }
    setState(() {
      numDirectories = newNumDirectories;
      numSongs = newNumSongs;
    });
  }

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
            title: const Text("1.24 GB"), // TODO compute size on disc
            subtitle: Row(
              children: [
                Caption('$numDirectories ${numDirectories == 1 ? 'Directory' : 'Directories'}'),
                Caption('$numSongs songs'),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder(
                stream: _hosts,
                initialData: const <pin.Host>[],
                builder: (BuildContext context, AsyncSnapshot<List<pin.Host>> snapshot) {
                  // TODO add help message if nothing pinned
                  return Column(
                    children: snapshot.requireData.map((pin.Host host) => PinsByServer(host)).toList(),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PinsByServer extends StatelessWidget {
  final pin.Host host;

  const PinsByServer(this.host, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pinnedFiles = host.content.toList()..sort((a, b) => a.path.compareTo(b.path));

    return Column(
      children: [
        ServerHeader(host.url),
        ListView.builder(
          itemCount: pinnedFiles.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) =>
              PinListTile(pinnedFiles[index], key: Key(host.url + pinnedFiles[index].path)),
        ),
      ],
    );
  }
}

class ServerHeader extends StatelessWidget {
  final String host;

  const ServerHeader(this.host, {Key? key}) : super(key: key);

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
              Text('From $host', style: Theme.of(context).textTheme.bodyText2),
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
  final dto.CollectionFile file;

  const PinListTile(this.file, {Key? key}) : super(key: key);

  String formatTitle() {
    if (file.isDirectory()) {
      return file.asDirectory().formatName();
    } else {
      return file.asSong().formatTitle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      // TODO this will try to fetch art from current server, even for offline music from other servers
      leading: ListThumbnail(file.artwork),
      title: Row(
        children: [
          // TODO file loading state
          const Padding(padding: EdgeInsets.only(right: 8), child: PinState()),
          Expanded(child: Text(formatTitle(), overflow: TextOverflow.ellipsis))
        ],
      ),
      subtitle: Column(
        children: [
          Row(
            children: const [
              // TODO directory stats
              Caption('14 songs'),
              Caption('2.58 MB'),
            ],
          ),
        ],
      ),
      trailing: CollectionFileContextMenuButton(
        file: file,
        actions: const [
          CollectionFileAction.queueLast,
          CollectionFileAction.queueNext,
          CollectionFileAction.togglePin,
        ],
      ),
    );
  }
}

class PinState extends StatelessWidget {
  const PinState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const index = 5;
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
