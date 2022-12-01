import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:shared_preferences/shared_preferences.dart';

const String authHostPreferenceKey = "polaris_auth_host";
const String tokenPreferenceKey = "polaris_auth_token";
const String usernamePreferenceKey = "polaris_auth_username";

enum Error {
  authenticationAlreadyInProgress,
  incorrectCredentials,
  requestFailed,
  requestTimeout,
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
      case polaris.APIError.unexpectedCacheMiss:
        return Error.requestFailed;
      case polaris.APIError.timeout:
        return Error.requestTimeout;
    }
  }
}

enum State {
  unauthenticated,
  reauthenticating,
  authenticating,
  authenticated,
}

class Manager extends ChangeNotifier {
  final http.Client httpClient;
  final connection.Manager connectionManager;

  State _state = State.unauthenticated;
  State get state => _state;
  String? _token;
  String? get token => _token;
  String? _username;
  String? get username => _username;

  Manager({
    required this.httpClient,
    required this.connectionManager,
  }) {
    connectionManager.addListener(() async => await _onConnectionStateChanged());
    _onConnectionStateChanged();
  }

  Future _onConnectionStateChanged() async {
    if (connectionManager.isConnected()) {
      _setState(State.unauthenticated);
      try {
        await _reauthenticate();
      } catch (e) {
        developer.log("Error during reauthentication", error: e);
      }
    }
  }

  Future _reauthenticate() async {
    assert(_state == State.unauthenticated);
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final url = preferences.getString(authHostPreferenceKey);
    _token = preferences.getString(tokenPreferenceKey);
    _username = preferences.getString(usernamePreferenceKey);
    final isSameHost = url == connectionManager.url;
    final hasToken = _token?.isNotEmpty ?? false;
    final hasUsername = _username?.isNotEmpty ?? false;
    if (!hasToken || !hasUsername || !isSameHost) {
      return;
    }

    _setState(State.reauthenticating);
    try {
      final guestAPI = polaris.HttpGuestClient(connectionManager: connectionManager, httpClient: httpClient);
      await guestAPI.testConnection(_token);
    } on polaris.APIError catch (e) {
      await _clear();
      _setState(State.unauthenticated);
      throw e.toAuthenticationError();
    } catch (e) {
      await _clear();
      _setState(State.unauthenticated);
      throw Error.unknownError;
    }

    _setState(State.authenticated);
  }

  Future authenticate(String newUsername, String password) async {
    if (_state != State.unauthenticated) {
      throw Error.authenticationAlreadyInProgress;
    }

    _setState(State.authenticating);
    Authorization authorization;
    try {
      final guestAPI = polaris.HttpGuestClient(connectionManager: connectionManager, httpClient: httpClient);
      authorization = await guestAPI.login(newUsername, password);
    } on polaris.APIError catch (e) {
      _setState(State.unauthenticated);
      throw e.toAuthenticationError();
    } catch (e) {
      _setState(State.unauthenticated);
      throw Error.unknownError;
    }

    _setHost(connectionManager.url);
    _setUsername(newUsername);
    _setToken(authorization.token);
    _setState(State.authenticated);
  }

  bool isAuthenticated() {
    return state == State.authenticated;
  }

  void _setState(State newState) {
    if (_state == newState) {
      return;
    }
    _state = newState;
    notifyListeners();
  }

  Future _clear() async {
    await _setHost(null);
    await _setToken(null);
    await _setUsername(null);
  }

  Future _setHost(String? host) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (host != null) {
      preferences.setString(authHostPreferenceKey, host);
    } else {
      preferences.remove(authHostPreferenceKey);
    }
  }

  Future _setToken(String? newToken) async {
    _token = newToken;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (_token != null) {
      preferences.setString(tokenPreferenceKey, _token!);
    } else {
      preferences.remove(tokenPreferenceKey);
    }
  }

  Future _setUsername(String? newUsername) async {
    _username = newUsername;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (_username != null) {
      preferences.setString(usernamePreferenceKey, _username!);
    } else {
      preferences.remove(usernamePreferenceKey);
    }
  }
}
