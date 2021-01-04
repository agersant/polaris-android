import 'package:polaris/shared/host.dart' as host;
import 'package:shared_preferences/shared_preferences.dart';

const String preferenceKey = "polaris_server_url";

class SharedPreferencesHost implements host.Manager {
  String _url;

  String get url => _url;

  set url(String newURL) {
    if (newURL != null) {
      newURL = newURL.trim();
    }
    if (!newURL.startsWith('http')) {
      newURL = 'http://' + newURL;
    }
    while (newURL.endsWith('/')) {
      newURL = newURL.substring(0, newURL.length - 1);
    }
    _url = newURL;
  }

  void onConnectionAttempt(String newURL) {
    url = newURL;
  }

  Future<void> onSuccessfulConnection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(preferenceKey, url);
  }

  static Future<SharedPreferencesHost> create() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString(preferenceKey);
    return SharedPreferencesHost(url);
  }

  SharedPreferencesHost(this._url);
}
