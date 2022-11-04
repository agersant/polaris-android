import 'dart:async';

import 'package:async/async.dart';

class UniqueTimer {
  final Duration duration;
  final Future<void> Function() callback;
  late RestartableTimer _timer;
  bool _working = false;

  UniqueTimer({required this.duration, required this.callback}) {
    _timer = RestartableTimer(duration, work);
  }

  void cancel() {
    _timer.cancel();
  }

  void wake() {
    if (!_timer.isActive) {
      work();
    }
  }

  void reset() {
    _timer.reset();
  }

  void work() async {
    if (_working) {
      _timer.reset();
      return;
    }

    _working = true;

    await callback();

    _working = false;
  }
}
