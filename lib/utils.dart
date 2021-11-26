import 'package:path/path.dart' as p;

final _pathSeparatorRegExp = RegExp(r'[/\\]');

const oneMB = 1024 * 1024;

List<String> splitPath(String path) {
  final standardPath = path.replaceAll(_pathSeparatorRegExp, '/');
  return p.split(standardPath);
}

String dirname(String path) {
  final standardPath = path.replaceAll(_pathSeparatorRegExp, '/');
  return p.dirname(standardPath);
}

String basename(String path) {
  final standardPath = path.replaceAll(_pathSeparatorRegExp, '/');
  return p.basename(standardPath);
}
