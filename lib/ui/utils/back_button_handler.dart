import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/ui/collection/browser_model.dart';

final getIt = GetIt.instance;

class BackButtonHandler extends StatefulWidget {
  final Widget child;
  BackButtonHandler(this.child);

  @override
  _BackButtonHandlerState createState() => _BackButtonHandlerState();
}

class _BackButtonHandlerState extends State<BackButtonHandler> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
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
