class Host {
  String _url;

  get url => _url;

  set url(String newURL) {
    // TODO trim, remove trailing slash, prepend http:// if needed
    _url = newURL;
  }
}
