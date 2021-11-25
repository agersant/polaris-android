import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/prefetch.dart' as prefetch;
import 'package:polaris/ui/collection/context_menu.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';
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
  late StreamSubscription _pinsSubscription;
  late StreamSubscription _fetchSubscription;
  final _pinManager = getIt<pin.Manager>();
  final _prefetchManager = getIt<prefetch.Manager>();
  int _numDirectories = 0;
  int _numSongs = 0;
  int _sizeOnDisk = 0;
  bool _fullyComputedSizeOnDisk = false;

  @override
  initState() {
    super.initState();
    final String? host = getIt<connection.Manager>().url;
    _hosts = _pinManager.hostsStream.map((Set<pin.Host> hosts) {
      return hosts.toList()
        ..sort((a, b) {
          if (a.url == host) return -1;
          if (b.url == host) return 1;
          return a.url.compareTo(b.url);
        });
    });

    _pinsSubscription = _pinManager.hostsStream.listen((hosts) {
      _updateStats(hosts);
      _updateSizeOnDisk();
    });

    _fetchSubscription = _prefetchManager.songsBeingFetchedStream.listen((songs) {
      _updateSizeOnDisk();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pinsSubscription.cancel();
    _fetchSubscription.cancel();
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
      _numDirectories = newNumDirectories;
      _numSongs = newNumSongs;
    });
  }

  Future<void> _updateSizeOnDisk() async {
    int size = 0;
    for (pin.Host host in _pinManager.hosts) {
      final songs = await _pinManager.getAllSongs(host.url);
      size += await computeSizeOnDisk(songs, host.url, onProgress: (s) {
        if (!_fullyComputedSizeOnDisk) {
          setState(() => _sizeOnDisk = size + s);
        }
      });
    }
    setState(() => _sizeOnDisk = size);
    _fullyComputedSizeOnDisk = true;
  }

  Widget _buildHelp() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: ErrorMessage(
        offlineMusicEmpty,
        icon: Icons.cloud_off,
        actionLabel: goBackButtonLabel,
        action: Navigator.of(context).pop,
      ),
    );
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
            title: Text(formatBytes(_sizeOnDisk, 2)),
            subtitle: Row(
              children: [
                Caption(nDirectories(_numDirectories)),
                Caption(nSongs(_numSongs)),
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
                  final hosts = snapshot.requireData;
                  if (hosts.isEmpty) {
                    return _buildHelp();
                  }
                  return Column(children: hosts.map((pin.Host host) => PinsByServer(host)).toList());
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
          // TODO When removing a pin, all the pins lower in the list get recreated
          itemBuilder: (context, index) => PinListTile(
            host.url,
            pinnedFiles[index],
            key: Key(host.url + pinnedFiles[index].path),
          ),
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

class PinListTile extends StatefulWidget {
  final String host;
  final dto.CollectionFile file;

  const PinListTile(this.host, this.file, {Key? key}) : super(key: key);

  @override
  State<PinListTile> createState() => _PinListTileState();
}

class _PinListTileState extends State<PinListTile> {
  final _connectionManager = getIt<connection.Manager>();
  final _prefetchManager = getIt<prefetch.Manager>();
  final _pinManager = getIt<pin.Manager>();
  final _mediaCache = getIt<MediaCacheInterface>();

  late StreamSubscription _fetchSubscription;
  int? _numSongsOnDisk;
  int? _totalSongs;
  int _sizeOnDisk = 0;
  bool _fullyComputedSizeOnDisk = false;

  @override
  void initState() {
    super.initState();
    _updateTotalSongs();
    _fetchSubscription = _prefetchManager.songsBeingFetchedStream.listen((event) {
      _updateNumSongsOnDisk();
      _updateSizeOnDisk();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _fetchSubscription.cancel();
  }

  Future<Set<dto.Song>> _listSongs() async {
    if (widget.file.isSong()) {
      return {widget.file.asSong()};
    } else {
      return await _pinManager.getSongsInDirectory(widget.host, widget.file.path);
    }
  }

  Future<void> _updateNumSongsOnDisk() async {
    final Set<dto.Song> songs = await _listSongs();
    int numSongsOnDisk = 0;
    for (dto.Song song in songs) {
      if (await _mediaCache.hasAudio(widget.host, song.path)) {
        numSongsOnDisk += 1;
      }
    }
    setState(() => _numSongsOnDisk = numSongsOnDisk);
  }

  Future<void> _updateTotalSongs() async {
    if (!_connectionManager.isConnected()) {
      setState(() => _totalSongs = null);
      return;
    }
    final Set<dto.Song> songs = await _listSongs();
    setState(() => _totalSongs = songs.length);
  }

  Future<void> _updateSizeOnDisk() async {
    final Set<dto.Song> songs = await _listSongs();
    final size = await computeSizeOnDisk(songs, widget.host, onProgress: (s) {
      if (!_fullyComputedSizeOnDisk) {
        setState(() => _sizeOnDisk = s);
      }
    });
    setState(() => _sizeOnDisk = size);
    _fullyComputedSizeOnDisk = true;
  }

  String formatTitle() {
    if (widget.file.isDirectory()) {
      return widget.file.asDirectory().formatName();
    } else {
      return widget.file.asSong().formatTitle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      // TODO this will try to fetch art from current server, even for offline music from other servers
      leading: ListThumbnail(widget.file.artwork),
      title: Row(
        children: [
          if (_connectionManager.isConnected())
            Padding(padding: const EdgeInsets.only(right: 8), child: PinStateIcon(widget.host, widget.file)),
          Expanded(child: Text(formatTitle(), overflow: TextOverflow.ellipsis))
        ],
      ),
      subtitle: Column(
        children: [
          Row(
            children: [
              if (_numSongsOnDisk != _totalSongs) Caption(xySongs(_numSongsOnDisk, _totalSongs)),
              if (_numSongsOnDisk == _totalSongs) Caption(nSongs(_numSongsOnDisk)),
              if (_sizeOnDisk > 0) Caption(formatBytes(_sizeOnDisk, 2)),
            ],
          ),
        ],
      ),
      trailing: CollectionFileContextMenuButton(
        file: widget.file,
        actions: const [
          CollectionFileAction.queueLast,
          CollectionFileAction.queueNext,
          CollectionFileAction.togglePin,
        ],
      ),
    );
  }
}

enum PinState {
  pending,
  fetching,
  fetched,
}

class PinStateIcon extends StatefulWidget {
  final String host;
  final dto.CollectionFile file;

  const PinStateIcon(this.host, this.file, {Key? key}) : super(key: key);

  @override
  State<PinStateIcon> createState() => _PinStateIconState();
}

class _PinStateIconState extends State<PinStateIcon> {
  PinState _pinState = PinState.pending;
  late StreamSubscription _songsBeingFetchedSubscription;
  final _prefetchManager = getIt<prefetch.Manager>();
  final _pinManager = getIt<pin.Manager>();

  @override
  initState() {
    super.initState();
    _songsBeingFetchedSubscription = _prefetchManager.songsBeingFetchedStream.listen((songs) async {
      try {
        final newState = await _computeState();
        setState(() => _pinState = newState);
      } catch (e) {
        developer.log('Error while computing pin state: $e');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _songsBeingFetchedSubscription.cancel();
  }

  Future<PinState> _computeState() async {
    if (await _isFetchingThis()) {
      return PinState.fetching;
    }
    if (await _finishedFetchingThis()) {
      return PinState.fetched;
    }
    return PinState.pending;
  }

  Future<bool> _isFetchingThis() async {
    final songsBeingFetched = _prefetchManager.songsBeingFetched;
    if (widget.file.isSong()) {
      return songsBeingFetched.any((song) => widget.file.path == song.path);
    }
    final songsInDirectory = await _pinManager.getSongsInDirectory(widget.host, widget.file.path);
    for (dto.Song songBeingFetched in songsBeingFetched) {
      if (songsInDirectory.any((song) => song.path == songBeingFetched.path)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _finishedFetchingThis() async {
    final mediaCache = getIt<MediaCacheInterface>();
    if (widget.file.isSong()) {
      return await mediaCache.hasAudio(widget.host, widget.file.path);
    }
    final songsToFetch = await _pinManager.getSongsInDirectory(widget.host, widget.file.path);
    for (dto.Song song in songsToFetch) {
      final hasAudio = await mediaCache.hasAudio(widget.host, song.path);
      if (!hasAudio) {
        return false;
      }
    }
    return true;
  }

  Widget _buildLoadingWidget() {
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
  }

  @override
  Widget build(BuildContext context) {
    switch (_pinState) {
      case PinState.pending:
        return Icon(Icons.cloud_outlined, size: 16, color: Theme.of(context).textTheme.caption?.color);
      case PinState.fetching:
        return _buildLoadingWidget();
      case PinState.fetched:
        return Icon(Icons.check, size: 16, color: Theme.of(context).textTheme.caption?.color);
    }
  }
}

class Caption extends StatelessWidget {
  final String text;
  const Caption(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 8), child: Text(text));
}

Future<int> computeSizeOnDisk(Set<dto.Song> songs, String host, {Function(int)? onProgress}) async {
  final _mediaCache = getIt<MediaCacheInterface>();

  int size = 0;
  await Future.wait(songs.map((song) async {
    final hasAudio = await _mediaCache.hasAudio(host, song.path);
    if (!hasAudio) {
      return;
    }
    final cacheFile = _mediaCache.getAudioLocation(host, song.path);
    try {
      final stat = await cacheFile.stat();
      size += stat.size;
      if (onProgress != null) {
        onProgress(size);
      }
    } catch (e) {
      return;
    }
  }));

  return size;
}
