import 'dart:io';
import '../test/helpers/util.dart';

Future<void> prepareRepo(String path) async {
  if (await Directory(path).exists()) {
    await Directory(path).delete(recursive: true);
  }
  await copyRepo(
    from: Directory('test/assets/testrepo/'),
    to: await Directory(path).create(),
  );
}

Future<void> disposeRepo(String path) async {
  await Directory(path).delete(recursive: true);
}
