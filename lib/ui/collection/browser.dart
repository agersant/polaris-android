import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart' as dto;
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class Browser extends StatefulWidget {
  @override
  _BrowserState createState() => _BrowserState();
}

class _BrowserState extends State<Browser> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<String> _locations = [''];
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    return _navigateToParent();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Navigator(
      key: _navigatorKey,
      pages: _locations.map((location) {
        return MaterialPage(child: BrowserLocation(location, _navigateToChild));
      }).toList(),
      onPopPage: (route, result) {
        return route.didPop(result);
      },
    );
  }

  _navigateToChild(dto.Directory directory) {
    final newLocations = List<String>.from(_locations);
    newLocations.add(directory.path);
    setState(() {
      _locations = newLocations;
    });
  }

  bool _navigateToParent() {
    if (_locations.length <= 1) {
      return false;
    }

    final newLocations = List<String>.from(_locations);
    newLocations.removeLast();
    setState(() {
      _locations = newLocations;
    });
    return true;
  }

  @override
  bool get wantKeepAlive => true;
}

class BrowserLocation extends StatefulWidget {
  final String location;
  final void Function(dto.Directory) onDirectoryTapped;

  BrowserLocation(this.location, this.onDirectoryTapped, {Key key})
      : assert(location != null),
        assert(onDirectoryTapped != null),
        super(key: key);

  @override
  _BrowserLocationState createState() => _BrowserLocationState();
}

class _BrowserLocationState extends State<BrowserLocation> {
  List<dto.CollectionFile> _files;

  @override
  void initState() {
    super.initState();
    _browseTo(widget.location);
  }

  _browseTo(String path) async {
    // TODO handle error
    final newFiles = await getIt<API>().browse(path);
    // TODO scroll to top
    setState(() {
      _files = newFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_files == null) {
      return Center(child: CircularProgressIndicator());
    }
    // TODO handle zero files
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        if (file.isDirectory()) {
          final directory = file.asDirectory();
          return Directory(directory, onTap: () => widget.onDirectoryTapped(directory));
        } else {
          assert(file.isSong());
          return Song(file.asSong());
        }
      },
    );
  }
}

final _pathSeparatorRegExp = RegExp(r'[/\\]');

class Directory extends StatelessWidget {
  final dto.Directory directory;
  final GestureTapCallback onTap;

  Directory(this.directory, {this.onTap}) : assert(directory != null);

  String _getDirectoryName() {
    return directory.path.split(_pathSeparatorRegExp).last;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        leading: Icon(Icons.folder),
        title: Text(_getDirectoryName()),
        trailing: Icon(Icons.more_vert),
        dense: true,
      ),
    );
  }
}

class Song extends StatelessWidget {
  final dto.Song song;

  Song(this.song) : assert(song != null);

  String _getFileName() {
    return song.title ?? song.path.split(_pathSeparatorRegExp).last;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: SizedBox(height: 40, width: 40, child: Thumbnail(song.artwork))),
      title: Text(_getFileName(), overflow: TextOverflow.ellipsis),
      subtitle: Text(song.formatArtist(), overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.more_vert),
      dense: true,
    );
  }
}
