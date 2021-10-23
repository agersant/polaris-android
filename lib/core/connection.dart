import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/shared/shared_preferences_host.dart';

enum Error {
  connectionAlreadyInProgress,
  unsupportedAPIVersion,
  networkError,
  requestFailed,
  unknownError,
}

extension _ToConnectionError on polaris.APIError {
  Error toConnectionError() {
    switch (this) {
      case polaris.APIError.unauthorized:
      case polaris.APIError.requestFailed:
      case polaris.APIError.responseParseError:
        return Error.requestFailed;
      case polaris.APIError.networkError:
      case polaris.APIError.unspecifiedHost:
        return Error.networkError;
    }
  }
}

enum State {
  disconnected,
  connecting,
  reconnecting,
  connected,
}

class Manager extends ChangeNotifier {
  final polaris.GuestClient guestAPI;
  final SharedPreferencesHost hostManager;

  State _state = State.disconnected;
  State get state => _state;

  State? _previousState;
  State? get previousState => _previousState;

  final StreamController<Error> _errorStreamController = StreamController<Error>();
  late final Stream<Error> _errorStream = _errorStreamController.stream.asBroadcastStream();
  Stream<Error> get errorStream => _errorStream;

  Manager({required this.guestAPI, required this.hostManager}) {
    reconnect();
  }

  Future reconnect() async {
    assert(_state == State.disconnected);
    if (hostManager.url?.isEmpty ?? true) {
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
    } on polaris.APIError catch (e) {
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
