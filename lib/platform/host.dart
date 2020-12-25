import 'package:shared_preferences/shared_preferences.dart';

const String preferenceKey = "polaris_server_url";

class Manager {
  String _url;

  get url => _url;

  set url(String newURL) {
    //  remove trailing slash, prepend http:// if needed
    if (newURL != null) {
      newURL = newURL.trim();
    }
    _url = newURL;
  }

  void persist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(preferenceKey, url);
  }

  static Future<Manager> create() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString(preferenceKey);
    return Manager(url);
  }

  Manager(this._url);
}
