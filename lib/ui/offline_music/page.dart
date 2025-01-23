import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/prefetch.dart' as prefetch;
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/context_menu.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';
import 'package:polaris/utils.dart';

final getIt = GetIt.instance;

class OfflineMusicPage extends StatefulWidget {
  const OfflineMusicPage({Key? key}) : super(key: key);

  @override
  State<OfflineMusicPage> createState() => _OfflineMusicPageState();
}

class _OfflineMusicPageState extends State<OfflineMusicPage> {
  final _pinManager = getIt<pin.Manager>();
  final _prefetchManager = getIt<prefetch.Manager>();
  late StreamSubscription _fetchSubscription;
  int _sizeOnDisk = 0;
  bool _fullyComputedSizeOnDisk = false;

  @override
  initState() {
    super.initState();
    _pinManager.addListener(_updateSizeOnDisk);
    _fetchSubscription = _prefetchManager.songsBeingFetchedStream.listen((songs) => _updateSizeOnDisk());
  }

  @override
  void dispose() {
    super.dispose();
    _pinManager.removeListener(_updateSizeOnDisk);
    _fetchSubscription.cancel();
  }

  Future<void> _updateSizeOnDisk() async {
    int size = 0;
    for (String host in _pinManager.hosts) {
      final songs = _pinManager.getSongsInHost(host);
      if (songs == null) {
        continue;
      }
      size += await computeSizeOnDisk(songs, host, onProgress: (s) {
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
    final pinManager = getIt<pin.Manager>();
    return Scaffold(
      appBar: AppBar(title: const Text(offlineMusicTitle)),
      body: ListenableBuilder(
          listenable: pinManager,
          builder: (context, child) {
            final hosts = pinManager.hosts;
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.offline_pin, size: 40),
                  title: Text(formatBytes(_sizeOnDisk, 2)),
                  subtitle: Row(
                    children: [
                      Caption(nSongs(pinManager.countSongs())),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: hosts.isEmpty
                        ? _buildHelp()
                        : Column(children: hosts.map((host) => PinsByServer(host)).toList()),
                  ),
                )
              ],
            );
          }),
    );
  }
}

class PinsByServer extends StatelessWidget {
  final String host;

