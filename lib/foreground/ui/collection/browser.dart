import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/shared/dto.dart' as dto;
import 'package:polaris/foreground/ui/model.dart';
import 'package:polaris/foreground/ui/collection/album_details.dart';
import 'package:polaris/foreground/ui/collection/album_grid.dart';
import 'package:polaris/foreground/ui/strings.dart';
import 'package:polaris/foreground/ui/utils/error_message.dart';
import 'package:polaris/foreground/ui/utils/format.dart';
import 'package:polaris/foreground/ui/utils/thumbnail.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

class Browser extends StatefulWidget {
  @override
  _BrowserState createState() => _BrowserState();
}

class _BrowserState extends State<Browser> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final Color fillColor = Theme.of(context).scaffoldBackgroundColor;
    final sharedAxisTransition =
        SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled, fillColor: fillColor);
    final PageTransitionsTheme transitionTheme = PageTransitionsTheme(
        builders: {TargetPlatform.android: sharedAxisTransition, TargetPlatform.iOS: sharedAxisTransition});

    final dividerColor = DividerTheme.of(context).color ?? Theme.of(context).dividerColor ?? Colors.black;

    return ChangeNotifierProvider.value(
      value: getIt<UIModel>(),
      child: Consumer<UIModel>(
        builder: (BuildContext context, UIModel uiModel, Widget child) {
          return Theme(
            data: Theme.of(context).copyWith(pageTransitionsTheme: transitionTheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Breadcrumbs(uiModel.browserStack.last, uiModel.popBrowserLocations),
                ),
                SizedBox(height: 1, child: Container(color: dividerColor)),
                Expanded(
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: Navigator(
                      pages: uiModel.browserStack.map((location) {
                        return MaterialPage(
                            child: BrowserLocation(
                          location,
                          onDirectoryTapped: uiModel.pushBrowserLocation,
                          navigateBack: uiModel.popBrowserLocation,
                        ));
                      }).toList(),
                      onPopPage: (route, result) {
                        return route.didPop(result);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
  polaris.APIError _error;

  @override
  initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() {
      _files = null;
      _error = null;
    });
    try {
      final files = await getIt<polaris.API>().browse(widget.location);
      setState(() {
        _files = files;
      });
    } on polaris.APIError catch (e) {
      setState(() {
        _error = e;
      });
    }
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
    if (_error != null) {
      return ErrorMessage(
        browseError,
        action: _fetchData,
        actionLabel: retryButtonLabel,
      );
    }

    if (_files == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_files.length == 0) {
      return ErrorMessage(
        emptyDirectory,
        action: widget.navigateBack,
        actionLabel: goBackButtonLabel,
      );
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

  ListTile _buildTile({void Function() onTap}) {
    return ListTile(
      leading: _getLeading(),
      title: Text(directory.formatName()),
      subtitle: _getSubtitle(),
      trailing: Icon(Icons.more_vert),
      dense: true,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAlbum = directory.album != null;
    final tile = _buildTile(onTap: isAlbum ? null : onTap);
    if (!isAlbum) {
      return Material(child: tile);
    } else {
      return OpenContainer(
        closedElevation: 0,
        useRootNavigator: true,
        transitionType: ContainerTransitionType.fade,
        closedColor: Theme.of(context).scaffoldBackgroundColor,
        openColor: Theme.of(context).scaffoldBackgroundColor,
        openBuilder: (context, action) => AlbumDetails(directory),
        closedBuilder: (context, action) => Material(child: InkWell(child: tile, enableFeedback: true, onTap: action)),
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

class Breadcrumbs extends StatefulWidget {
  final String path;
  final void Function(int) popLocations;

  Breadcrumbs(this.path, this.popLocations, {Key key})
      : assert(path != null),
        super(key: key);

  @override
  _BreadcrumbsState createState() => _BreadcrumbsState();
}

class _BreadcrumbsState extends State<Breadcrumbs> {
  final _scrollController = ScrollController();

  List<String> _getSegments() {
    return ["All"].followedBy(splitPath(widget.path).where((s) => s.isNotEmpty)).toList();
  }

  @override
  void didUpdateWidget(Breadcrumbs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> segments = _getSegments();

    final breadcrumbs = segments.asMap().entries.map((entry) {
      final int index = entry.key;
      final String value = entry.value;
      final style = index == segments.length - 1 ? TextStyle(color: Theme.of(context).accentColor) : null;
      return Breadcrumb(
        name: value,
        style: style,
        onTap: () => widget.popLocations(segments.length - 1 - index),
      );
    });
    List<Widget> children = breadcrumbs.expand((breadcrumb) => [Chevron(), breadcrumb]).skip(1).toList();

    return SizedBox(
      height: 24,
      child: ScrollConfiguration(
        behavior: BreadcrumbsScrollBehavior(),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: children,
          ),
        ),
      ),
    );
  }
}

class Chevron extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color chevronColor = Theme.of(context).textTheme.caption.color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Icon(
        Icons.chevron_right,
        color: chevronColor,
        size: 16,
      ),
    );
  }
}

class Breadcrumb extends StatelessWidget {
  final String name;
  final TextStyle style;
  final void Function() onTap;

  Breadcrumb({Key key, this.name, this.onTap, this.style})
      : assert(name != null),
        assert(onTap != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(name, style: style),
    );
  }
}

// Disable ink
class BreadcrumbsScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
