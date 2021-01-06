import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:polaris/transient/connection.dart' as connection;
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/shared/token.dart' as token;

enum Error {
  authenticationAlreadyInProgress,
  incorrectCredentials,
  requestFailed,
  unknownError,
}

extension _ToAuthenticationError on polaris.APIError {
  Error toAuthenticationError() {
    switch (this) {
      case polaris.APIError.unauthorized:
        return Error.incorrectCredentials;
      case polaris.APIError.requestFailed:
      case polaris.APIError.networkError:
      case polaris.APIError.unspecifiedHost:
      case polaris.APIError.responseParseError:
        return Error.requestFailed;
    }
    return Error.unknownError;
  }
}

enum State {
  unauthenticated,
  reauthenticating,
  authenticating,
  authenticated,
}

class Manager extends ChangeNotifier {
  final connection.Manager connectionManager;
  final token.Manager tokenManager;
  final polaris.GuestAPI guestAPI;

  State _state = State.unauthenticated;
  State get state => _state;

  final StreamController<Error> _errorStreamController = StreamController<Error>();
  Stream<Error> _errorStream;
  Stream<Error> get errorStream => _errorStream;

  Manager({
    @required this.connectionManager,
    @required this.tokenManager,
    @required this.guestAPI,
  })  : assert(connectionManager != null),
        assert(tokenManager != null),
        assert(guestAPI != null) {
    _errorStream = _errorStreamController.stream.asBroadcastStream();
    connectionManager.addListener(() async => await _onConnectionStateChanged());
    _onConnectionStateChanged();
  }

  _onConnectionStateChanged() async {
    final previousConnectionState = connectionManager.previousState;
    final connectionState = connectionManager.state;
    if (connectionState == connection.State.connected) {
      if (previousConnectionState == connection.State.reconnecting) {
        try {
          await _reauthenticate();
        } catch (e) {}
      } else {
        tokenManager.token = null;
        _setState(State.unauthenticated);
      }
    }
  }

  Future _reauthenticate() async {
    assert(_state == State.unauthenticated);
    if (tokenManager.token == null || tokenManager.token.isEmpty) {
      return;
    }

    _setState(State.reauthenticating);
    try {
      await guestAPI.testConnection();
    } on polaris.APIError catch (e) {
      _setState(State.unauthenticated);
      _emitError(e.toAuthenticationError());
      return;
    } catch (e) {
      _setState(State.unauthenticated);
      _emitError(Error.unknownError);
      return;
    }

    _setState(State.authenticated);
  }

  Future authenticate(String username, password) async {
    if (_state != State.unauthenticated) {
      _emitError(Error.authenticationAlreadyInProgress);
      return;
    }

    _setState(State.authenticating);
    Authorization authorization;
    try {
      authorization = await guestAPI.login(username, password);
    } on polaris.APIError catch (e) {
      _setState(State.unauthenticated);
      _emitError(e.toAuthenticationError());
      return;
    } catch (e) {
      _setState(State.unauthenticated);
      _emitError(Error.unknownError);
      return;
    }

    tokenManager.token = authorization.token;
    tokenManager.persist();
    _setState(State.authenticated);
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
