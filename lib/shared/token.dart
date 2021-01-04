import 'package:shared_preferences/shared_preferences.dart';

const String preferenceKey = "polaris_auth_token";

class Manager {
  String token;

  void persist() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString(preferenceKey, token);
  }

  static Future<Manager> create() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String token = preferences.getString(preferenceKey);
    return Manager(token);
  }

  Manager(this.token);
}
