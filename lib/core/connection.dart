import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:shared_preferences/shared_preferences.dart';

const String hostPreferenceKey = "polaris_server_url";

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
  http.Client httpClient;

  State _state = State.disconnected;
  State get state => _state;

  String? _url;
  String? get url => _url;

  State? _previousState;
  State? get previousState => _previousState;

  Manager({required this.httpClient}) {
    reconnect();
  }

  Future reconnect() async {
    assert(_state == State.disconnected);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _url = prefs.getString(hostPreferenceKey);
    if (_url?.isEmpty ?? true) {
      return;
    }

    _setState(State.reconnecting);
    try {
      await _tryConnect();
    } catch (e) {
      developer.log("Error during reconnect", error: e);
    }
  }

  Future connect(String newURL) async {
    if (_state != State.disconnected) {
      throw Error.connectionAlreadyInProgress;
    }

    _setURL(newURL);
    _setState(State.connecting);
    return await _tryConnect();
  }

  disconnect() {
    _setState(State.disconnected);
  }

  Future _tryConnect() async {
    assert(state == State.connecting || state == State.reconnecting);

    dto.APIVersion apiVersion;
    try {
      polaris.HttpGuestClient guestClient = polaris.HttpGuestClient(httpClient: httpClient, connectionManager: this);
      apiVersion = await guestClient.getAPIVersion();
    } on polaris.APIError catch (e) {
      _setState(State.disconnected);
      throw e.toConnectionError();
    } catch (e) {
      _setState(State.disconnected);
      throw Error.unknownError;
    }

    if (apiVersion.major != 6) {
      _setState(State.disconnected);
      throw Error.unsupportedAPIVersion;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentURL = url;
    if (currentURL != null) {
      prefs.setString(hostPreferenceKey, currentURL);
    }

    _setState(State.connected);
  }

  _setState(State newState) {
    if (_state == newState) {
      return;
    }
    _previousState = state;
    _state = newState;
    notifyListeners();
  }

  _setURL(String? newURL) {
    if (newURL != null) {
      newURL = _cleanURL(newURL);
    }
    _url = newURL;
  }

  String _cleanURL(String url) {
    if (!url.startsWith('http')) {
      url = 'http://' + url;
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
