import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/src/util.dart';
import 'package:libgit2dart/src/config.dart';

void main() {
  final tmpDir = Directory.systemTemp.path;
  const configFileName = 'test_config';
  late Config config;

  group('Config', () {
    setUpAll(() {
      libgit2.git_libgit2_init();
    });

    setUp(() {
      File('$tmpDir/$configFileName').writeAsStringSync(
          '[core]\n\trepositoryformatversion = 0\n\tbare = false\n[remote "origin"]\n\turl = someurl');
      config = Config.open(path: '$tmpDir/$configFileName');
    });

    tearDown(() {
      config.close();
      File('$tmpDir/$configFileName').deleteSync();
    });

    tearDownAll(() {
      libgit2.git_libgit2_shutdown();
    });

    test('opens file successfully with provided path', () {
      expect(config, isA<Config>());
    });

    test('gets entries of file', () {
      expect(config.variables['core.repositoryformatversion'], equals('0'));
    });

    test('sets boolean value for provided key', () {
      config.setVariable('core.bare', true);
      expect(config.variables['core.bare'], equals('true'));
    });

    test('sets integer value for provided key', () {
      config.setVariable('core.repositoryformatversion', 1);
      expect(config.variables['core.repositoryformatversion'], equals('1'));
    });

    test('sets string value for provided key', () {
      config.setVariable('remote.origin.url', 'updated');
      expect(config.variables['remote.origin.url'], equals('updated'));
    });
  });
  ;
}
