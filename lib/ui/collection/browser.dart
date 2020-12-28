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

class _BrowserState extends State<Browser> with AutomaticKeepAliveClientMixin {
  List<dto.CollectionFile> _files;

  @override
  void initState() {
    super.initState();
    _browseTo('');
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
    super.build(context);
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
          return Directory(directory, onTap: () => _browseTo(directory.path));
        } else {
          assert(file.isSong());
          return Song(file.asSong());
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
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
