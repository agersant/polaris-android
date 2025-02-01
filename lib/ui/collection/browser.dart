import 'dart:math';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/context_menu.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/utils.dart';

final getIt = GetIt.instance;

class Browser extends StatefulWidget {
  const Browser({Key? key}) : super(key: key);

  @override
  State<Browser> createState() => _BrowserState();
}

class _BrowserState extends State<Browser> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final Color fillColor = Theme.of(context).scaffoldBackgroundColor;
    final sharedAxisTransition =
        SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal, fillColor: fillColor);
    final PageTransitionsTheme transitionTheme = PageTransitionsTheme(
        builders: {TargetPlatform.android: sharedAxisTransition, TargetPlatform.iOS: sharedAxisTransition});

    final dividerColor = DividerTheme.of(context).color ?? Theme.of(context).dividerColor;

    final browserModel = getIt<BrowserModel>();
    return ListenableBuilder(
      listenable: browserModel,
      builder: (BuildContext context, Widget? child) {
        final isTopLevel = browserModel.browserStack.length == 1;
        final String title = isTopLevel ? 'All Files' : basename(browserModel.browserStack.last);
        return Theme(
          data: Theme.of(context).copyWith(pageTransitionsTheme: transitionTheme),
          child: PopScope(
            canPop: !browserModel.isBrowserActive || browserModel.browserStack.length <= 1,
            onPopInvokedWithResult: (didPop, dynamic result) {
              if (didPop) {
                return;
              }
              final bool shouldPop = !browserModel.isBrowserActive || !browserModel.popBrowserLocation();
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: Theme.of(context).textTheme.titleMedium),
                              if (!isTopLevel)
                                Breadcrumbs(browserModel.browserStack.last, browserModel.popBrowserLocations),
                            ],
                          ),
                        ),
                        Expanded(
                            flex: 0,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: DirectoryContextMenuButton(
                                path: browserModel.browserStack.last,
                                icon: Icons.menu,
                                actions: const [
                                  DirectoryAction.queueLast,
                                  DirectoryAction.queueNext,
                                  DirectoryAction.togglePin,
                                ],
                              ),
                            ))
                      ],
                    )),
                SizedBox(height: 1, child: Container(color: dividerColor)),
                Expanded(
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: Navigator(
                      onDidRemovePage: (page) {},
                      pages: browserModel.browserStack.map((location) {
                        return MaterialPage<dynamic>(
                          child: BrowserLocation(
                            location,
                            onDirectoryTapped: browserModel.pushBrowserLocation,
                            navigateBack: browserModel.popBrowserLocation,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class BrowserLocation extends StatefulWidget {
  final String location;
  final void Function(String) onDirectoryTapped;
  final void Function() navigateBack;

  const BrowserLocation(this.location, {required this.onDirectoryTapped, required this.navigateBack, Key? key})
      : super(key: key);

  @override
  State<BrowserLocation> createState() => _BrowserLocationState();
}

class _BrowserLocationState extends State<BrowserLocation> {
  List<dto.BrowserEntry>? _entries;
  APIError? _error;

  @override
  initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(BrowserLocation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _fetchData();
    }
  }

  Future _fetchData({bool useCache = true}) async {
    setState(() {
      _entries = null;
      _error = null;
    });
    try {
      final entries = await getIt<AppClient>().browse(widget.location, useCache: useCache);
      setState(() {
        _entries = entries;
      });
    } on APIError catch (e) {
      setState(() {
        _error = e;
      });
    }
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

    List<dto.BrowserEntry>? entries = _entries;
    if (entries == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (entries.isEmpty) {
      return ErrorMessage(
        emptyDirectory,
        action: widget.navigateBack,
        actionLabel: goBackButtonLabel,
      );
    }

    late Widget content;

    content = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.isDirectory) {
          return Directory(entry, onTap: () => widget.onDirectoryTapped(entry.path));
        } else {
          return Song(entry);
        }
      },
    );

    return RefreshIndicator(
      onRefresh: () => _fetchData(useCache: false),
      child: content,
    );
  }
}

class Directory extends StatelessWidget {
  final dto.BrowserEntry entry;
  final GestureTapCallback? onTap;

  const Directory(this.entry, {this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: const Icon(Icons.folder),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(entry.formatName()),
        trailing: DirectoryContextMenuButton(
          path: entry.path,
          actions: const [
            DirectoryAction.queueLast,
            DirectoryAction.queueNext,
            DirectoryAction.togglePin,
          ],
        ),
      ),
    );
  }
}

class Song extends StatelessWidget {
  final dto.BrowserEntry entry;

  const Song(this.entry, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        onTap: _onTap,
        dense: true,
        leading: const Icon(Icons.audio_file),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(entry.formatName(), overflow: TextOverflow.ellipsis),
        trailing: SongContextMenuButton(
          path: entry.path,
          actions: const [
            SongAction.queueLast,
            SongAction.queueNext,
            SongAction.songInfo,
            SongAction.viewAlbum,
            SongAction.togglePin,
          ],
        ),
      ),
    );
  }

  void _onTap() {
    final Playlist playlist = getIt<Playlist>();
    playlist.queueLast([entry.path]);
  }
}

class Breadcrumbs extends StatefulWidget {
  final String path;
  final void Function(int) popLocations;

  const Breadcrumbs(this.path, this.popLocations, {Key? key}) : super(key: key);

  @override
  State<Breadcrumbs> createState() => _BreadcrumbsState();
}

class _BreadcrumbsState extends State<Breadcrumbs> {
  final _scrollController = ScrollController();

  List<String> _getSegments() {
    final components = splitPath(widget.path).where((s) => s.isNotEmpty);
    return ["All"].followedBy(components.take(max(0, components.length - 1))).toList();
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
      final style = Theme.of(context).textTheme.bodySmall;
      return Breadcrumb(
        name: value,
        style: style,
        onTap: () => widget.popLocations(segments.length - index),
      );
    });
    List<Widget> children = breadcrumbs.expand((breadcrumb) => [const Chevron(), breadcrumb]).skip(1).toList();

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
  const Chevron({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color? chevronColor = Theme.of(context).textTheme.bodySmall?.color;
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
  final TextStyle? style;
  final void Function() onTap;

  const Breadcrumb({Key? key, required this.name, required this.onTap, this.style}) : super(key: key);

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
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
