import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';

// Copy-pasta from the widget with the same name from audio_service, but with handler for didPopRoute()
// We don't want to disconnect when random popups get closed
// TODO submit bug report about this
class PolarisAudioServiceWidget extends StatefulWidget {
  final Widget child;

  PolarisAudioServiceWidget({@required this.child});

  @override
  _AudioServiceWidgetState createState() => _AudioServiceWidgetState();
}

class _AudioServiceWidgetState extends State<PolarisAudioServiceWidget> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AudioService.connect();
  }

  @override
  void dispose() {
    AudioService.disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        AudioService.connect();
        break;
      case AppLifecycleState.paused:
        AudioService.disconnect();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
