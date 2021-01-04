import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:polaris/shared/api_error.dart';
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/transient/guest_api.dart';

enum Error {
  connectionAlreadyInProgress,
  unsupportedAPIVersion,
  networkError,
  requestFailed,
  unknownError,
}

extension _ToConnectionError on APIError {
  Error toConnectionError() {
    switch (this) {
      case APIError.unauthorized:
      case APIError.requestFailed:
      case APIError.responseParseError:
        return Error.requestFailed;
      case APIError.networkError:
      case APIError.unspecifiedHost:
        return Error.networkError;
    }
    return Error.unknownError;
  }
}

enum State {
  disconnected,
  connecting,
  reconnecting,
  connected,
}

class Manager extends ChangeNotifier {
  final GuestAPI guestAPI;
  final host.Manager hostManager;

  State _state = State.disconnected;
  State get state => _state;

  State _previousState;
  State get previousState => _previousState;

  final StreamController<Error> _errorStreamController = StreamController<Error>();
  Stream<Error> _errorStream;
  Stream<Error> get errorStream => _errorStream;

  Manager({@required this.guestAPI, @required this.hostManager})
      : assert(guestAPI != null),
        assert(hostManager != null) {
    _errorStream = _errorStreamController.stream.asBroadcastStream();
    reconnect();
  }

  Future reconnect() async {
    assert(_state == State.disconnected);
    if (hostManager.url == null || hostManager.url.isEmpty) {
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

    hostManager.onConnectionAttempt(url);
    _setState(State.connecting);
    return await _tryConnect();
  }

  disconnect() {
    _setState(State.disconnected);
  }

  Future _tryConnect() async {
    assert(state == State.connecting || state == State.reconnecting);

    var apiVersion;
    try {
      apiVersion = await guestAPI.getAPIVersion();
    } on APIError catch (e) {
      _setState(State.disconnected);
      _emitError(e.toConnectionError());
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

    hostManager.onSuccessfulConnection();
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
    _previousState = state;
    _state = newState;
    notifyListeners();
  }
}
