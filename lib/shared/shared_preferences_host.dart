import 'package:flutter/widgets.dart';
import 'package:polaris/shared/host.dart' as host;
import 'package:shared_preferences/shared_preferences.dart';

const String preferenceKey = "polaris_server_url";

class SharedPreferencesHost extends ChangeNotifier implements host.Manager {
  host.State _state = host.State.available;
  get state => _state;

  String? _url;
  String? get url => _url;

  set url(String? newURL) {
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

  void onConnectionAttempt(String newURL) {
    url = newURL;
  }

  Future<void> onSuccessfulConnection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentURL = url;
    if (currentURL != null) {
      prefs.setString(preferenceKey, currentURL);
    }
  }

  static Future<SharedPreferencesHost> create() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString(preferenceKey);
    return SharedPreferencesHost(url);
  }

  SharedPreferencesHost(this._url);
}
