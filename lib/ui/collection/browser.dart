import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart' as dto;
import 'package:polaris/ui/collection/album_details.dart';
import 'package:polaris/ui/collection/album_grid.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class Browser extends StatefulWidget {
  final bool handleBackButton;

  Browser({this.handleBackButton, Key key}) : super(key: key);

  @override
  _BrowserState createState() => _BrowserState();
}

class _BrowserState extends State<Browser> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<String> _locations = [''];

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
    if (!widget.handleBackButton) {
      return false;
    }
    return _navigateToParent();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final Color fillColor = Theme.of(context).scaffoldBackgroundColor;
    final sharedAxisTransition =
        SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled, fillColor: fillColor);
    final PageTransitionsTheme transitionTheme = PageTransitionsTheme(
        builders: {TargetPlatform.android: sharedAxisTransition, TargetPlatform.iOS: sharedAxisTransition});

    return Theme(
      data: Theme.of(context).copyWith(pageTransitionsTheme: transitionTheme),
      child: Navigator(
        pages: _locations.map((location) {
          return MaterialPage(
              child: BrowserLocation(
            location,
            onDirectoryTapped: _navigateToChild,
            navigateBack: () => _navigateToParent(),
          ));
        }).toList(),
        onPopPage: (route, result) {
          return route.didPop(result);
        },
      ),
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

enum ViewMode {
  explorer,
  discography,
}

class BrowserLocation extends StatefulWidget {
  final String location;
  final void Function(dto.Directory) onDirectoryTapped;
  final void Function() navigateBack;

  BrowserLocation(this.location, {@required this.onDirectoryTapped, @required this.navigateBack, Key key})
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
    // TODO handle error
    getIt<API>().browse(widget.location).then((files) {
      setState(() {
        _files = files;
      });
    });
  }

  ViewMode _getViewMode() {
    if (_files == null || _files.length == 0) {
      return ViewMode.explorer;
    }

    var onlyDirectories = true;
    var hasAnyPicture = false;
    var allHaveAlbums = true;
    for (var file in _files) {
      onlyDirectories &= file.isDirectory();
      hasAnyPicture |= file.asDirectory()?.artwork != null;
      allHaveAlbums &= file.asDirectory()?.album != null;
    }

    if (onlyDirectories && hasAnyPicture && allHaveAlbums) {
      return ViewMode.discography;
    }
    return ViewMode.explorer;
  }

  @override
  Widget build(BuildContext context) {
    // TODO some kind of breadcrumb / current directory name
    if (_files == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_files.length == 0) {
      return EmptyDirectory(widget.navigateBack);
    }

    if (_getViewMode() == ViewMode.discography) {
      final albums = _files.map((f) => f.asDirectory()).toList();
      return AlbumGrid(albums);
    } else {
      return ListView.builder(
        physics: BouncingScrollPhysics(),
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
}

class EmptyDirectory extends StatelessWidget {
  final void Function() navigateBack;

  EmptyDirectory(this.navigateBack) : assert(navigateBack != null);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 24,
              color: Theme.of(context).textTheme.caption.color,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(emptyDirectory),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: OutlineButton(onPressed: navigateBack, child: Text(goBackButtonLabel)),
        )
      ],
    );
  }
}

class Directory extends StatelessWidget {
  final dto.Directory directory;
  final GestureTapCallback onTap;

  Directory(this.directory, {this.onTap, Key key})
      : assert(directory != null),
        super(key: key);

  Widget _getLeading() {
    if (directory.artwork != null || directory.album != null) {
      return ListThumbnail(directory.artwork);
    }
    return Icon(Icons.folder);
  }

  Widget _getSubtitle() {
    if (directory.album != null) {
      return Text(directory.formatArtist());
    }
    return null;
  }

  ListTile _buildTile() {
    return ListTile(
      leading: _getLeading(),
      title: Text(directory.formatName()),
      subtitle: _getSubtitle(),
      trailing: Icon(Icons.more_vert),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile();
    if (directory.album == null) {
      return GestureDetector(
        onTap: onTap,
        child: tile,
      );
    } else {
      return OpenContainer(
        closedElevation: 0,
        useRootNavigator: true,
        transitionType: ContainerTransitionType.fade,
        closedColor: Theme.of(context).scaffoldBackgroundColor,
        openColor: Theme.of(context).scaffoldBackgroundColor,
        openBuilder: (context, action) {
          return AlbumDetails(directory);
        },
        closedBuilder: (context, action) {
          return tile;
        },
      );
    }
  }
}

class Song extends StatelessWidget {
  final dto.Song song;

  Song(this.song, {Key key})
      : assert(song != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ListThumbnail(song.artwork),
      title: Text(song.formatTrackNumberAndTitle(), overflow: TextOverflow.ellipsis),
      subtitle: Text(song.formatArtist(), overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.more_vert),
      dense: true,
    );
  }
}
