import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';

// Copy-pasta from the widget with the same name from audio_service, but without the handler for didPopRoute()
// This handler is problematic because AudioServiceWidget registers with WidgetsBindingObserver
// before the Polaris Browser, and disconnects from the AudioService before the browser intercepts back button presses.
// This leaves us with a disconnected audio service while the UI is still up.
// However, the disconnect in didPopRoute is also important. Avoids resource leak:
// Activity agersant.polaris.MainActivity has leaked ServiceConnection android.media.browse.MediaBrowser$MediaServiceConnection@12e1f74 that was originally bound here
//
// Related to this hack. Warning when backing out of app:
// https://github.com/ryanheise/audio_service/issues/73
// https://github.com/ryanheise/audio_service/pull/77
// TODO submit bug report about this and/or find a better workaround
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