  const PinsByServer(this.host, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pins = getIt<pin.Manager>().getPinsForHost(host) ?? [];

    return Column(
      children: [
        ServerHeader(host),
        ListView.builder(
          itemCount: pins.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => PinListTile(
            host,
            pins[index],
            key: Key(host + pins[index].key),
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
              Text('From $host', style: Theme.of(context).textTheme.bodyMedium),
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
  final pin.Pin myPin;

  const PinListTile(this.host, this.myPin, {Key? key}) : super(key: key);

  @override
  State<PinListTile> createState() => _PinListTileState();
}

class _PinListTileState extends State<PinListTile> {
  final _connectionManager = getIt<connection.Manager>();
  final _prefetchManager = getIt<prefetch.Manager>();
  final _collectionCache = getIt<CollectionCache>();
  final _mediaCache = getIt<MediaCacheInterface>();

  late StreamSubscription _fetchSubscription;
  int? _numSongsOnDisk;
  int _sizeOnDisk = 0;
  bool _fullyComputedSizeOnDisk = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _updateNumSongsOnDisk() async {
    List<String> songs = widget.myPin.songs;
    int numSongsOnDisk = 0;
    for (String song in songs) {
      if (await _mediaCache.hasAudio(widget.host, song)) {
        numSongsOnDisk += 1;
      }
    }
    setState(() => _numSongsOnDisk = numSongsOnDisk);
  }

  Future<void> _updateSizeOnDisk() async {
    List<String> songs = widget.myPin.songs;
    final size = await computeSizeOnDisk(songs, widget.host, onProgress: (s) {
      if (!_fullyComputedSizeOnDisk) {
        setState(() => _sizeOnDisk = s);
      }
    });
    setState(() => _sizeOnDisk = size);
    _fullyComputedSizeOnDisk = true;
  }

  String _formatTitle() => switch (widget.myPin) {
        pin.SongPin p => _collectionCache.getSong(widget.host, p.path)?.formatTitle() ?? basename(p.path),
        pin.DirectoryPin p => basename(p.path),
        pin.AlbumPin p => '${p.name} by ${dto.AlbumHeader(name: p.name, mainArtists: p.mainArtists).formatArtists()}',
      };

  Widget _buildLeading() => switch (widget.myPin) {
        pin.SongPin p => ListThumbnail(_collectionCache.getSong(widget.host, p.path)?.artwork),
        pin.DirectoryPin _ => const SizedBox(width: 44, height: 44, child: Center(child: Icon(Icons.folder))),
        pin.AlbumPin p => ListThumbnail(p.artwork),
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: _buildLeading(),
      title: Row(
        children: [
          if (_connectionManager.isConnected())
            Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PinStateIcon(
                  widget.host,
                  widget.myPin,
                  numSongsOnDisk: _numSongsOnDisk,
                  totalSongs: widget.myPin.songs.length,
                )),
          Expanded(child: Text(_formatTitle(), overflow: TextOverflow.ellipsis))
        ],
      ),
      subtitle: Column(
        children: [
          Row(
            children: [
              if (_numSongsOnDisk != widget.myPin.songs.length)
                Caption(xySongs(_numSongsOnDisk, widget.myPin.songs.length)),
              if (_numSongsOnDisk == widget.myPin.songs.length) Caption(nSongs(_numSongsOnDisk)),
              if (_sizeOnDisk > 0) Caption(formatBytes(_sizeOnDisk, 2)),
            ],
          ),
        ],
      ),
      trailing: switch (widget.myPin) {
        pin.SongPin p => SongContextMenuButton(
            path: p.path,
            actions: const [SongAction.togglePin],
          ),
        pin.DirectoryPin p => DirectoryContextMenuButton(
            path: p.path,
            actions: const [DirectoryAction.togglePin],
          ),
        pin.AlbumPin p => AlbumContextMenuButton(
            name: p.name,
            mainArtists: p.mainArtists,
            actions: const [AlbumAction.togglePin],
          ),
      },
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
  final pin.Pin myPin;
  final int? numSongsOnDisk;
  final int? totalSongs;

  const PinStateIcon(
    this.host,
    this.myPin, {
    required this.numSongsOnDisk,
    required this.totalSongs,
    Key? key,
  }) : super(key: key);

  @override
  State<PinStateIcon> createState() => _PinStateIconState();
}

class _PinStateIconState extends State<PinStateIcon> {
  PinState _pinState = PinState.pending;
  late StreamSubscription _songsBeingFetchedSubscription;
  final _prefetchManager = getIt<prefetch.Manager>();

  @override
  initState() {
    super.initState();
    _songsBeingFetchedSubscription = _prefetchManager.songsBeingFetchedStream.listen((songs) => _updateState());
  }

  @override
  void dispose() {
    super.dispose();
    _songsBeingFetchedSubscription.cancel();
  }

  @override
  void didUpdateWidget(PinStateIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateState();
  }

  void _updateState() async {
    try {
      final newState = await _computeState();
      setState(() => _pinState = newState);
    } catch (e) {
      developer.log('Error while computing pin state: $e');
    }
  }

  Future<PinState> _computeState() async {
    if (await _isFetchingThis()) {
      return PinState.fetching;
    }
    if (widget.totalSongs == null || widget.numSongsOnDisk == null || widget.numSongsOnDisk != widget.totalSongs) {
      return PinState.pending;
    }
    return PinState.fetched;
  }

  Future<bool> _isFetchingThis() async {
    final songsBeingFetched = _prefetchManager.songsBeingFetched;
    return songsBeingFetched.any((song) => widget.myPin.songs.contains(song));
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
        return Icon(Icons.cloud_outlined, size: 16, color: Theme.of(context).textTheme.bodySmall?.color);
      case PinState.fetching:
        return _buildLoadingWidget();
      case PinState.fetched:
        return Icon(Icons.check, size: 16, color: Theme.of(context).textTheme.bodySmall?.color);
    }
  }
}

class Caption extends StatelessWidget {
  final String text;
  const Caption(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 8), child: Text(text));
}

Future<int> computeSizeOnDisk(Iterable<String> songs, String host, {Function(int)? onProgress}) async {
  final mediaCache = getIt<MediaCacheInterface>();

  int size = 0;
  await Future.wait(songs.map((song) async {
    final hasAudio = await mediaCache.hasAudio(host, song);
    if (!hasAudio) {
      return;
    }
    final cacheFile = mediaCache.getAudioLocation(host, song);
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
