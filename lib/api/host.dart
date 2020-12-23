import 'package:shared_preferences/shared_preferences.dart';

const String serverURLKey = "polaris_server_url";

class Host {
  String _url;

  get url => _url;

  set url(String newURL) {
    // TODO trim, remove trailing slash, prepend http:// if needed
    _url = newURL;
  }

  void persist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(serverURLKey, url);
  }

  static Future<Host> create() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString(serverURLKey);
    return Host(url);
  }

  Host(this._url);
}
