abstract class Manager {
  String get url;
  void onConnectionAttempt(String url);
  Future<void> onSuccessfulConnection();
}
