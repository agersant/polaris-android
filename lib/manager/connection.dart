import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/service/api.dart';
import 'package:polaris/service/host.dart';

final getIt = GetIt.instance;

enum Error {
  connectionAlreadyInProgress,
  unsupportedAPIVersion,
  networkError,
  requestFailed,
  unknownError,
}

enum State {
  disconnected,
  connecting,
  reconnecting,
  connected,
}

class Manager extends ChangeNotifier {
  API _api = getIt<API>();
  Host _host = getIt<Host>();
  State _state = State.disconnected;
  get state => _state;

  final StreamController<Error> _errorStreamController =
      StreamController<Error>();

  Stream<Error> _errorStream;
  get errorStream => _errorStream;

  Manager() {
    _errorStream = _errorStreamController.stream.asBroadcastStream();
    reconnect();
  }

  Future reconnect() async {
    assert(_state == State.disconnected);
    if (_host.url == null || _host.url.isEmpty) {
      return;
    }

    _setState(State.reconnecting);
    try {
      await _tryConnect();
    } catch (e) {}
  }

  Future connect(String url) async {
    if (_state != State.disconnected) {
      _emitError(Error.connectionAlreadyInProgress);
      return;
    }
    _host.url = url;
    _setState(State.connecting);
    return await _tryConnect();
  }

  disconnect() {
    _host.url = null;
    _setState(State.disconnected);
  }

  Future _tryConnect() async {
    assert(state == State.connecting || state == State.reconnecting);

    var apiVersion;
    try {
      apiVersion = await _api.getAPIVersion();
    } on APIError catch (e) {
      _setState(State.disconnected);
      switch (e) {
        case APIError.requestFailed:
          _emitError(Error.requestFailed);
          break;
        case APIError.networkError:
        case APIError.unspecifiedHost:
          _emitError(Error.networkError);
          break;
      }
      return;
    } catch (e) {
      _setState(State.disconnected);
      _emitError(Error.unknownError);
      return;
    }

    if (apiVersion.major != 6) {
      _setState(State.disconnected);
      _emitError(Error.unsupportedAPIVersion);
      return;
    }

    _host.persist();
    _setState(State.connected);
  }

  _emitError(Error error) {
    _errorStreamController.add(error);
    throw error;
  }

  _setState(State newState) {
    if (_state == newState) {
      return;
    }
    _state = newState;
    notifyListeners();
  }
}
