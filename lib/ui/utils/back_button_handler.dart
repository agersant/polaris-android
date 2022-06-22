import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/ui/collection/browser_model.dart';

final getIt = GetIt.instance;

class BackButtonHandler extends StatefulWidget {
  final Widget child;
  const BackButtonHandler(this.child, {Key? key}) : super(key: key);

  @override
  _BackButtonHandlerState createState() => _BackButtonHandlerState();
}

class _BackButtonHandlerState extends State<BackButtonHandler> with WidgetsBindingObserver {
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

  // Unclear how this works out, but the code below fixes a bug where after a hot-reload,
  // the back buttons prioritizes closing collection browser routes instead of
  // album details.
  @override
  void didUpdateWidget(BackButtonHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  Future<bool> didPopRoute() async {
    final browserModel = getIt<BrowserModel>();
    if (!browserModel.isBrowserActive) {
      return false;
    }
    return browserModel.popBrowserLocation();
  }
}
