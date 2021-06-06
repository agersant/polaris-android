import 'package:polaris/foreground/service.dart';

class MockServiceLauncher implements Launcher {
  bool _started = false;
  @override
  Future<void> start() async {
    _started = true;
  }

  @override
  Future<void> stop() async {
    _started = false;
  }

  @override
  Future<int?> getServicePort() async {
    return _started ? 8080 : null;
  }
}
