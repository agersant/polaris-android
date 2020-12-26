import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/connection.dart' as connection;
import 'package:polaris/platform/dto.dart';
import 'package:polaris/platform/token.dart' as token;

final getIt = GetIt.instance;

enum Error {
  authenticationAlreadyInProgress,
  incorrectCredentials,
  requestFailed,
  unknownError,
}

extension _ToAuthenticationError on APIError {
  Error toAuthenticationError() {
    switch (this) {
      case APIError.unauthorized:
        return Error.incorrectCredentials;
      case APIError.requestFailed:
      case APIError.networkError:
      case APIError.unspecifiedHost:
      case APIError.responseParseError:
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
  API _api = getIt<API>();
  connection.Manager _connectionManager = getIt<connection.Manager>();
  token.Manager _tokenManager = getIt<token.Manager>();

  State _state = State.unauthenticated;
  State get state => _state;

  final StreamController<Error> _errorStreamController = StreamController<Error>();
  Stream<Error> _errorStream;
  Stream<Error> get errorStream => _errorStream;

  Manager() {
    _errorStream = _errorStreamController.stream.asBroadcastStream();
    _connectionManager.addListener(() async => await _onConnectionStateChanged());
    _onConnectionStateChanged();
  }

  _onConnectionStateChanged() async {
    final previousConnectionState = _connectionManager.previousState;
    final connectionState = _connectionManager.state;
    if (connectionState == connection.State.connected) {
      if (previousConnectionState == connection.State.reconnecting) {
        try {
          await _reauthenticate();
        } catch (e) {}
      } else {
        _tokenManager.token = null;
        _setState(State.unauthenticated);
      }
    }
  }

  Future _reauthenticate() async {
    assert(_state == State.unauthenticated);
    if (_tokenManager.token == null || _tokenManager.token.isEmpty) {
      return;
    }

    _setState(State.reauthenticating);
    try {
      await _api.browse('');
    } on APIError catch (e) {
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
      authorization = await _api.login(username, password);
    } on APIError catch (e) {
      _setState(State.unauthenticated);
      _emitError(e.toAuthenticationError());
      return;
    } catch (e) {
      _setState(State.unauthenticated);
      _emitError(Error.unknownError);
      return;
    }

    _tokenManager.token = authorization.token;
    _tokenManager.persist();
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
