import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/api/api.dart';

final getIt = GetIt.instance;

enum ConnectionStoreError {
  connectionAlreadyInProgress,
  unsupportedAPIVersion,
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
}

class ConnectionStore extends ChangeNotifier {
  ConnectionState _state = ConnectionState.disconnected;

  get state => _state;

  set state(ConnectionState state) {
    if (_state == state) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  disconnect() {
    var api = getIt<API>();
    api.host = null;
    _setState(ConnectionState.disconnected);
  }

  Future connect(String host) async {
    if (_state == ConnectionState.connecting) {
      throw ConnectionStoreError.connectionAlreadyInProgress;
    }
    _setState(ConnectionState.connecting);

    var api = getIt<API>();
    api.host = host;

    try {
      var apiVersion = await api.getAPIVersion();
      if (apiVersion.major != 6) {
        throw ConnectionStoreError.unsupportedAPIVersion;
      }
    } catch (e) {
      _setState(ConnectionState.disconnected);
      throw e;
    }

    _setState(ConnectionState.connected);
  }

  _setState(ConnectionState newState) {
    if (_state == newState) {
      return;
    }
    _state = newState;
    notifyListeners();
  }
}
