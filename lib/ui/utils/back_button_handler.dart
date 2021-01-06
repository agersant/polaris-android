import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/transient/ui_model.dart';

final getIt = GetIt.instance;

class BackButtonHandler extends StatefulWidget {
  final Widget child;
  BackButtonHandler(this.child) : assert(child != null);

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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  Future<bool> didPopRoute() async {
    final uiModel = getIt<UIModel>();
    if (!uiModel.isBrowserActive) {
      return false;
    }
    return uiModel.popBrowserLocation();
  }
}
