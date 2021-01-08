import 'package:flutter/foundation.dart';

enum State {
  available,
  unavailable,
}

abstract class Manager extends ChangeNotifier {
  State get state;
  String get url;
}
