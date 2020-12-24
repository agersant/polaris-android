import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/api/api.dart';
import 'package:polaris/api/host.dart';

final getIt = GetIt.instance;

enum ConnectionStoreError {
  connectionAlreadyInProgress,
  unsupportedAPIVersion,
  networkError,
  requestFailed,
  unknownError,
}

enum ConnectionState {
  disconnected,
  connecting,
  reconnecting,
  connected,
}

class ConnectionStore extends ChangeNotifier {
  API _api = getIt<API>();
  Host _host = getIt<Host>();
  ConnectionState _state = ConnectionState.disconnected;
  get state => _state;

  final StreamController<ConnectionStoreError> _errorStreamController =
      StreamController<ConnectionStoreError>();

  Stream<ConnectionStoreError> _errorStream;
  get errorStream => _errorStream;

  ConnectionStore() {
    _errorStream = _errorStreamController.stream.asBroadcastStream();
    reconnect();
  }

  Future reconnect() async {
    assert(_state == ConnectionState.disconnected);
    if (_host.url == null || _host.url.isEmpty) {
      return;
    }

    _setState(ConnectionState.reconnecting);
    try {
      await _tryConnect();
    } catch (e) {}
  }

  Future connect(String url) async {
    if (_state != ConnectionState.disconnected) {
      _emitError(ConnectionStoreError.connectionAlreadyInProgress);
      return;
    }
    _host.url = url;
    _setState(ConnectionState.connecting);
    return await _tryConnect();
  }

  disconnect() {
    _host.url = null;
    _setState(ConnectionState.disconnected);
  }

  Future _tryConnect() async {
    assert(state == ConnectionState.connecting ||
        state == ConnectionState.reconnecting);

    var apiVersion;
    try {
      apiVersion = await _api.getAPIVersion();
    } on APIError catch (e) {
      _setState(ConnectionState.disconnected);
      switch (e) {
        case APIError.requestFailed:
          _emitError(ConnectionStoreError.requestFailed);
          break;
        case APIError.networkError:
        case APIError.unspecifiedHost:
          _emitError(ConnectionStoreError.networkError);
          break;
      }
      return;
    } catch (e) {
      _setState(ConnectionState.disconnected);
      _emitError(ConnectionStoreError.unknownError);
      return;
    }

    if (apiVersion.major != 6) {
      _setState(ConnectionState.disconnected);
      _emitError(ConnectionStoreError.unsupportedAPIVersion);
      return;
    }

    _host.persist();
    _setState(ConnectionState.connected);
  }

  _emitError(ConnectionStoreError error) {
    _errorStreamController.add(error);
    throw error;
  }

  _setState(ConnectionState newState) {
    if (_state == newState) {
      return;
    }
    _state = newState;
    notifyListeners();
  }
}
