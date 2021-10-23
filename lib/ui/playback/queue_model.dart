import 'package:flutter/foundation.dart';

class QueueModel extends ChangeNotifier {
  bool _isQueueOpen = false;
  bool get isQueueOpen => _isQueueOpen;

  void openQueue() {
    _isQueueOpen = true;
    notifyListeners();
  }

  void closeQueue() {
    _isQueueOpen = false;
    notifyListeners();
  }
}
