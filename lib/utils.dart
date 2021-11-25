final _pathSeparatorRegExp = RegExp(r'[/\\]');

List<String> splitPath(String path) {
  return path.split(_pathSeparatorRegExp).toList();
}

String dirname(String path) {
  final components = splitPath(path)..removeLast();
  return components.join('/');
}

String basename(String path) {
  return splitPath(path).last;
}
